"""/dokon — katalog boshqaruvi (kategoriya/mahsulot). dokon.py (buyurtmalar)
dan alohida fayl — bir xil auth (`get_dokon_session`/`require_dokon_name`)
ishlatadi, lekin ular o'zgartirilmaydi, shu yerdan import qilinadi.

Muhim arxitektura qarori: bu yerdagi endpointlar mavjud `/products` va
`/categories` endpointlarini (backend/app/api/products.py,categories.py)
ICHKI FUNKSIYA CHAQIRUVI sifatida qayta ishlatadi — HTTP orqali emas, to'g'ridan
-to'g'ri Python funksiya sifatida (`current_user` parametriga MVP1'dagi yagona
do'kon egasini — admin foydalanuvchini — uzatib). Bu degani:
  - Rasm yuklash/siqish, variant CRUD, SKU validatsiyasi, savat/sevimlilar
    bilan bog'liq o'chirish himoyasi — bari BIR JOYDA qoladi, ikki marta
    yozilmaydi.
  - `products.py`/`categories.py` fayllariga BIRON O'ZGARISH kiritilmagan —
    faqat import qilib chaqirilmoqda (CLAUDE.md: "mavjud endpointlar’ga
    tegilmasin").

Moderatsiya: uydagilar yuklagan/o'zgartirgan mahsulot DARHOL live bo'lishi
kerak (pending navbatga tushmasin). Buni Shop.is_trusted orqali emas, alohida
`AppConfig["dokon_catalog_moderation"]` orqali boshqaramiz — standart holat
"false" (moderatsiya o'chiq — darhol tasdiqlanadi). "true" qilinsa, odatdagi
pending/approve oqimi qaytadi. Yoqish/o'chirish — PROGRESS.md'da yozilgan.

"Kim qo'shdi/o'zgartirdi" va "bir vaqtda ikki kishi tahrirlasa ogohlantirish"
— DB'ga yangi ustun qo'shmasdan, xuddi order-claim mexanizmi kabi Redis'da
saqlanadi (`dokon:meta:{kind}:{id}` hash: rev/created_by/created_at/
updated_by/updated_at). Redis flush bo'lsa faqat shu label yo'qoladi — asosiy
ma'lumot (Product/Category qatorlari) tegilmaydi, shuning uchun xavfsiz
kelishuv.
"""
from datetime import datetime, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import categories as categories_api
from app.api import products as products_api
from app.api.dokon import require_dokon_name
from app.core.config import settings
from app.core.moderation import approve
from app.core.redis_client import get_redis
from app.core.telegram_bot import send_message
from app.db.session import get_db
from app.models.app_config import AppConfig
from app.models.category import Category
from app.models.product import Product, ProductStatus
from app.models.product_image import ProductImage
from app.models.product_variant import ProductVariant
from app.models.shop import Shop
from app.models.user import User
from app.schemas.marketplace import (
    CategoryCreate,
    CategoryReorderRequest,
    CategoryUpdate,
    ProductCreate,
    ProductImageReorderRequest,
    ProductUpdate,
    VariantCreate,
    VariantUpdate,
)

router = APIRouter(prefix="/dokon-api", tags=["dokon-catalog"])

MODERATION_CONFIG_KEY = "dokon_catalog_moderation"


# ========== yordamchi: yagona do'kon/egasi, moderatsiya sozlamasi ==========

async def _get_shop_and_owner(db: AsyncSession) -> tuple[Shop, User]:
    """MVP1 — bitta faol do'kon bor (CLAUDE.md §1). Bir nechtasi topilsa eng
    birinchisi (id bo'yicha) ishlatiladi — hozircha bunday holat kutilmaydi."""
    shop = (await db.scalars(
        select(Shop).where(Shop.is_active.is_(True)).order_by(Shop.id)
    )).first()
    if not shop:
        raise HTTPException(status_code=503, detail="Do'kon topilmagan. Avval /admin-web orqali do'kon yarating.")
    owner = await db.get(User, shop.owner_id)
    if not owner:
        raise HTTPException(status_code=503, detail="Do'kon egasi topilmadi")
    return shop, owner


async def _moderation_enabled(db: AsyncSession) -> bool:
    row = await db.get(AppConfig, MODERATION_CONFIG_KEY)
    return bool(row and row.value == "true")


async def _auto_approve_if_needed(db: AsyncSession, product_id: int, admin_id: int) -> None:
    """Moderatsiya o'chiq bo'lsa — mahsulotni (staged o'zgarish bo'lsa ham)
    darhol tasdiqlaydi. `approve()` — moderation.py'dagi umumiy funksiya,
    o'zgartirilmagan."""
    if await _moderation_enabled(db):
        return
    product = await db.get(Product, product_id)
    if product and (product.status != ProductStatus.approved or product.pending_edit):
        approve(product, admin_id)
        await db.commit()


async def _notify_admin(text: str) -> None:
    for raw_id in settings.admin_telegram_ids:
        try:
            chat_id = int(raw_id)
        except ValueError:
            continue
        await send_message(chat_id, text, bot_token=(settings.TELEGRAM_MINIAPP_BOT_TOKEN or None))


def _combo_label(attrs: dict) -> str:
    if not attrs:
        return "Standart"
    return " / ".join(str(v) for v in attrs.values())


# ========== yordamchi: "kim/qachon" va tahrir to'qnashuvi (Redis) ==========

_META_PREFIX = "dokon:meta:"


def _meta_key(kind: str, obj_id: int) -> str:
    return f"{_META_PREFIX}{kind}:{obj_id}"


async def _meta_get(redis, kind: str, obj_id: int) -> dict:
    raw = await redis.hgetall(_meta_key(kind, obj_id))
    return {
        "rev": int(raw.get("rev", 0)) if raw else 0,
        "created_by": raw.get("created_by") if raw else None,
        "created_at": raw.get("created_at") if raw else None,
        "updated_by": raw.get("updated_by") if raw else None,
        "updated_at": raw.get("updated_at") if raw else None,
    }


async def _meta_touch(redis, kind: str, obj_id: int, actor: str, created: bool = False) -> dict:
    """Rev'ni +1 qiladi, updated_by/at'ni yangilaydi. `created=True` bo'lsa
    (yoki hali created_at bo'lmasa) created_by/at ham yoziladi. Eski
    (yangilanishdan oldingi) qiymatni qaytaradi — chaqiruvchi shu bilan
    to'qnashuv borligini aniqlaydi."""
    now = datetime.now(timezone.utc).isoformat()
    prev = await _meta_get(redis, kind, obj_id)
    new_rev = prev["rev"] + 1
    mapping = {"rev": new_rev, "updated_by": actor, "updated_at": now}
    if created or not prev["created_at"]:
        mapping["created_by"] = actor
        mapping["created_at"] = now
    await redis.hset(_meta_key(kind, obj_id), mapping=mapping)
    return {"rev": new_rev, "prev_rev": prev["rev"], "prev_updated_by": prev["updated_by"]}


async def _meta_delete(redis, kind: str, obj_id: int) -> None:
    await redis.delete(_meta_key(kind, obj_id))


def _conflict_info(known_rev: int | None, touch: dict) -> dict | None:
    """`known_rev` chaqiruvchi yuklagan paytdagi rev. Agar boshqa xodim
    orada saqlagan bo'lsa (prev_rev known_rev'dan katta) — ogohlantirish."""
    if known_rev is None:
        return None
    if touch["prev_rev"] > known_rev and touch["prev_updated_by"]:
        return {"conflict": True, "conflict_by": touch["prev_updated_by"]}
    return None


# ========== KATEGORIYALAR ==========
# O'qish — mavjud ochiq `GET /categories` orqali (auth talab qilmaydi, dokon
# frontend to'g'ridan-to'g'ri shuni chaqiradi). Bu yerda faqat yozish.

class DokonCategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    slug: str = Field(min_length=1, max_length=140)


class DokonCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    slug: str | None = Field(default=None, min_length=1, max_length=140)
    known_rev: int | None = None


@router.post("/categories", status_code=status.HTTP_201_CREATED)
async def dokon_create_category(
    payload: DokonCategoryCreate,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    cat = await categories_api.create_category(
        payload=CategoryCreate(name=payload.name, slug=payload.slug),
        current_user=owner,
        db=db,
    )
    redis = get_redis()
    await _meta_touch(redis, "category", cat.id, name, created=True)
    return await _category_out(db, redis, cat.id)


@router.patch("/categories/{category_id}")
async def dokon_update_category(
    category_id: int,
    payload: DokonCategoryUpdate,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    fields = payload.model_dump(exclude={"known_rev"}, exclude_unset=True)
    await categories_api.update_category(
        category_id=category_id,
        payload=CategoryUpdate(**fields),
        current_user=owner,
        db=db,
    )
    redis = get_redis()
    touch = await _meta_touch(redis, "category", category_id, name)
    out = await _category_out(db, redis, category_id)
    out["conflict"] = _conflict_info(payload.known_rev, touch)
    return out


@router.post("/categories/{category_id}/image")
async def dokon_upload_category_image(
    category_id: int,
    file: UploadFile = File(...),
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await categories_api.upload_category_image(category_id=category_id, file=file, current_user=owner, db=db)
    redis = get_redis()
    await _meta_touch(redis, "category", category_id, name)
    return await _category_out(db, redis, category_id)


@router.delete("/categories/{category_id}/image")
async def dokon_delete_category_image(
    category_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await categories_api.delete_category_image(category_id=category_id, current_user=owner, db=db)
    redis = get_redis()
    await _meta_touch(redis, "category", category_id, name)
    return await _category_out(db, redis, category_id)


@router.patch("/categories/reorder")
async def dokon_reorder_categories(
    payload: CategoryReorderRequest,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    return await categories_api.reorder_categories(payload=payload, current_user=owner, db=db)


@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def dokon_delete_category(
    category_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    # `categories.py`dagi delete_category o'zi bloklamaydi — Product.category_id
    # ustuni ON DELETE SET NULL, shuning uchun jim ravishda mahsulotlarni
    # "kategoriyasiz" qilib qo'yardi. Shu yerda alohida tekshiramiz (5-bo'lim:
    # "Ichida mahsulot bo'lsa o'chirishga ruxsat berma").
    product_count = await db.scalar(
        select(func.count()).select_from(Product).where(Product.category_id == category_id)
    )
    if product_count:
        raise HTTPException(
            status_code=400,
            detail=f"Bu kategoriyada {product_count} ta mahsulot bor. Avval ularni boshqa kategoriyaga o'tkazing yoki o'chiring.",
        )
    await categories_api.delete_category(category_id=category_id, current_user=owner, db=db)
    await _meta_delete(get_redis(), "category", category_id)


async def _category_out(db: AsyncSession, redis, category_id: int) -> dict:
    cat = await db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    product_count = await db.scalar(
        select(func.count()).select_from(Product).where(Product.category_id == category_id)
    )
    meta = await _meta_get(redis, "category", category_id)
    return {
        "id": cat.id, "name": cat.name, "slug": cat.slug, "icon": cat.icon,
        "color": cat.color, "sort_order": cat.sort_order,
        "image_url": cat.image_url, "thumb_url": cat.thumb_url,
        "product_count": product_count or 0,
        **meta,
    }


# ========== MAHSULOTLAR ==========

class DokonVariantIn(BaseModel):
    attributes: dict = Field(default_factory=dict)
    price: int = Field(gt=0)
    stock: int = Field(ge=0, default=0)


class DokonProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    brand: str | None = Field(default=None, max_length=100)
    description: str | None = None
    category_id: int | None = None
    variants: list[DokonVariantIn] = Field(min_length=1, max_length=200)


class DokonProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    brand: str | None = Field(default=None, max_length=100)
    description: str | None = None
    category_id: int | None = None
    is_active: bool | None = None
    known_rev: int | None = None


class DokonVariantQuickUpdate(BaseModel):
    price: int | None = Field(default=None, gt=0)
    stock: int | None = Field(default=None, ge=0)
    is_active: bool | None = None
    known_rev: int | None = None


async def _dokon_product_out(db: AsyncSession, redis, product_id: int) -> dict:
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
    variants = (await db.scalars(
        select(ProductVariant).where(ProductVariant.product_id == product_id)
        .order_by(ProductVariant.sort_order, ProductVariant.id)
    )).all()
    images = (await db.scalars(
        select(ProductImage).where(ProductImage.product_id == product_id)
        .order_by(ProductImage.sort_order)
    )).all()
    category = await db.get(Category, product.category_id) if product.category_id else None
    meta = await _meta_get(redis, "product", product_id)
    return {
        "id": product.id,
        "name": product.name,
        "brand": product.brand,
        "description": product.description,
        "category_id": product.category_id,
        "category_name": category.name if category else None,
        "image_url": product.image_url,
        "thumb_url": product.thumb_url,
        "is_active": product.is_active,
        "status": product.status.value,
        "rejected_reason": product.rejected_reason,
        "has_pending_edit": bool(product.pending_edit),
        "created_at": product.created_at.isoformat(),
        "variants": [
            {
                "id": v.id, "variant_name": v.variant_name, "price": v.price,
                "stock": v.stock, "attributes": v.attributes, "is_active": v.is_active,
                "sort_order": v.sort_order,
            }
            for v in variants
        ],
        "images": [
            {"id": im.id, "image_url": im.image_url, "thumb_url": im.thumb_url, "sort_order": im.sort_order}
            for im in images
        ],
        "min_price": min((v.price for v in variants if v.is_active), default=None),
        "max_price": max((v.price for v in variants if v.is_active), default=None),
        "total_stock": sum(v.stock for v in variants if v.is_active),
        **meta,
    }


@router.get("/products")
async def dokon_list_products(
    q: str | None = Query(default=None, max_length=100),
    category_id: int | None = Query(default=None),
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    base = select(Product).where(Product.shop_id == shop.id)
    if q:
        safe_q = q.replace("%", r"\%").replace("_", r"\_")
        base = base.where(Product.name.ilike(f"%{safe_q}%"))
    if category_id is not None:
        base = base.where(Product.category_id == category_id)
    products = (await db.scalars(base.order_by(Product.id.desc()).limit(500))).all()

    redis = get_redis()
    variants_map = await products_api._load_variants_map(db, [p.id for p in products])
    category_ids = {p.category_id for p in products if p.category_id}
    category_map: dict[int, Category] = {}
    if category_ids:
        cats = (await db.scalars(select(Category).where(Category.id.in_(category_ids)))).all()
        category_map = {c.id: c for c in cats}

    result = []
    for p in products:
        variants = variants_map.get(p.id, [])
        active_variants = [v for v in variants if v.is_active]
        meta = await _meta_get(redis, "product", p.id)
        result.append({
            "id": p.id, "name": p.name, "brand": p.brand,
            "category_id": p.category_id,
            "category_name": category_map[p.category_id].name if p.category_id in category_map else None,
            "image_url": p.image_url, "thumb_url": p.thumb_url,
            "is_active": p.is_active, "status": p.status.value,
            "has_pending_edit": bool(p.pending_edit),
            "variant_count": len(variants),
            "single_variant_id": variants[0].id if len(variants) == 1 else None,
            "min_price": min((v.price for v in active_variants), default=None),
            "max_price": max((v.price for v in active_variants), default=None),
            "total_stock": sum(v.stock for v in active_variants),
            **meta,
        })
    return result


@router.get("/products/{product_id}")
async def dokon_get_product(
    product_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    return await _dokon_product_out(db, get_redis(), product_id)


@router.post("/products", status_code=status.HTTP_201_CREATED)
async def dokon_create_product(
    payload: DokonProductCreate,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    first, rest = payload.variants[0], payload.variants[1:]

    product_out = await products_api.create_product(
        payload=ProductCreate(
            shop_id=shop.id, category_id=payload.category_id, name=payload.name,
            brand=payload.brand, description=payload.description,
            price=Decimal(first.price), stock=first.stock,
        ),
        current_user=owner, db=db,
    )
    default_variant_id = product_out.variants[0].id
    await products_api.update_variant(
        product_id=product_out.id, variant_id=default_variant_id,
        payload=VariantUpdate(variant_name=_combo_label(first.attributes), attributes=first.attributes),
        current_user=owner, db=db,
    )
    for v in rest:
        await products_api.create_variant(
            product_id=product_out.id,
            payload=VariantCreate(
                variant_name=_combo_label(v.attributes), price=v.price, stock=v.stock,
                attributes=v.attributes,
            ),
            current_user=owner, db=db,
        )

    await _auto_approve_if_needed(db, product_out.id, owner.id)
    redis = get_redis()
    await _meta_touch(redis, "product", product_out.id, name, created=True)
    await _notify_admin(f"🆕 {name} yangi mahsulot qo'shdi: {payload.name}\n{settings.MINIAPP_URL}")
    return await _dokon_product_out(db, redis, product_out.id)


@router.patch("/products/{product_id}")
async def dokon_update_product(
    product_id: int,
    payload: DokonProductUpdate,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    fields = payload.model_dump(exclude={"known_rev"}, exclude_unset=True)
    name_changed = "name" in fields
    if fields:
        await products_api.update_product(
            product_id=product_id, payload=ProductUpdate(**fields), current_user=owner, db=db,
        )
    await _auto_approve_if_needed(db, product_id, owner.id)

    redis = get_redis()
    touch = await _meta_touch(redis, "product", product_id, name)
    if name_changed:
        product = await db.get(Product, product_id)
        await _notify_admin(f"✏️ {name} mahsulot nomini o'zgartirdi: {product.name}\n{settings.MINIAPP_URL}")

    out = await _dokon_product_out(db, redis, product_id)
    out["conflict"] = _conflict_info(payload.known_rev, touch)
    return out


@router.delete("/products/{product_id}")
async def dokon_delete_product(
    product_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    result = await products_api.delete_product(product_id=product_id, current_user=owner, db=db)
    await _meta_delete(get_redis(), "product", product_id)
    return result


# ── variantlar (narx/zaxira tez tahrirlash + to'liq SKU muharriri) ──

@router.patch("/products/{product_id}/variants/{variant_id}")
async def dokon_update_variant(
    product_id: int,
    variant_id: int,
    payload: DokonVariantQuickUpdate,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    old_variant = await db.get(ProductVariant, variant_id)
    old_price = old_variant.price if old_variant else None

    fields = payload.model_dump(exclude={"known_rev"}, exclude_unset=True)
    if fields:
        await products_api.update_variant(
            product_id=product_id, variant_id=variant_id,
            payload=VariantUpdate(**fields), current_user=owner, db=db,
        )

    redis = get_redis()
    touch = await _meta_touch(redis, "product", product_id, name)

    if payload.price is not None and old_price is not None and payload.price != old_price:
        product = await db.get(Product, product_id)
        await _notify_admin(
            f"💰 {name} narx o'zgartirdi: {product.name} — {old_price:,} → {payload.price:,} so'm".replace(",", " ")
            + f"\n{settings.MINIAPP_URL}"
        )

    out = await _dokon_product_out(db, redis, product_id)
    out["conflict"] = _conflict_info(payload.known_rev, touch)
    return out


@router.post("/products/{product_id}/variants", status_code=status.HTTP_201_CREATED)
async def dokon_add_variant(
    product_id: int,
    payload: DokonVariantIn,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.create_variant(
        product_id=product_id,
        payload=VariantCreate(
            variant_name=_combo_label(payload.attributes), price=payload.price,
            stock=payload.stock, attributes=payload.attributes,
        ),
        current_user=owner, db=db,
    )
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


@router.delete("/products/{product_id}/variants/{variant_id}")
async def dokon_delete_variant(
    product_id: int,
    variant_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.delete_variant(product_id=product_id, variant_id=variant_id, current_user=owner, db=db)
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


# ── rasmlar ──

@router.post("/products/{product_id}/main-image")
async def dokon_upload_main_image(
    product_id: int,
    file: UploadFile = File(...),
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.upload_product_image(product_id=product_id, file=file, current_user=owner, db=db)
    await _auto_approve_if_needed(db, product_id, owner.id)
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


@router.post("/products/{product_id}/images", status_code=status.HTTP_201_CREATED)
async def dokon_add_gallery_image(
    product_id: int,
    file: UploadFile = File(...),
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.add_product_image(product_id=product_id, file=file, current_user=owner, db=db)
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


@router.delete("/products/{product_id}/images/{image_id}")
async def dokon_delete_image(
    product_id: int,
    image_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.delete_product_image(product_id=product_id, image_id=image_id, current_user=owner, db=db)
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


@router.patch("/products/{product_id}/images/reorder")
async def dokon_reorder_images(
    product_id: int,
    payload: dict,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.reorder_product_images(
        product_id=product_id, payload=ProductImageReorderRequest(**payload), current_user=owner, db=db,
    )
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


@router.post("/products/{product_id}/images/{image_id}/set-main")
async def dokon_set_main_image(
    product_id: int,
    image_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    shop, owner = await _get_shop_and_owner(db)
    await products_api.set_main_product_image(product_id=product_id, image_id=image_id, current_user=owner, db=db)
    await _auto_approve_if_needed(db, product_id, owner.id)
    redis = get_redis()
    await _meta_touch(redis, "product", product_id, name)
    return await _dokon_product_out(db, redis, product_id)


# ========== SOZLAMA (moderatsiya) — faqat o'qish, /dokon UI'da ko'rsatish uchun ==========

@router.get("/config")
async def dokon_get_config(
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    return {"moderation_enabled": await _moderation_enabled(db)}
