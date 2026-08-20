"""Admin endpointlar — faqat role=admin uchun."""
import json
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from pydantic import BaseModel, Field

from app.api.app_version import _VERSION_FILE, AppVersionOut
from app.api.deps import require_admin
from app.api.kits import _kit_out, _load_items
from app.api.products import _load_variants_map, _product_out
from app.core.moderation import admin_direct_edit, approve, reject
from app.core.push import send_push_to_user
from app.db.session import get_db
from app.models.notification import Notification
from app.api.cart import enrich_order, transition_order_status
from app.models.order import Order, OrderStatus
from app.models.product import Product, ProductStatus
from app.models.product_set import ProductSet
from app.models.product_variant import ProductVariant
from app.models.shop import Shop, ShopStatus
from app.models.user import User, UserRole
from app.schemas.admin import AdminStats, OrderStatusUpdate, UserAdminUpdate
from app.schemas.auth import UserOut
from app.schemas.common import Page
from app.schemas.marketplace import KitOut, OrderOut, ProductOut

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


# ========== MODERATSIYA (mahsulot/to'plam tasdiqlash) ==========

class RejectRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=1000)


class BulkModerationRequest(BaseModel):
    ids: list[int] = Field(min_length=1, max_length=200)


class ProductDirectEditRequest(BaseModel):
    """Admin "tuzatib tasdiqlash" — himoyalangan maydonni to'g'ridan-to'g'ri
    tahrirlab, shu bilan birga tasdiqlaydi (sellerga qaytarmasdan)."""
    name: str | None = None
    brand: str | None = None
    description: str | None = None
    category_id: int | None = None
    image_url: str | None = None


@router.get("/moderation/products", response_model=Page[ProductOut])
async def list_products_for_moderation(
    db: AsyncSession = Depends(get_db),
    status_filter: ProductStatus | None = Query(default=ProductStatus.pending, alias="status"),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    """Moderatsiya navbati — sukut bo'yicha faqat 'pending'."""
    base = select(Product)
    if status_filter is not None:
        base = base.where(Product.status == status_filter)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = (await db.scalars(base.order_by(Product.submitted_at).limit(limit).offset(offset))).all()

    variants_map = await _load_variants_map(db, [p.id for p in rows])
    shop_ids = {p.shop_id for p in rows}
    shop_map: dict[int, Shop] = {}
    if shop_ids:
        shops = (await db.scalars(select(Shop).where(Shop.id.in_(shop_ids)))).all()
        shop_map = {s.id: s for s in shops}

    items = [
        await _product_out(
            p, variants_map.get(p.id, []),
            shop_map[p.shop_id].name if p.shop_id in shop_map else None,
        )
        for p in rows
    ]
    return Page[ProductOut](items=items, total=total or 0, limit=limit, offset=offset)


async def _get_product_or_404(db: AsyncSession, product_id: int) -> Product:
    p = await db.get(Product, product_id)
    if not p:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    return p


async def _product_moderation_out(db: AsyncSession, p: Product) -> ProductOut:
    variants = (await db.scalars(
        select(ProductVariant).where(ProductVariant.product_id == p.id)
    )).all()
    shop = await db.get(Shop, p.shop_id)
    return await _product_out(p, list(variants), shop.name if shop else None)


@router.post("/moderation/products/{product_id}/approve", response_model=ProductOut)
async def approve_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    p = await _get_product_or_404(db, product_id)
    approve(p, current_user.id)
    await db.commit()
    await db.refresh(p)
    return await _product_moderation_out(db, p)


@router.post("/moderation/products/{product_id}/reject", response_model=ProductOut)
async def reject_product(
    product_id: int,
    payload: RejectRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    p = await _get_product_or_404(db, product_id)
    reject(p, current_user.id, payload.reason)
    await db.commit()
    await db.refresh(p)
    return await _product_moderation_out(db, p)


@router.post("/moderation/products/{product_id}/edit-approve", response_model=ProductOut)
async def edit_approve_product(
    product_id: int,
    payload: ProductDirectEditRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Admin sellerga qaytarmasdan o'zi tahrirlab, shu zahoti tasdiqlaydi."""
    p = await _get_product_or_404(db, product_id)
    changed = payload.model_dump(exclude_unset=True)
    if changed:
        admin_direct_edit(p, changed)
    approve(p, current_user.id)
    await db.commit()
    await db.refresh(p)
    return await _product_moderation_out(db, p)


@router.post("/moderation/products/bulk-approve")
async def bulk_approve_products(
    payload: BulkModerationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    rows = (await db.scalars(select(Product).where(Product.id.in_(payload.ids)))).all()
    for p in rows:
        approve(p, current_user.id)
    await db.commit()
    return {"approved": len(rows)}


@router.get("/moderation/kits", response_model=Page[KitOut])
async def list_kits_for_moderation(
    db: AsyncSession = Depends(get_db),
    status_filter: ProductStatus | None = Query(default=ProductStatus.pending, alias="status"),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    base = select(ProductSet)
    if status_filter is not None:
        base = base.where(ProductSet.status == status_filter)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    rows = (await db.scalars(base.order_by(ProductSet.submitted_at).limit(limit).offset(offset))).all()

    items = [await _kit_out(s, await _load_items(db, s.id), db) for s in rows]
    return Page[KitOut](items=items, total=total or 0, limit=limit, offset=offset)


async def _get_kit_or_404(db: AsyncSession, kit_id: int) -> ProductSet:
    kit = await db.get(ProductSet, kit_id)
    if not kit:
        raise HTTPException(status_code=404, detail="To'plam topilmadi")
    return kit


@router.post("/moderation/kits/{kit_id}/approve", response_model=KitOut)
async def approve_kit(
    kit_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    kit = await _get_kit_or_404(db, kit_id)
    approve(kit, current_user.id)
    await db.commit()
    await db.refresh(kit)
    return await _kit_out(kit, await _load_items(db, kit.id), db)


@router.post("/moderation/kits/{kit_id}/reject", response_model=KitOut)
async def reject_kit(
    kit_id: int,
    payload: RejectRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    kit = await _get_kit_or_404(db, kit_id)
    reject(kit, current_user.id, payload.reason)
    await db.commit()
    await db.refresh(kit)
    return await _kit_out(kit, await _load_items(db, kit.id), db)


@router.post("/moderation/kits/bulk-approve")
async def bulk_approve_kits(
    payload: BulkModerationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    rows = (await db.scalars(select(ProductSet).where(ProductSet.id.in_(payload.ids)))).all()
    for kit in rows:
        approve(kit, current_user.id)
    await db.commit()
    return {"approved": len(rows)}


# ========== APP VERSION ==========
class AppVersionUpdateRequest(BaseModel):
    app: Literal["user", "seller"]
    version: str = Field(min_length=1, max_length=20)
    build: int = Field(ge=1)
    apk_url: str = Field(min_length=1, max_length=500)
    notes: str = ""
    force: bool = False


@router.put("/app-version", response_model=AppVersionOut)
async def update_app_version(payload: AppVersionUpdateRequest):
    """`release.sh` qiladigan ishni admin panel orqali qiladi — konteyner
    qayta ishga tushirilmaydi, faylga to'g'ridan-to'g'ri yoziladi."""
    try:
        with open(_VERSION_FILE) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        data = {}
    data[payload.app] = payload.model_dump(exclude={"app"})
    with open(_VERSION_FILE, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    return AppVersionOut(**data[payload.app])
