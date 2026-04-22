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
from app.api.cart import enrich_order
from app.api.ws import notify_user
from app.core.push import notify_order_status
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
    # Shu do'konlardagi mahsulotlar
    product_ids_q = select(Product.id).where(Product.shop_id.in_(shop_ids))
    # Shu mahsulotlar bor order_item'lar orqali order ID'lar
    order_ids_q = select(OrderItem.order_id).where(
        OrderItem.product_id.in_(product_ids_q)
    ).distinct()
    orders = (await db.scalars(
        select(Order).where(Order.id.in_(order_ids_q)).order_by(Order.id.desc())
    )).all()
    return [await enrich_order(o, db) for o in orders]


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    new_status: OrderStatus,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sotuvchi buyurtma holatini o'zgartirishi (masalan: shipped)."""
    if current_user.role not in (UserRole.seller, UserRole.admin):
        raise HTTPException(status_code=403, detail="Faqat sotuvchilar uchun")

    order = await db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    # Buyurtma shu sotuvchining do'koniga tegishli ekanligini tekshirish
    if current_user.role != UserRole.admin:
        shops = (await db.scalars(select(Shop).where(Shop.owner_id == current_user.id))).all()
        shop_ids = [s.id for s in shops]
        product_ids = (await db.scalars(
            select(Product.id).where(Product.shop_id.in_(shop_ids))
        )).all()
        order_product_ids = [oi.product_id for oi in order.items]
        if not any(pid in product_ids for pid in order_product_ids):
            raise HTTPException(status_code=403, detail="Bu buyurtma sizning do'koningizga tegishli emas")

    order.status = new_status
    await db.commit()
    await db.refresh(order)

    # Buyerga push (FCM)
    await notify_order_status(order.user_id, order.id, new_status.value)
    # Real-time WebSocket broadcast
    await notify_user(order.user_id, "order_status", {
        "order_id": order.id,
        "status": new_status.value,
    })

    return await enrich_order(order, db)


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
