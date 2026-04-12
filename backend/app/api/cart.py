"""Cart va Order endpointlari — savatcha va buyurtma berish."""
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.cart import CartItem
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.shop import Shop
from app.models.user import User
from app.core.push import notify_new_order, notify_order_status
from app.schemas.marketplace import CartItemAdd, CartItemOut, OrderItemOut, OrderOut

router = APIRouter(tags=["cart-orders"])


async def _enrich_order(order: Order, db: AsyncSession) -> OrderOut:
    """Order'ga mahsulot nomi va rasmini qo'shadi."""
    # Barcha mahsulotlarni bir so'rovda olish
    product_ids = [oi.product_id for oi in order.items]
    products = (await db.scalars(select(Product).where(Product.id.in_(product_ids)))).all() if product_ids else []
    product_map = {p.id: p for p in products}

    enriched_items = []
    for oi in order.items:
        product = product_map.get(oi.product_id)
        enriched_items.append(OrderItemOut(
            id=oi.id,
            product_id=oi.product_id,
            quantity=oi.quantity,
            price_at_purchase=oi.price_at_purchase,
            product_name=product.name if product else None,
            product_image_url=product.image_url if product else None,
        ))
    return OrderOut(
        id=order.id,
        user_id=order.user_id,
        total=order.total,
        status=order.status,
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
    # Barcha kerakli mahsulotlarni bir so'rovda olish
    product_ids = [ci.product_id for ci in rows]
    products = (await db.scalars(select(Product).where(Product.id.in_(product_ids)))).all()
    product_map = {p.id: p for p in products}
    result = []
    for ci in rows:
        product = product_map.get(ci.product_id)
        result.append(CartItemOut(
            id=ci.id,
            product_id=ci.product_id,
            quantity=ci.quantity,
            product_name=product.name if product else None,
            product_price=str(product.price) if product else None,
            product_image_url=product.image_url if product else None,
        ))
    return result


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

    product = await db.get(Product, payload.product_id)
    if not product or not product.is_active:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    existing = await db.scalar(
        select(CartItem).where(
            CartItem.user_id == current_user.id,
            CartItem.product_id == payload.product_id,
        )
    )
    if existing:
        existing.quantity += payload.quantity
        await db.commit()
        await db.refresh(existing)
        return existing
    item = CartItem(
        user_id=current_user.id,
        product_id=payload.product_id,
        quantity=payload.quantity,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


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


@router.post("/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
async def checkout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Savatchadagi hamma narsadan buyurtma yaratadi va savatchani bo'shatadi."""
    cart_rows = (
        await db.scalars(select(CartItem).where(CartItem.user_id == current_user.id))
    ).all()
    if not cart_rows:
        raise HTTPException(status_code=400, detail="Savatcha bo'sh")

    # Mahsulotlarni va stockni tekshirish (row lock bilan — race condition oldini oladi)
    total = Decimal("0")
    items_to_create: list[OrderItem] = []
    for ci in cart_rows:
        # SELECT ... FOR UPDATE — boshqa tranzaksiya kutadi
        product = await db.scalar(
            select(Product).where(Product.id == ci.product_id).with_for_update()
        )
        if not product or not product.is_active:
            raise HTTPException(
                status_code=400, detail=f"Mahsulot #{ci.product_id} mavjud emas"
            )
        if product.stock < ci.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"'{product.name}' yetarli emas (qolgan: {product.stock})",
            )
        product.stock -= ci.quantity
        line_total = product.price * ci.quantity
        total += line_total
        items_to_create.append(
            OrderItem(
                product_id=product.id,
                quantity=ci.quantity,
                price_at_purchase=product.price,
            )
        )

    order = Order(user_id=current_user.id, total=total, items=items_to_create)
    db.add(order)

    # Savatchani tozalash
    for ci in cart_rows:
        await db.delete(ci)

    await db.commit()
    await db.refresh(order)

    # Sotuvchilarga push yuborish
    notified_owners = set()
    for oi in items_to_create:
        product = await db.get(Product, oi.product_id)
        if product:
            shop = await db.get(Shop, product.shop_id)
            if shop and shop.owner_id not in notified_owners:
                notified_owners.add(shop.owner_id)
                await notify_new_order(shop.owner_id, order.id)

    return await _enrich_order(order, db)


@router.post("/orders/{order_id}/cancel", response_model=OrderOut)
async def cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchi faqat 'pending' holatdagi buyurtmani bekor qila oladi."""
    order = await db.get(Order, order_id)
    if not order or order.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    if order.status != OrderStatus.pending:
        raise HTTPException(status_code=400, detail="Faqat kutilayotgan buyurtmani bekor qilish mumkin")
    # Stock'ni qaytarish
    for oi in order.items:
        product = await db.get(Product, oi.product_id)
        if product:
            product.stock += oi.quantity
    order.status = OrderStatus.cancelled
    await db.commit()
    await db.refresh(order)
    return await _enrich_order(order, db)


@router.get("/orders", response_model=list[OrderOut])
async def list_my_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.scalars(
        select(Order).where(Order.user_id == current_user.id).order_by(Order.id.desc())
    )).all()
    return [await _enrich_order(o, db) for o in rows]
