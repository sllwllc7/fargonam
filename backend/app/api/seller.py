"""Seller endpointlar — sotuvchining do'koniga kelgan buyurtmalar va analitika."""
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.product_variant import ProductVariant
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.api.cart import enrich_order, transition_order_status
from app.schemas.marketplace import OrderOut, ShopOut

router = APIRouter(prefix="/seller", tags=["seller"])


@router.get("/shops", response_model=list[ShopOut])
async def my_shops(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Joriy sotuvchining barcha do'konlari — status'dan qat'iy nazar."""
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Faqat sotuvchilar uchun")
    shops = (await db.scalars(select(Shop).where(Shop.owner_id == current_user.id))).all()
    return list(shops)


@router.get("/orders", response_model=list[OrderOut])
async def seller_orders(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sotuvchining do'konlaridagi mahsulotlarga tegishli buyurtmalar."""
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Faqat sotuvchilar uchun")
    # Sotuvchining do'konlari
    shops = (await db.scalars(select(Shop).where(Shop.owner_id == current_user.id))).all()
    if not shops:
        return []
    shop_ids = [s.id for s in shops]
    # Shu do'konlardagi mahsulotlarning variantlari
    variant_ids_q = select(ProductVariant.id).where(
        ProductVariant.product_id.in_(select(Product.id).where(Product.shop_id.in_(shop_ids)))
    )
    # Shu variantlar bor order_item'lar orqali order ID'lar
    order_ids_q = select(OrderItem.order_id).where(
        OrderItem.variant_id.in_(variant_ids_q)
    ).distinct()
    orders = (await db.scalars(
        select(Order).where(Order.id.in_(order_ids_q)).order_by(Order.id.desc())
    )).all()
    return [await enrich_order(o, db, include_phone=True) for o in orders]


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    new_status: OrderStatus,
    reason: str | None = Query(default=None, max_length=500, description="Faqat cancelled uchun — bekor qilish sababi"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sotuvchi buyurtma holatini o'zgartirishi (masalan: shipped, yoki
    "Bajarib bo'lmaydi" — cancelled + reason)."""
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Faqat sotuvchilar uchun")

    order = (await db.scalars(
        select(Order).where(Order.id == order_id).with_for_update()
    )).first()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    # Buyurtma shu sotuvchining do'koniga tegishli ekanligini tekshirish
    if current_user.role != UserRole.admin:
        shops = (await db.scalars(select(Shop).where(Shop.owner_id == current_user.id))).all()
        shop_ids = [s.id for s in shops]
        product_ids = (await db.scalars(
            select(Product.id).where(Product.shop_id.in_(shop_ids))
        )).all()
        order_variant_ids = [oi.variant_id for oi in order.items]
        order_product_ids = (await db.scalars(
            select(ProductVariant.product_id).where(ProductVariant.id.in_(order_variant_ids))
        )).all() if order_variant_ids else []
        if not any(pid in product_ids for pid in order_product_ids):
            raise HTTPException(status_code=403, detail="Bu buyurtma sizning do'koningizga tegishli emas")

    await transition_order_status(order, new_status, db, actor="seller", cancel_reason=reason)
    return await enrich_order(order, db, include_phone=True)


@router.get("/stats")
async def seller_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sotuvchi analitikasi — daromad, buyurtmalar, mahsulotlar."""
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Faqat sotuvchilar uchun")
    shops = (await db.scalars(select(Shop).where(Shop.owner_id == current_user.id))).all()
    if not shops:
        return {"shops": 0, "products": 0, "orders": 0, "revenue": 0}
    shop_ids = [s.id for s in shops]
    products_total = await db.scalar(
        select(func.count()).select_from(Product).where(Product.shop_id.in_(shop_ids))
    )
    # Buyurtmalar va daromad
    variant_ids_q = select(ProductVariant.id).where(
        ProductVariant.product_id.in_(select(Product.id).where(Product.shop_id.in_(shop_ids)))
    )
    order_items = (await db.scalars(
        select(OrderItem).where(OrderItem.variant_id.in_(variant_ids_q))
    )).all()
    order_ids = set(oi.order_id for oi in order_items)
    revenue = sum(oi.price_at_purchase * oi.quantity for oi in order_items)
    return {
        "shops": len(shops),
        "products": products_total or 0,
        "orders": len(order_ids),
        "revenue": float(revenue),
    }
