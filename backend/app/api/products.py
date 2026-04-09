"""Product endpointlari — listing, yaratish, yangilash, o'chirish, rasm yuklash."""
import secrets
from decimal import Decimal
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.storage import PRODUCTS_DIR, public_url
from app.db.session import get_db
from app.models.product import Product
from app.models.product_image import ProductImage
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.schemas.common import Page
from app.schemas.marketplace import ProductCreate, ProductOut, ProductUpdate


async def _product_with_shop(p: Product, db: AsyncSession) -> ProductOut:
    """ProductOut + shop_name."""
    out = ProductOut.model_validate(p)
    shop = await db.get(Shop, p.shop_id)
    if shop:
        out.shop_name = shop.name
    return out

# Ruxsat etilgan rasm formatlari va max hajm
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB

router = APIRouter(prefix="/products", tags=["products"])


@router.get("", response_model=Page[ProductOut])
async def list_products(
    db: AsyncSession = Depends(get_db),
    q: str | None = Query(default=None, description="Nomda qidirish (case-insensitive)"),
    shop_id: int | None = Query(default=None),
    category_id: int | None = Query(default=None),
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    sort: str | None = Query(default=None, description="price_asc, price_desc, newest, rating"),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    base = select(Product).where(Product.is_active.is_(True))
    if q:
        base = base.where(Product.name.ilike(f"%{q}%"))
    if shop_id is not None:
        base = base.where(Product.shop_id == shop_id)
    if category_id is not None:
        base = base.where(Product.category_id == category_id)
    if min_price is not None:
        base = base.where(Product.price >= min_price)
    if max_price is not None:
        base = base.where(Product.price <= max_price)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    order_clause = Product.id.desc()
    if sort == "price_asc":
        order_clause = Product.price.asc()
    elif sort == "price_desc":
        order_clause = Product.price.desc()
    elif sort == "newest":
        order_clause = Product.id.desc()
    rows = await db.scalars(
        base.order_by(order_clause).limit(limit).offset(offset)
    )
    return Page[ProductOut](
        items=[await _product_with_shop(p, db) for p in rows],
        total=total or 0,
        limit=limit,
        offset=offset,
    )


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(product_id: int, db: AsyncSession = Depends(get_db)):
    p = await db.get(Product, product_id)
    if not p:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    return await _product_with_shop(p, db)


async def _ensure_shop_owner(db: AsyncSession, shop_id: int, user: User) -> Shop:
    shop = await db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="Do'kon topilmadi")
    if shop.owner_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Bu do'kon sizniki emas")
    return shop


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    payload: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _ensure_shop_owner(db, payload.shop_id, current_user)
    product = Product(
        shop_id=payload.shop_id,
        category_id=payload.category_id,
        name=payload.name,
        description=payload.description,
        price=payload.price,
        stock=payload.stock,
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


@router.patch("/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: int,
    payload: ProductUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    await db.commit()
    await db.refresh(product)
    return product


@router.post("/{product_id}/image", response_model=ProductOut)
async def upload_product_image(
    product_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mahsulotga rasm yuklash. Bitta asosiy rasm — eskisini almashtiradi."""
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Faqat JPEG, PNG yoki WebP rasm yuklash mumkin",
        )

    contents = await file.read()
    if len(contents) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Rasm 5MB dan katta")
    if not contents:
        raise HTTPException(status_code=400, detail="Bo'sh fayl")

    ext = ALLOWED_IMAGE_TYPES[file.content_type]
    filename = f"{product_id}_{secrets.token_hex(8)}{ext}"
    dest: Path = PRODUCTS_DIR / filename
    dest.write_bytes(contents)

    # Eski rasmni o'chirish (agar bor bo'lsa va lokal bo'lsa)
    if product.image_url and product.image_url.startswith("/static/"):
        old = PRODUCTS_DIR.parent / product.image_url[len("/static/") :]
        try:
            old.unlink(missing_ok=True)
        except OSError:
            pass

    product.image_url = public_url(f"products/{filename}")
    await db.commit()
    await db.refresh(product)
    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    await db.delete(product)
    await db.commit()


@router.get("/{product_id}/images")
async def list_product_images(product_id: int, db: AsyncSession = Depends(get_db)):
    """Mahsulotning barcha rasmlari."""
    rows = (await db.scalars(
        select(ProductImage).where(ProductImage.product_id == product_id).order_by(ProductImage.sort_order)
    )).all()
    return [{"id": img.id, "image_url": img.image_url, "sort_order": img.sort_order} for img in rows]


@router.post("/{product_id}/images", status_code=status.HTTP_201_CREATED)
async def add_product_image(
    product_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mahsulotga qo'shimcha rasm qo'shish."""
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Faqat JPEG/PNG/WebP")
    contents = await file.read()
    if len(contents) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Rasm 5MB dan katta")

    ext = ALLOWED_IMAGE_TYPES[file.content_type]
    filename = f"{product_id}_{secrets.token_hex(8)}{ext}"
    (PRODUCTS_DIR / filename).write_bytes(contents)

    img = ProductImage(product_id=product_id, image_url=public_url(f"products/{filename}"))
    db.add(img)
    await db.commit()
    await db.refresh(img)
    return {"id": img.id, "image_url": img.image_url}
