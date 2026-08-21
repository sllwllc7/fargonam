"""Category endpointlari — kategoriyalarni o'qish va admin yaratish."""
import secrets

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.api.products import ALLOWED_IMAGE_TYPES, MAX_IMAGE_BYTES, _validate_image_magic
from app.core.category_icons import ALLOWED_CATEGORY_ICONS
from app.core.image_processing import process_product_image
from app.core.storage import CATEGORIES_DIR, public_url
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
            image_url=c.image_url, thumb_url=c.thumb_url,
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


def _check_category_edit_permission(current_user: User) -> None:
    if current_user.role not in (UserRole.admin, UserRole.seller):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Faqat admin yoki sotuvchi kategoriya o'zgartira oladi",
        )


def _delete_local_category_image(url: str | None) -> None:
    if url and url.startswith("/static/"):
        path = CATEGORIES_DIR.parent / url[len("/static/"):]
        try:
            path.unlink(missing_ok=True)
        except OSError:
            pass


@router.post("/{category_id}/image", response_model=CategoryOut)
async def upload_category_image(
    category_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kategoriyaga rasm yuklash — mahsulot rasmi bilan bir xil qayta ishlov
    (siqish, max o'lcham, kvadrat preview). Bitta rasm — yuklansa eskisini
    almashtiradi, ikonka esa rasm bo'lmagan holat uchun zaxira bo'lib qoladi
    (bu yerda o'chirilmaydi)."""
    _check_category_edit_permission(current_user)
    cat = await db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Faqat JPEG, PNG yoki WebP rasm yuklash mumkin")
    contents = await file.read()
    if len(contents) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Rasm 5MB dan katta")
    if not contents:
        raise HTTPException(status_code=400, detail="Bo'sh fayl")
    if _validate_image_magic(contents) is None:
        raise HTTPException(status_code=400, detail="Fayl haqiqiy rasm emas")

    try:
        main_bytes, thumb_bytes = process_product_image(contents)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    token = secrets.token_hex(8)
    filename = f"{category_id}_{token}.jpg"
    thumb_filename = f"{category_id}_{token}_thumb.jpg"
    (CATEGORIES_DIR / filename).write_bytes(main_bytes)
    (CATEGORIES_DIR / thumb_filename).write_bytes(thumb_bytes)

    _delete_local_category_image(cat.image_url)
    _delete_local_category_image(cat.thumb_url)

    cat.image_url = public_url(f"categories/{filename}")
    cat.thumb_url = public_url(f"categories/{thumb_filename}")
    await db.commit()
    await db.refresh(cat)
    return cat


@router.delete("/{category_id}/image", response_model=CategoryOut)
async def delete_category_image(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kategoriya rasmini o'chiradi — UI ikonkaga qaytadi (ikonka har doim
    saqlanadi, shu uchun bu amal xavfsiz)."""
    _check_category_edit_permission(current_user)
    cat = await db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    _delete_local_category_image(cat.image_url)
    _delete_local_category_image(cat.thumb_url)
    cat.image_url = None
    cat.thumb_url = None
    await db.commit()
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
