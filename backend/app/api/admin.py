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
from app.api.cart import enrich_order, transition_order_status
from app.models.order import Order, OrderStatus
from app.models.product import Product
from app.models.shop import Shop, ShopStatus
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
    rows = (await db.scalars(base.order_by(Order.id.desc()).limit(limit).offset(offset))).all()
    return Page[OrderOut](
        items=[await enrich_order(o, db, include_phone=True) for o in rows],
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
    order = (await db.scalars(
        select(Order).where(Order.id == order_id).with_for_update()
    )).first()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    await transition_order_status(order, payload.status, db, actor="admin")
    return order


# ========== STATS ==========
@router.get("/stats", response_model=AdminStats)
async def get_stats(db: AsyncSession = Depends(get_db)):
    users_total = await db.scalar(select(func.count()).select_from(User))
    sellers_total = await db.scalar(
        select(func.count()).select_from(User).where(User.role == UserRole.seller)
    )
    shops_total = await db.scalar(select(func.count()).select_from(Shop))
    shops_pending = await db.scalar(
        select(func.count()).select_from(Shop).where(Shop.status == ShopStatus.pending)
    )
    products_total = await db.scalar(select(func.count()).select_from(Product))
    orders_total = await db.scalar(select(func.count()).select_from(Order))
    # Faqat yetkazib berilgan (pul haqiqatan qo'lga tegan) buyurtmalar —
    # 'paid' offline oqimda faqat "sotuvchi tasdiqladi" degani, pul hali
    # kuryerda/yetkazilmagan bo'lishi mumkin.
    revenue = await db.scalar(
        select(func.coalesce(func.sum(Order.total), 0)).where(
            Order.status == OrderStatus.delivered
        )
    )
    return AdminStats(
        users_total=users_total or 0,
        sellers_total=sellers_total or 0,
        shops_total=shops_total or 0,
        shops_pending=int(shops_pending or 0),
        products_total=products_total or 0,
        orders_total=orders_total or 0,
        revenue_total=float(revenue or Decimal("0")),
    )


# ========== SHOPS / KYC ==========

class ShopStatusUpdate(BaseModel):
    status: ShopStatus
    admin_note: str | None = Field(default=None, max_length=500)


class ShopAdminOut(BaseModel):
    id: int
    owner_id: int
    name: str
    description: str | None
    status: ShopStatus
    admin_note: str | None
    is_active: bool
    created_at: str
    owner_phone: str | None = None
    product_count: int = 0

    model_config = {"from_attributes": True}

    @classmethod
    def model_validate(cls, obj, **kw):  # type: ignore[override]
        return cls(
            id=obj.id,
            owner_id=obj.owner_id,
            name=obj.name,
            description=obj.description,
            status=obj.status,
            admin_note=obj.admin_note,
            is_active=obj.is_active,
            created_at=str(obj.created_at),
        )


@router.get("/shops", response_model=Page[ShopAdminOut])
async def list_shops(
    db: AsyncSession = Depends(get_db),
    status_filter: ShopStatus | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    """Barcha do'konlar ro'yxati — status bo'yicha filtrlash mumkin."""
    base = select(Shop)
    if status_filter is not None:
        base = base.where(Shop.status == status_filter)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = (await db.scalars(base.order_by(Shop.id.desc()).limit(limit).offset(offset))).all()

    owner_ids = [s.owner_id for s in rows]
    phone_map: dict[int, str] = {}
    if owner_ids:
        owners = (await db.scalars(select(User).where(User.id.in_(owner_ids)))).all()
        phone_map = {u.id: u.phone for u in owners if u.phone}

    count_map: dict[int, int] = {}
    shop_ids = [s.id for s in rows]
    if shop_ids:
        count_rows = (await db.execute(
            select(Product.shop_id, func.count()).where(Product.shop_id.in_(shop_ids)).group_by(Product.shop_id)
        )).all()
        count_map = {shop_id: count for shop_id, count in count_rows}

    items = []
    for s in rows:
        out = ShopAdminOut.model_validate(s)
        out.owner_phone = phone_map.get(s.owner_id)
        out.product_count = count_map.get(s.id, 0)
        items.append(out)

    return Page[ShopAdminOut](
        items=items,
        total=total or 0,
        limit=limit,
        offset=offset,
    )


@router.patch("/shops/{shop_id}", response_model=ShopAdminOut)
async def update_shop_status(
    shop_id: int,
    payload: ShopStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Do'konni tasdiqlash yoki rad etish (KYC)."""
    shop = await db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="Do'kon topilmadi")
    shop.status = payload.status
    if payload.admin_note is not None:
        shop.admin_note = payload.admin_note
    await db.commit()
    await db.refresh(shop)
    return ShopAdminOut.model_validate(shop)


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
