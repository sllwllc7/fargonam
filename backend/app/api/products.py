"""Product endpointlari — katalog (parent+variant), variant CRUD, rasm yuklash."""
import secrets
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_current_user_optional
from app.core.image_processing import process_product_image
from app.core.moderation import stage_protected_update
from app.core.storage import PRODUCTS_DIR, delete_file, public_url
from app.db.session import get_db
from app.models.cart import CartItem
from app.models.favorite import Favorite
from app.models.product import Product, ProductStatus
from app.models.product_image import ProductImage
from app.models.product_variant import ProductVariant
from app.models.review import Review
from app.models.shop import Shop, ShopStatus
from app.models.user import User, UserRole
from app.schemas.common import Page
from app.schemas.marketplace import (
    ProductCreate,
    ProductImageReorderRequest,
    ProductOut,
    ProductUpdate,
    VariantCreate,
    VariantOut,
    VariantUpdate,
)

router = APIRouter(prefix="/products", tags=["products"])


def _default_variant(variants: list[ProductVariant]) -> ProductVariant | None:
    """Mobile_seller/eski UI moslik uchun "asosiy" variant — birinchi yaratilgan
    (sort_order, keyin id bo'yicha)."""
    if not variants:
        return None
    return sorted(variants, key=lambda v: (v.sort_order, v.id))[0]


def _generate_sku(product_id: int) -> str:
    return f"SKU-{product_id}-{secrets.token_hex(4)}"


async def _product_out(
    p: Product,
    variants: list[ProductVariant],
    shop_name: str | None = None,
    seller_phone: str | None = None,
) -> ProductOut:
    active_variants = [v for v in variants if v.is_active]
    # Eski moslik price/stock maydonlari xaridor haqiqatda savatga qo'sha
    # oladigan variant bilan mos kelishi uchun avval FAOL variantlardan
    # tanlanadi (cart.py:_resolve_variant_id bilan bir xil semantika) —
    # aks holda nofaol variant narxi ko'rsatilib, savatga qo'shilgan narx
    # bilan mos kelmasligi mumkin edi.
    default = _default_variant(active_variants) or _default_variant(variants)
    prices = [v.price for v in active_variants]
    out = ProductOut(
        id=p.id,
        shop_id=p.shop_id,
        category_id=p.category_id,
        name=p.name,
        slug=p.slug,
        brand=p.brand,
        description=p.description,
        image_url=p.image_url,
        thumb_url=p.thumb_url,
        is_active=p.is_active,
        created_at=p.created_at,
        shop_name=shop_name,
        seller_phone=seller_phone,
        status=p.status.value,
        rejected_reason=p.rejected_reason,
        pending_edit=p.pending_edit,
        submitted_at=p.submitted_at,
        variants=[VariantOut.model_validate(v) for v in variants],
        min_price=Decimal(min(prices)) if prices else None,
        max_price=Decimal(max(prices)) if prices else None,
        total_stock=sum(v.stock for v in active_variants),
        price=Decimal(default.price) if default else None,
        stock=default.stock if default else None,
    )
    return out


async def _load_variants_map(db: AsyncSession, product_ids: list[int]) -> dict[int, list[ProductVariant]]:
    if not product_ids:
        return {}
    rows = (await db.scalars(
        select(ProductVariant)
        .where(ProductVariant.product_id.in_(product_ids))
        .order_by(ProductVariant.sort_order, ProductVariant.id)
    )).all()
    result: dict[int, list[ProductVariant]] = {pid: [] for pid in product_ids}
    for v in rows:
        result.setdefault(v.product_id, []).append(v)
    return result


async def _can_view_unapproved_shop(db: AsyncSession, shop_id: int, user: User | None) -> bool:
    """Do'kon KYC holati approved bo'lmasa ham, do'kon egasi (yoki admin)
    o'z mahsulotlarini ko'ra olishi kerak — aks holda ularni nofaol ham
    qila olmaydi (Shop.status katalog filtridan bypass)."""
    if user is None:
        return False
    if user.role == UserRole.admin:
        return True
    shop = await db.get(Shop, shop_id)
    return bool(shop and shop.owner_id == user.id)


@router.get("", response_model=Page[ProductOut])
async def list_products(
    db: AsyncSession = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
    q: str | None = Query(default=None, max_length=100, description="Nomda qidirish (case-insensitive)"),
    shop_id: int | None = Query(default=None),
    category_id: int | None = Query(default=None),
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    sort: str | None = Query(default=None, description="price_asc, price_desc, newest, rating"),
    limit: int = Query(default=50, le=200, ge=1),
    offset: int = Query(default=0, ge=0),
):
    # Har mahsulot uchun narx/stok agregatlari (faqat faol variantlar)
    agg = (
        select(
            ProductVariant.product_id.label("product_id"),
            func.min(ProductVariant.price).label("min_price"),
            func.max(ProductVariant.price).label("max_price"),
        )
        .where(ProductVariant.is_active.is_(True))
        .group_by(ProductVariant.product_id)
        .subquery()
    )

    base = (
        select(Product, agg.c.min_price, agg.c.max_price)
        .join(agg, agg.c.product_id == Product.id)
        .where(Product.is_active.is_(True))
    )
    # KYC tasdiqlanmagan do'kon mahsulotlari va moderatsiyadan o'tmagan
    # mahsulotlar ommaviy katalogda ko'rinmaydi — bundan mustasno: so'rovchi
    # aynan shu do'konni so'rayotgan egasi/admin (moderatsiya holatidan
    # qat'iy nazar o'z mahsulotini ko'ra olishi kerak)
    if shop_id is None or not await _can_view_unapproved_shop(db, shop_id, current_user):
        base = base.join(Shop, Shop.id == Product.shop_id).where(Shop.status == ShopStatus.approved)
        base = base.where(Product.status == ProductStatus.approved)
    if q:
        # LIKE maxsus belgilarini escape qilish
        safe_q = q.replace("%", r"\%").replace("_", r"\_")
        variant_name_match = select(ProductVariant.product_id).where(
            ProductVariant.variant_name.ilike(f"%{safe_q}%")
        )
        base = base.where(
            or_(Product.name.ilike(f"%{safe_q}%"), Product.id.in_(variant_name_match))
        )
    if shop_id is not None:
        base = base.where(Product.shop_id == shop_id)
    if category_id is not None:
        base = base.where(Product.category_id == category_id)
    if min_price is not None:
        base = base.where(agg.c.max_price >= min_price)
    if max_price is not None:
        base = base.where(agg.c.min_price <= max_price)

    total = await db.scalar(select(func.count()).select_from(base.subquery()))
    order_clause = Product.id.desc()
    if sort == "price_asc":
        order_clause = agg.c.min_price.asc()
    elif sort == "price_desc":
        order_clause = agg.c.max_price.desc()
    elif sort == "newest":
        order_clause = Product.id.desc()
    rows = (await db.execute(
        base.order_by(order_clause).limit(limit).offset(offset)
    )).all()
    products = [row[0] for row in rows]

    # Barcha shoplar va variantlarni bir so'rovda olish (N+1 o'rniga)
    shop_ids = list({p.shop_id for p in products})
    shops = (await db.scalars(select(Shop).where(Shop.id.in_(shop_ids)))).all() if shop_ids else []
    shop_map = {s.id: s for s in shops}
    variants_map = await _load_variants_map(db, [p.id for p in products])

    items = [
        await _product_out(p, variants_map.get(p.id, []), shop_map.get(p.shop_id).name if shop_map.get(p.shop_id) else None)
        for p in products
    ]

    return Page[ProductOut](
        items=items,
        total=total or 0,
        limit=limit,
        offset=offset,
    )


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    p = await db.get(Product, product_id)
    if not p or not p.is_active:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    shop = await db.get(Shop, p.shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    # KYC tasdiqlanmagan do'kon yoki moderatsiyadan o'tmagan mahsulot —
    # do'kon egasi/admin bundan mustasno
    unapproved = shop.status != ShopStatus.approved or p.status != ProductStatus.approved
    if unapproved and not await _can_view_unapproved_shop(db, shop.id, current_user):
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    variants = (await db.scalars(
        select(ProductVariant)
        .where(ProductVariant.product_id == product_id)
        .order_by(ProductVariant.sort_order, ProductVariant.id)
    )).all()
    return await _product_out(p, list(variants), shop.name)


async def _ensure_shop_owner(db: AsyncSession, shop_id: int, user: User) -> Shop:
    shop = await db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="Do'kon topilmadi")
    if shop.owner_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Bu do'kon sizniki emas")
    # Admin bo'lmasa — do'kon tasdiqlanganligini tekshirish
    if user.role != UserRole.admin and shop.status != ShopStatus.approved:
        raise HTTPException(
            status_code=403,
            detail="Do'koningiz hali admin tomonidan tasdiqlanmagan. Tasdiqlashni kuting.",
        )
    return shop


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    payload: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mahsulot yaratadi + `price`/`stock`dan avtomatik "default" variant."""
    await _ensure_shop_owner(db, payload.shop_id, current_user)
    product = Product(
        shop_id=payload.shop_id,
        category_id=payload.category_id,
        name=payload.name,
        brand=payload.brand,
        description=payload.description,
        status=ProductStatus.pending,
    )
    db.add(product)
    await db.flush()  # product.id kerak

    variant = ProductVariant(
        product_id=product.id,
        sku=_generate_sku(product.id),
        variant_name="Standart",
        price=int(payload.price),
        stock=payload.stock,
    )
    db.add(variant)
    await db.commit()
    await db.refresh(product)
    await db.refresh(variant)
    return await _product_out(product, [variant])


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

    data = payload.model_dump(exclude_unset=True)
    price = data.pop("price", None)
    stock = data.pop("stock", None)
    # is_active — ko'rinish tugmasi (yashirish/ko'rsatish), moderatsiya emas,
    # darhol qo'llanadi
    is_active = data.pop("is_active", None)
    if is_active is not None:
        product.is_active = is_active
    # Qolgan maydonlar (name/brand/description/category_id) — himoyalangan,
    # tasdiqlangan mahsulotda staging orqali o'tadi (moderation.py)
    stage_protected_update(product, data)

    variants = (await db.scalars(
        select(ProductVariant)
        .where(ProductVariant.product_id == product_id)
        .order_by(ProductVariant.sort_order, ProductVariant.id)
    )).all()
    if price is not None or stock is not None:
        active_variants = [v for v in variants if v.is_active]
        default = _default_variant(active_variants) or _default_variant(list(variants))
        if default is None:
            # Eski mahsulotda variant bo'lmasa (bo'lmasligi kerak, lekin himoya) — yaratamiz
            default = ProductVariant(
                product_id=product.id,
                sku=_generate_sku(product.id),
                variant_name="Standart",
                price=int(price) if price is not None else 1,
                stock=stock if stock is not None else 0,
            )
            db.add(default)
            variants = [*variants, default]
        else:
            if price is not None:
                default.price = int(price)
            if stock is not None:
                default.stock = stock

    await db.commit()
    await db.refresh(product)
    variants = (await db.scalars(
        select(ProductVariant)
        .where(ProductVariant.product_id == product_id)
        .order_by(ProductVariant.sort_order, ProductVariant.id)
    )).all()
    return await _product_out(product, list(variants))


@router.delete("/{product_id}")
async def delete_product(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)

    variant_ids = (await db.scalars(
        select(ProductVariant.id).where(ProductVariant.product_id == product_id)
    )).all()

    if variant_ids:
        in_cart = await db.scalar(
            select(func.count()).select_from(CartItem).where(CartItem.variant_id.in_(variant_ids))
        )
        if in_cart:
            raise HTTPException(
                status_code=400,
                detail="Bu mahsulot xaridorlar savatchasida bor, o'chirib bo'lmaydi. Buning o'rniga nofaol qiling.",
            )

    in_favorites = await db.scalar(
        select(func.count()).select_from(Favorite).where(Favorite.product_id == product_id)
    )
    if in_favorites:
        raise HTTPException(
            status_code=400,
            detail="Bu mahsulot xaridorlar sevimlilarida bor, o'chirib bo'lmaydi. Buning o'rniga nofaol qiling.",
        )

    # Sharhlar bloklanmaydi — sharhni sotuvchi o'chira olmaydi (xaridorniki),
    # bloklasak mahsulot abadiy o'chmas bo'lib qolardi. O'chishiga ruxsat
    # beramiz (CASCADE), lekin nechtasi o'chganini javobda qaytaramiz.
    reviews_count = await db.scalar(
        select(func.count()).select_from(Review).where(Review.product_id == product_id)
    ) or 0

    await db.delete(product)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Bu mahsulot buyurtmalar tarixida ishlatilgan, o'chirib bo'lmaydi. Buning o'rniga nofaol qiling.",
        )
    return {"deleted": True, "deleted_reviews": reviews_count}


# ── Variant CRUD (qo'shimcha variantlar — hozircha /docs orqali qo'lda) ──

@router.post("/{product_id}/variants", response_model=VariantOut, status_code=status.HTTP_201_CREATED)
async def create_variant(
    product_id: int,
    payload: VariantCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    variant = ProductVariant(
        product_id=product_id,
        sku=payload.sku or _generate_sku(product_id),
        variant_name=payload.variant_name,
        price=payload.price,
        old_price=payload.old_price,
        stock=payload.stock,
        attributes=payload.attributes,
        image_url=payload.image_url,
        sort_order=payload.sort_order,
    )
    db.add(variant)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        raise HTTPException(status_code=409, detail="Bu SKU allaqachon band")
    await db.refresh(variant)
    return variant


@router.patch("/{product_id}/variants/{variant_id}", response_model=VariantOut)
async def update_variant(
    product_id: int,
    variant_id: int,
    payload: VariantUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    variant = await db.get(ProductVariant, variant_id)
    if not variant or variant.product_id != product_id:
        raise HTTPException(status_code=404, detail="Variant topilmadi")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(variant, field, value)
    await db.commit()
    await db.refresh(variant)
    return variant


@router.delete("/{product_id}/variants/{variant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_variant(
    product_id: int,
    variant_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    variant = await db.get(ProductVariant, variant_id)
    if not variant or variant.product_id != product_id:
        raise HTTPException(status_code=404, detail="Variant topilmadi")
    remaining = await db.scalar(
        select(func.count()).select_from(ProductVariant).where(ProductVariant.product_id == product_id)
    )
    if (remaining or 0) <= 1:
        raise HTTPException(status_code=400, detail="Mahsulotda kamida bitta variant qolishi kerak")

    in_cart = await db.scalar(
        select(func.count()).select_from(CartItem).where(CartItem.variant_id == variant_id)
    )
    if in_cart:
        raise HTTPException(
            status_code=400,
            detail="Bu variant xaridorlar savatchasida bor, o'chirib bo'lmaydi. Buning o'rniga nofaol qiling.",
        )

    await db.delete(variant)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Bu variant buyurtmalar tarixida ishlatilgan, o'chirib bo'lmaydi. Buning o'rniga nofaol qiling.",
        )


# ── Ruxsat etilgan rasm formatlari va max hajm ──

ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB

# Fayl boshidagi "magic bytes" — haqiqiy rasm ekanligini tekshirish uchun
# (client content_type'ni aldashi mumkin)
_MAGIC_BYTES = {
    b"\xff\xd8\xff": ".jpg",      # JPEG
    b"\x89PNG\r\n\x1a\n": ".png", # PNG
    b"RIFF": ".webp",             # WebP (RIFF...WEBP)
}


def _validate_image_magic(data: bytes) -> str | None:
    """Fayl boshidagi baytlardan haqiqiy formatni aniqlaydi. None = noma'lum."""
    for magic, ext in _MAGIC_BYTES.items():
        if data[:len(magic)] == magic:
            if ext == ".webp" and data[8:12] != b"WEBP":
                continue
            return ext
    return None


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

    # Magic bytes tekshiruvi — content_type aldanishi mumkin
    if _validate_image_magic(contents) is None:
        raise HTTPException(status_code=400, detail="Fayl haqiqiy rasm emas")

    try:
        main_bytes, thumb_bytes = process_product_image(contents)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    token = secrets.token_hex(8)
    filename = f"{product_id}_{token}.jpg"
    thumb_filename = f"{product_id}_{token}_thumb.jpg"
    (PRODUCTS_DIR / filename).write_bytes(main_bytes)
    (PRODUCTS_DIR / thumb_filename).write_bytes(thumb_bytes)

    # Eski rasmlarni o'chirish (agar bor bo'lsa, lokal bo'lsa VA hozir stagelanmagan
    # bo'lsa — tasdiqlangan mahsulotda eski rasm hali User App'da ko'rinib
    # turishi kerak, o'chirib bo'lmaydi)
    if product.status != ProductStatus.approved:
        for old_url in (product.image_url, product.thumb_url):
            if old_url and old_url.startswith("/static/"):
                old = PRODUCTS_DIR.parent / old_url[len("/static/") :]
                try:
                    old.unlink(missing_ok=True)
                except OSError:
                    pass

    stage_protected_update(product, {
        "image_url": public_url(f"products/{filename}"),
        "thumb_url": public_url(f"products/{thumb_filename}"),
    })
    await db.commit()
    await db.refresh(product)
    variants = (await db.scalars(
        select(ProductVariant).where(ProductVariant.product_id == product_id)
    )).all()
    return await _product_out(product, list(variants))


@router.get("/{product_id}/images")
async def list_product_images(product_id: int, db: AsyncSession = Depends(get_db)):
    """Mahsulotning barcha rasmlari."""
    rows = (await db.scalars(
        select(ProductImage).where(ProductImage.product_id == product_id).order_by(ProductImage.sort_order)
    )).all()
    return [
        {"id": img.id, "image_url": img.image_url, "thumb_url": img.thumb_url, "sort_order": img.sort_order}
        for img in rows
    ]


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

    if _validate_image_magic(contents) is None:
        raise HTTPException(status_code=400, detail="Fayl haqiqiy rasm emas")

    try:
        main_bytes, thumb_bytes = process_product_image(contents)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    token = secrets.token_hex(8)
    filename = f"{product_id}_{token}.jpg"
    thumb_filename = f"{product_id}_{token}_thumb.jpg"
    (PRODUCTS_DIR / filename).write_bytes(main_bytes)
    (PRODUCTS_DIR / thumb_filename).write_bytes(thumb_bytes)

    img = ProductImage(
        product_id=product_id,
        image_url=public_url(f"products/{filename}"),
        thumb_url=public_url(f"products/{thumb_filename}"),
    )
    db.add(img)
    await db.commit()
    await db.refresh(img)
    return {"id": img.id, "image_url": img.image_url, "thumb_url": img.thumb_url}


def _delete_local_file(url: str | None) -> None:
    if url and url.startswith("/static/"):
        delete_file(url[len("/static/"):])


@router.delete("/{product_id}/images/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product_image(
    product_id: int,
    image_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Galereyadagi bitta rasmni o'chiradi (asosiy rasm bunga kirmaydi —
    u alohida yangi rasm yuklab almashtiriladi)."""
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    img = await db.get(ProductImage, image_id)
    if not img or img.product_id != product_id:
        raise HTTPException(status_code=404, detail="Rasm topilmadi")
    _delete_local_file(img.image_url)
    _delete_local_file(img.thumb_url)
    await db.delete(img)
    await db.commit()


@router.patch("/{product_id}/images/reorder")
async def reorder_product_images(
    product_id: int,
    payload: ProductImageReorderRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)

    ids = [item.id for item in payload.items]
    rows = {
        img.id: img
        for img in await db.scalars(
            select(ProductImage).where(ProductImage.id.in_(ids), ProductImage.product_id == product_id)
        )
    }
    missing = set(ids) - set(rows)
    if missing:
        raise HTTPException(status_code=404, detail=f"Rasm topilmadi: {sorted(missing)}")
    for item in payload.items:
        rows[item.id].sort_order = item.sort_order
    await db.commit()
    return await list_product_images(product_id, db)


@router.post("/{product_id}/images/{image_id}/set-main", response_model=ProductOut)
async def set_main_product_image(
    product_id: int,
    image_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Galereyadagi bitta rasmni mahsulotning asosiy (kartochka) rasmi qiladi."""
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    await _ensure_shop_owner(db, product.shop_id, current_user)
    img = await db.get(ProductImage, image_id)
    if not img or img.product_id != product_id:
        raise HTTPException(status_code=404, detail="Rasm topilmadi")

    stage_protected_update(product, {"image_url": img.image_url, "thumb_url": img.thumb_url})
    await db.commit()
    await db.refresh(product)
    variants = (await db.scalars(
        select(ProductVariant).where(ProductVariant.product_id == product_id)
    )).all()
    return await _product_out(product, list(variants))
