"""Category endpointlari — kategoriyalarni o'qish va admin yaratish."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.category_icons import ALLOWED_CATEGORY_ICONS
from app.db.session import get_db
from app.models.category import Category
from app.models.product import Product
from app.models.shop import Shop, ShopStatus
from app.models.user import User, UserRole
from app.schemas.marketplace import (
    CategoryCreate,
    CategoryOut,
    CategoryReorderRequest,
    CategoryUpdate,
)

router = APIRouter(prefix="/categories", tags=["categories"])


def _check_icon(icon: str | None) -> None:
    if icon is not None and icon not in ALLOWED_CATEGORY_ICONS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Noma'lum ikonka: {icon}",
        )


@router.get("", response_model=list[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    rows = list(await db.scalars(select(Category).order_by(Category.sort_order, Category.id)))
    # Faol/tasdiqlangan do'kondagi mahsulotlar soni — Market ekranida ko'rsatish uchun
    counts = dict((await db.execute(
        select(Product.category_id, func.count())
        .join(Shop, Shop.id == Product.shop_id)
        .where(Product.is_active.is_(True), Shop.status == ShopStatus.approved)
        .group_by(Product.category_id)
    )).all())
    return [
        CategoryOut(
            id=c.id, name=c.name, slug=c.slug, parent_id=c.parent_id,
            icon=c.icon, color=c.color, sort_order=c.sort_order,
            product_count=counts.get(c.id, 0),
        )
        for c in rows
    ]


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(
    payload: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in (UserRole.admin, UserRole.seller):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Faqat admin yoki sotuvchi kategoriya qo'sha oladi",
        )
    _check_icon(payload.icon)
    max_sort = await db.scalar(select(func.max(Category.sort_order)))
    cat = Category(
        name=payload.name, slug=payload.slug, parent_id=payload.parent_id,
        icon=payload.icon, color=payload.color, sort_order=(max_sort or 0) + 10,
    )
    db.add(cat)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="Slug band yoki parent yo'q")
    await db.refresh(cat)
    return cat


@router.patch("/reorder", response_model=list[CategoryOut])
async def reorder_categories(
    payload: CategoryReorderRequest,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    ids = [item.id for item in payload.items]
    rows = {c.id: c for c in await db.scalars(select(Category).where(Category.id.in_(ids)))}
    missing = set(ids) - set(rows)
    if missing:
        raise HTTPException(status_code=404, detail=f"Kategoriya topilmadi: {sorted(missing)}")
    for item in payload.items:
        rows[item.id].sort_order = item.sort_order
    await db.commit()
    return await list_categories(db)


@router.patch("/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    payload: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in (UserRole.admin, UserRole.seller):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Faqat admin yoki sotuvchi kategoriya o'zgartira oladi",
        )
    cat = await db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    changed = payload.model_dump(exclude_unset=True)
    if "icon" in changed:
        _check_icon(changed["icon"])
    for field, value in changed.items():
        setattr(cat, field, value)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="Slug band yoki parent yo'q")
    await db.refresh(cat)
    return cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Faqat admin o'chira oladi")
    cat = await db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    await db.delete(cat)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Kategoriyani o'chirib bo'lmadi (bog'liq mahsulotlar bor)")
