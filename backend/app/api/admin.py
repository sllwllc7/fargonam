"""Admin endpointlar — faqat role=admin uchun."""
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from pydantic import BaseModel, Field

from app.api.deps import require_admin
from app.core.push import send_push_to_user
from app.db.session import get_db
from app.models.notification import Notification
from app.models.order import Order, OrderStatus
from app.models.product import Product
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.schemas.admin import AdminStats, OrderStatusUpdate, UserAdminUpdate
from app.schemas.auth import UserOut
from app.schemas.common import Page
from app.schemas.marketplace import OrderOut

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


# ========== USERS ==========
@router.get("/users", response_model=Page[UserOut])
async def list_users(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(default=None, description="Telefon yoki ism bo'yicha qidirish"),
    role: UserRole | None = Query(default=None),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    base = select(User)
    if q:
        like = f"%{q}%"
        base = base.where((User.phone.ilike(like)) | (User.full_name.ilike(like)))
    if role is not None:
        base = base.where(User.role == role)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = await db.scalars(base.order_by(User.id.desc()).limit(limit).offset(offset))
    return Page[UserOut](
        items=[UserOut.model_validate(u) for u in rows],
        total=total or 0,
        limit=limit,
        offset=offset,
    )


@router.patch("/users/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    payload: UserAdminUpdate,
    db: AsyncSession = Depends(get_db),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    data = payload.model_dump(exclude_unset=True)
    if "role" in data:
        try:
            user.role = UserRole(data["role"])
        except ValueError:
            raise HTTPException(status_code=400, detail="Noto'g'ri rol")
    if "is_active" in data:
        user.is_active = bool(data["is_active"])
    await db.commit()
    await db.refresh(user)
    return user


# ========== ORDERS ==========
@router.get("/orders", response_model=Page[OrderOut])
async def list_all_orders(
    db: AsyncSession = Depends(get_db),
    status_filter: OrderStatus | None = Query(default=None, alias="status"),
    user_id: int | None = Query(default=None),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    base = select(Order)
    if status_filter is not None:
        base = base.where(Order.status == status_filter)
    if user_id is not None:
        base = base.where(Order.user_id == user_id)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = await db.scalars(base.order_by(Order.id.desc()).limit(limit).offset(offset))
    return Page[OrderOut](
        items=[OrderOut.model_validate(o) for o in rows],
        total=total or 0,
        limit=limit,
        offset=offset,
    )


@router.patch("/orders/{order_id}", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    order = await db.get(Order, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    order.status = payload.status
    await db.commit()
    await db.refresh(order)
    return order


# ========== STATS ==========
@router.get("/stats", response_model=AdminStats)
async def get_stats(db: AsyncSession = Depends(get_db)):
    users_total = await db.scalar(select(func.count()).select_from(User))
    sellers_total = await db.scalar(
        select(func.count()).select_from(User).where(User.role == UserRole.seller)
    )
    shops_total = await db.scalar(select(func.count()).select_from(Shop))
    products_total = await db.scalar(select(func.count()).select_from(Product))
    orders_total = await db.scalar(select(func.count()).select_from(Order))
    # Faqat to'langan/yetkazilgan buyurtmalarni hisoblaymiz
    revenue = await db.scalar(
        select(func.coalesce(func.sum(Order.total), 0)).where(
            Order.status.in_([OrderStatus.paid, OrderStatus.shipped, OrderStatus.delivered])
        )
    )
    return AdminStats(
        users_total=users_total or 0,
        sellers_total=sellers_total or 0,
        shops_total=shops_total or 0,
        products_total=products_total or 0,
        orders_total=orders_total or 0,
        revenue_total=float(revenue or Decimal("0")),
    )


# ========== BROADCAST (xabar yuborish) ==========

class BroadcastRequest(BaseModel):
    title: str = Field(max_length=200)
    body: str = Field(max_length=2000)
    # Kimga: "all", "buyers", "sellers", yoki aniq user_id lar
    target: str = Field(default="all", pattern=r"^(all|buyers|sellers|user_ids)$")
    user_ids: list[int] | None = None  # target=user_ids bo'lganda


@router.post("/broadcast")
async def broadcast_message(
    payload: BroadcastRequest,
    db: AsyncSession = Depends(get_db),
):
    """Admin — barcha yoki tanlangan userlarga xabar yuborish."""
    # Kimga yuborish
    if payload.target == "user_ids" and payload.user_ids:
        user_ids = payload.user_ids
    else:
        base = select(User.id).where(User.is_active.is_(True))
        if payload.target == "buyers":
            base = base.where(User.role == UserRole.buyer)
        elif payload.target == "sellers":
            base = base.where(User.role == UserRole.seller)
        user_ids = list((await db.scalars(base)).all())

    # Notification yaratish va push yuborish
    sent = 0
    for uid in user_ids:
        notif = Notification(
            user_id=uid,
            title=payload.title,
            body=payload.body,
            type="system",
        )
        db.add(notif)
        count = await send_push_to_user(uid, payload.title, payload.body, data={"type": "system"})
        if count > 0:
            sent += 1

    await db.commit()
    return {
        "total_users": len(user_ids),
        "push_sent": sent,
        "notifications_created": len(user_ids),
    }
