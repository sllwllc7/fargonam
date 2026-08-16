"""Cart va Order endpointlari — savatcha va buyurtma berish (variant asosida)."""
import asyncio
import logging
import secrets
from decimal import Decimal

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.api.ws import notify_user
from app.core.redis_client import get_redis
from app.db.session import get_db
from app.models.cart import CartItem
from app.models.order import DeliveryType, Order, OrderItem, OrderStatus, PaymentMethod
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.models.saved_address import SavedAddress
from app.models.shop import Shop
from app.models.user import User
from app.core.push import notify_new_order, notify_order_status, notify_seller_order_cancelled
from app.schemas.marketplace import CartItemAdd, CartItemOut, OrderItemOut, OrderOut

logger = logging.getLogger(__name__)


class CheckoutRequest(BaseModel):
    payment_method: PaymentMethod = PaymentMethod.cash
    delivery_type: DeliveryType = DeliveryType.delivery
    delivery_address: str | None = None
    # Ixtiyoriy — saqlangan manzildan tanlansa, uning matni delivery_address'ga
    # "surat" sifatida yoziladi (agar delivery_address alohida berilmasa)
    delivery_address_id: int | None = None

router = APIRouter(tags=["cart-orders"])

_IDEMPOTENCY_PREFIX = "idem:orders:"
_IDEMPOTENCY_PENDING_TTL = 30       # soniya — bir so'rov qayta ishlanishi kutiladigan max vaqt
_IDEMPOTENCY_RESULT_TTL = 86400     # 1 kun — shu vaqt ichida takroriy so'rov keshdan qaytariladi
_PICKUP_CODE_MIN = 1000
_PICKUP_CODE_MAX = 9999
_PICKUP_CODE_MAX_ATTEMPTS = 50


async def _generate_pickup_code(db: AsyncSession) -> str:
    """4 xonali, butun tarix bo'yicha unikal pickup kod (hech qachon qayta
    ishlatilmaydi — DB'dagi uq_orders_pickup_code shu bilan mos)."""
    for _ in range(_PICKUP_CODE_MAX_ATTEMPTS):
        code = str(secrets.randbelow(_PICKUP_CODE_MAX - _PICKUP_CODE_MIN + 1) + _PICKUP_CODE_MIN)
        exists = await db.scalar(select(Order.id).where(Order.pickup_code == code))
        if not exists:
            return code
    # Juda kam ehtimol (~9000 kod tugagudek bo'lganda) — aniq xato, jim crash emas
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Pickup kodlar tugadi, admin bilan bog'laning",
    )


async def _wait_for_idempotent_result(redis, key: str, attempts: int = 10, interval: float = 0.3) -> str:
    """Boshqa so'rov shu Idempotency-Key bilan allaqachon ishlab turibdi —
    tugashini bir necha marta tekshirib kutamiz."""
    for _ in range(attempts):
        value = await redis.get(key)
        if value and value != "pending":
            return value
        await asyncio.sleep(interval)
    return "pending"


async def restore_order_stock(order: Order, db: AsyncSession) -> None:
    """Buyurtma bekor qilinganda variant zaxirasini qaytaradi."""
    for oi in order.items:
        variant = await db.get(ProductVariant, oi.variant_id)
        if variant:
            variant.stock += oi.quantity


# ── Buyurtma holati state machine ───────────────────────────
# cancelled va delivered — terminal, ulardan chiquvchi o'tish yo'q.
ALLOWED_TRANSITIONS: dict[OrderStatus, set[OrderStatus]] = {
    OrderStatus.pending: {OrderStatus.paid, OrderStatus.cancelled},
    OrderStatus.paid: {OrderStatus.shipped, OrderStatus.cancelled},
    OrderStatus.shipped: {OrderStatus.delivered},
    OrderStatus.delivered: set(),
    OrderStatus.cancelled: set(),
}


async def _order_shop_owner_ids(order: Order, db: AsyncSession) -> list[int]:
    """Buyurtma tarkibidagi mahsulotlar tegishli do'kon(lar) egalarining
    user_id'lari (bir nechta sotuvchi bo'lishi mumkin — kelajakdagi
    ko'p-do'konli holat uchun)."""
    variant_ids = [oi.variant_id for oi in order.items]
    if not variant_ids:
        return []
    shop_ids = (await db.scalars(
        select(Product.shop_id)
        .join(ProductVariant, ProductVariant.product_id == Product.id)
        .where(ProductVariant.id.in_(variant_ids))
        .distinct()
    )).all()
    if not shop_ids:
        return []
    owner_ids = (await db.scalars(
        select(Shop.owner_id).where(Shop.id.in_(shop_ids)).distinct()
    )).all()
    return list(owner_ids)


async def transition_order_status(
    order: Order,
    new_status: OrderStatus,
    db: AsyncSession,
    actor: str,
    cancel_reason: str | None = None,
) -> bool:
    """Buyurtma holatini state machine bo'yicha o'zgartiradi.

    Bir xil statusga qayta yozish — idempotent no-op (False qaytaradi,
    hech narsa o'zgarmaydi, notify yuborilmaydi — tarmoq retry'sida
    "xato" ko'rinmasligi uchun). Noto'g'ri o'tish (masalan delivered'dan
    orqaga) — 400. `actor` notify yo'nalishini aniqlaydi: xaridor
    bekor qilsa sotuvchi(lar)ga, sotuvchi/admin o'zgartirsa xaridorga.
    """
    if new_status == order.status:
        return False

    allowed = ALLOWED_TRANSITIONS.get(order.status, set())
    if new_status not in allowed:
        raise HTTPException(
            status_code=400,
            detail=f"'{order.status.value}' holatidan '{new_status.value}'ga o'tish mumkin emas",
        )

    if new_status == OrderStatus.cancelled:
        await restore_order_stock(order, db)
        if cancel_reason:
            order.cancel_reason = cancel_reason
    order.status = new_status
    await db.commit()
    await db.refresh(order)

    if actor == "buyer":
        for seller_id in await _order_shop_owner_ids(order, db):
            await notify_seller_order_cancelled(seller_id, order.id, cancel_reason)
            await notify_user(seller_id, "order_status", {
                "order_id": order.id,
                "status": new_status.value,
            })
    else:
        await notify_order_status(order.user_id, order.id, new_status.value)
        await notify_user(order.user_id, "order_status", {
            "order_id": order.id,
            "status": new_status.value,
        })
    return True


async def _variant_product_map(
    db: AsyncSession, variant_ids: list[int]
) -> tuple[dict[int, ProductVariant], dict[int, Product]]:
    """variant_id → ProductVariant va product_id → Product xaritalarini bitta
    so'rovda oladi (N+1 o'rniga)."""
    if not variant_ids:
        return {}, {}
    variants = (await db.scalars(
        select(ProductVariant).where(ProductVariant.id.in_(variant_ids))
    )).all()
    variant_map = {v.id: v for v in variants}
    product_ids = list({v.product_id for v in variants})
    products = (await db.scalars(select(Product).where(Product.id.in_(product_ids)))).all() if product_ids else []
    product_map = {p.id: p for p in products}
    return variant_map, product_map


async def enrich_order(order: Order, db: AsyncSession, include_phone: bool = False) -> OrderOut:
    """Order'ga variant/mahsulot nomi va rasmini qo'shadi.

    `include_phone=True` bo'lsagina xaridor telefoni qo'shiladi — chaqiruvchi
    endpoint aniq shuni so'rashi shart (default False, maxfiy ma'lumot
    tasodifan chiqib ketmasligi uchun). Faqat quyidagilarda True beriladi:
    xaridorning o'z buyurtmasi (cart.py), sotuvchining buyurtmalari
    (seller.py), admin (admin.py). Diqqat: buyurtmada bir nechta do'kon
    sotuvchisi bo'lganda seller.py'dagi egalik tekshiruvi ANY-based (Round 3
    topilma, order-splitting hali yo'q) — ya'ni bu parametr FAQAT javobda
    maydon chiqishini boshqaradi, endpoint'ga kim kira olishini emas."""
    variant_ids = [oi.variant_id for oi in order.items]
    variant_map, product_map = await _variant_product_map(db, variant_ids)
    customer = await db.get(User, order.user_id) if include_phone else None

    enriched_items = []
    for oi in order.items:
        variant = variant_map.get(oi.variant_id)
        product = product_map.get(variant.product_id) if variant else None
        product_name = product.name if product else None
        variant_name = variant.variant_name if variant else None
        display_name = f"{product_name} · {variant_name}" if product_name and variant_name else product_name
        enriched_items.append(OrderItemOut(
            id=oi.id,
            variant_id=oi.variant_id,
            quantity=oi.quantity,
            price_at_purchase=oi.price_at_purchase,
            variant_name=variant_name,
            product_id=product.id if product else None,
            product_name=display_name,
            product_image_url=(variant.image_url if variant and variant.image_url else (product.image_url if product else None)),
        ))
    return OrderOut(
        id=order.id,
        user_id=order.user_id,
        total=order.total,
        status=order.status,
        payment_method=order.payment_method,
        delivery_type=order.delivery_type,
        delivery_address=order.delivery_address,
        delivery_address_id=order.delivery_address_id,
        pickup_code=order.pickup_code,
        cancel_reason=order.cancel_reason,
        customer_phone=customer.phone if customer else None,
        customer_name=customer.full_name if customer else None,
        created_at=order.created_at,
        items=enriched_items,
    )


@router.get("/cart", response_model=list[CartItemOut])
async def get_cart(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(select(CartItem).where(CartItem.user_id == current_user.id))).all()
    if not rows:
        return []
    variant_map, product_map = await _variant_product_map(db, [ci.variant_id for ci in rows])
    result = []
    for ci in rows:
        variant = variant_map.get(ci.variant_id)
        product = product_map.get(variant.product_id) if variant else None
        product_name = product.name if product else None
        variant_name = variant.variant_name if variant else None
        display_name = f"{product_name} · {variant_name}" if product_name and variant_name else product_name
        result.append(CartItemOut(
            id=ci.id,
            variant_id=ci.variant_id,
            quantity=ci.quantity,
            variant_name=variant_name,
            price=variant.price if variant else None,
            stock=variant.stock if variant else None,
            product_id=product.id if product else None,
            product_name=display_name,
            product_price=str(variant.price) if variant else None,
            product_image_url=(variant.image_url if variant and variant.image_url else (product.image_url if product else None)),
            is_available=bool(variant and variant.is_active),
        ))
    return result


async def _resolve_variant_id(payload: CartItemAdd, db: AsyncSession) -> int:
    if payload.variant_id is not None:
        return payload.variant_id
    # Eski moslik — product_id berilgan, "default" (birinchi faol) variantga qo'shiladi
    variant = await db.scalar(
        select(ProductVariant)
        .where(ProductVariant.product_id == payload.product_id, ProductVariant.is_active.is_(True))
        .order_by(ProductVariant.sort_order, ProductVariant.id)
        .limit(1)
    )
    if not variant:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    return variant.id


@router.post("/cart", response_model=CartItemOut, status_code=status.HTTP_201_CREATED)
async def add_to_cart(
    payload: CartItemAdd,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Savatda 50 tadan oshmasligi
    from sqlalchemy import func as sqlfunc
    cart_count = await db.scalar(
        select(sqlfunc.count()).where(CartItem.user_id == current_user.id)
    )
    if (cart_count or 0) >= 50:
        raise HTTPException(status_code=400, detail="Savatchada 50 tadan ortiq mahsulot bo'lishi mumkin emas")

    variant_id = await _resolve_variant_id(payload, db)
    variant = await db.get(ProductVariant, variant_id)
    if not variant or not variant.is_active:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")

    existing = await db.scalar(
        select(CartItem).where(
            CartItem.user_id == current_user.id,
            CartItem.variant_id == variant_id,
        )
    )
    if existing:
        existing.quantity += payload.quantity
        await db.commit()
        await db.refresh(existing)
        item = existing
    else:
        item = CartItem(
            user_id=current_user.id,
            variant_id=variant_id,
            quantity=payload.quantity,
        )
        db.add(item)
        await db.commit()
        await db.refresh(item)

    product = await db.get(Product, variant.product_id)
    display_name = f"{product.name} · {variant.variant_name}" if product else variant.variant_name
    return CartItemOut(
        id=item.id,
        variant_id=item.variant_id,
        quantity=item.quantity,
        variant_name=variant.variant_name,
        price=variant.price,
        stock=variant.stock,
        product_id=product.id if product else None,
        product_name=display_name,
        product_price=str(variant.price),
        product_image_url=variant.image_url or (product.image_url if product else None),
    )


@router.patch("/cart/{item_id}")
async def update_cart_quantity(
    item_id: int,
    quantity: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Savatchadagi element sonini o'zgartirish."""
    item = await db.get(CartItem, item_id)
    if not item or item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Element topilmadi")
    if quantity <= 0:
        await db.delete(item)
        await db.commit()
        return {"status": "deleted"}
    item.quantity = quantity
    await db.commit()
    return {"status": "updated", "quantity": quantity}


@router.delete("/cart/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_cart(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item = await db.get(CartItem, item_id)
    if not item or item.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Element topilmadi")
    await db.delete(item)
    await db.commit()


def _format_address_snapshot(addr: SavedAddress) -> str:
    parts = [p for p in [addr.region, addr.district, addr.address] if p]
    text = ", ".join(parts)
    if addr.landmark:
        text = f"{text} (mo'ljal: {addr.landmark})"
    return text


@router.post("/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
async def checkout(
    payload: CheckoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    """Savatchadagi hamma narsadan buyurtma yaratadi va savatchani bo'shatadi.

    `Idempotency-Key` header (ilova checkout urinishi uchun bitta marta
    generatsiya qiladi) orqali takroriy so'rov — tarmoq retry yoki tugmani
    ikki marta bosish — yangi buyurtma yaratmaydi, birinchi urinish
    natijasini qaytaradi."""
    redis = get_redis()
    redis_key = f"{_IDEMPOTENCY_PREFIX}{current_user.id}:{idempotency_key}" if idempotency_key else None

    if redis_key:
        try:
            claimed = await redis.set(redis_key, "pending", nx=True, ex=_IDEMPOTENCY_PENDING_TTL)
        except Exception as e:
            # Redis o'chgan/ulanmagan — idempotency himoyasisiz davom etamiz
            # (fail-open). Checkout'ning o'zi to'xtab qolmasligi muhimroq —
            # duplikat buyurtma xavfi juda kam vaqt oynasida (odatiy holatda
            # bosiladigan ikki marta tugma) va stock FOR UPDATE bilan
            # himoyalangan. Necha vaqt himoyasiz ishlaganini bilish uchun
            # LOG darajasi WARNING.
            logger.warning(f"Redis ishlamayapti, idempotency'siz davom etilmoqda (user={current_user.id}): {e}")
            redis_key = None
            claimed = True

        if redis_key and not claimed:
            cached = await _wait_for_idempotent_result(redis, redis_key)
            if cached and cached != "pending":
                order = await db.get(Order, int(cached))
                if order and order.user_id == current_user.id:
                    return await enrich_order(order, db, include_phone=True)
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="So'rov hali qayta ishlanmoqda, biroz kutib qaytadan urinib ko'ring",
            )

    try:
        cart_rows = (
            await db.scalars(select(CartItem).where(CartItem.user_id == current_user.id))
        ).all()
        if not cart_rows:
            raise HTTPException(status_code=400, detail="Savatcha bo'sh")

        delivery_address = None
        delivery_address_id = None
        pickup_code = None
        if payload.delivery_type == DeliveryType.pickup:
            pickup_code = await _generate_pickup_code(db)
        else:
            delivery_address = payload.delivery_address
            delivery_address_id = payload.delivery_address_id
            if delivery_address_id is not None:
                addr = await db.get(SavedAddress, delivery_address_id)
                if not addr or addr.user_id != current_user.id:
                    raise HTTPException(status_code=404, detail="Manzil topilmadi")
                if not delivery_address:
                    delivery_address = _format_address_snapshot(addr)

        # Variantlarni va stockni tekshirish (row lock bilan — race condition oldini oladi)
        total = Decimal("0")
        items_to_create: list[OrderItem] = []
        for ci in cart_rows:
            # SELECT ... FOR UPDATE — boshqa tranzaksiya kutadi
            variant = await db.scalar(
                select(ProductVariant).where(ProductVariant.id == ci.variant_id).with_for_update()
            )
            if not variant or not variant.is_active:
                raise HTTPException(
                    status_code=400, detail=f"Mahsulot varianti #{ci.variant_id} mavjud emas"
                )
            if variant.stock < ci.quantity:
                raise HTTPException(
                    status_code=400,
                    detail=f"'{variant.variant_name}' yetarli emas (qolgan: {variant.stock})",
                )
            variant.stock -= ci.quantity
            line_total = Decimal(variant.price) * ci.quantity
            total += line_total
            items_to_create.append(
                OrderItem(
                    variant_id=variant.id,
                    quantity=ci.quantity,
                    price_at_purchase=variant.price,
                )
            )

        order = Order(
            user_id=current_user.id,
            total=total,
            items=items_to_create,
            payment_method=payload.payment_method,
            delivery_type=payload.delivery_type,
            delivery_address=delivery_address,
            delivery_address_id=delivery_address_id,
            pickup_code=pickup_code,
        )
        db.add(order)

        # Savatchani tozalash
        for ci in cart_rows:
            await db.delete(ci)

        await db.commit()
        await db.refresh(order)
    except Exception:
        if redis_key:
            # Xato bo'lsa — keyingi urinish darhol qayta ishlansin, 30s kutmasin
            try:
                await redis.delete(redis_key)
            except Exception as e:
                logger.warning(f"Redis'dan idempotency key o'chirilmadi (himoyasiz emas, faqat kesh): {e}")
        raise

    if redis_key:
        try:
            await redis.set(redis_key, str(order.id), ex=_IDEMPOTENCY_RESULT_TTL)
        except Exception as e:
            # Buyurtma allaqachon yaratilgan — bu xato checkout'ni bekor qilmaydi,
            # faqat keyingi retry idempotency keshidan foyda ko'rmaydi.
            logger.warning(f"Redis natija keshiga yozilmadi (order={order.id}): {e}")

    # Sotuvchilarga push yuborish
    notified_owners = set()
    for oi in items_to_create:
        variant = await db.get(ProductVariant, oi.variant_id)
        product = await db.get(Product, variant.product_id) if variant else None
        if product:
            shop = await db.get(Shop, product.shop_id)
            if shop and shop.owner_id not in notified_owners:
                notified_owners.add(shop.owner_id)
                await notify_new_order(shop.owner_id, order.id)

    return await enrich_order(order, db, include_phone=True)


@router.post("/orders/{order_id}/cancel", response_model=OrderOut)
async def cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Xaridor buyurtmani bekor qiladi — faqat 'pending' yoki 'paid'
    holatda ('shipped'ga chiqqach yopiq — state machine belgilaydi)."""
    order = (await db.scalars(
        select(Order).where(Order.id == order_id).with_for_update()
    )).first()
    if not order or order.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    await transition_order_status(order, OrderStatus.cancelled, db, actor="buyer")
    return await enrich_order(order, db, include_phone=True)


@router.get("/orders", response_model=list[OrderOut])
async def list_my_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(
        select(Order).where(Order.user_id == current_user.id).order_by(Order.id.desc())
    )).all()
    return [await enrich_order(o, db, include_phone=True) for o in rows]
