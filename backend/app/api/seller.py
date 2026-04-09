"""Seller endpointlar — sotuvchining do'koniga kelgan buyurtmalar va analitika."""
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.schemas.marketplace import OrderOut

router = APIRouter(prefix="/seller", tags=["seller"])


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
    # Shu do'konlardagi mahsulotlar
    product_ids_q = select(Product.id).where(Product.shop_id.in_(shop_ids))
    # Shu mahsulotlar bor order_item'lar orqali order ID'lar
    order_ids_q = select(OrderItem.order_id).where(
        OrderItem.product_id.in_(product_ids_q)
    ).distinct()
    orders = (await db.scalars(
        select(Order).where(Order.id.in_(order_ids_q)).order_by(Order.id.desc())
    )).all()
    return list(orders)


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    new_status: OrderStatus,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sotuvchi buyurtma holatini o'zgartirishi (masalan: shipped)."""
    order = await db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    order.status = new_status
    await db.commit()
    await db.refresh(order)
    return order


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
    product_ids_q = select(Product.id).where(Product.shop_id.in_(shop_ids))
    order_items = (await db.scalars(
        select(OrderItem).where(OrderItem.product_id.in_(product_ids_q))
    )).all()
    order_ids = set(oi.order_id for oi in order_items)
    revenue = sum(oi.price_at_purchase * oi.quantity for oi in order_items)
    return {
        "shops": len(shops),
        "products": products_total or 0,
        "orders": len(order_ids),
        "revenue": float(revenue),
    }
