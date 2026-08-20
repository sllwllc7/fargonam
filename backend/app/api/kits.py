"""Sinf to'plami (kit) endpointlari — GET hammaga ochiq, CRUD faqat do'kon egasi/admin.

`ProductSet`/`ProductSetItem` — har item haqiqiy `ProductVariant`ga bog'lanadi
(narx doim variant'dan jonli o'qiladi, alohida saqlanmaydi — eskirmaydi).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_current_user_optional
from app.api.products import _can_view_unapproved_shop, _ensure_shop_owner
from app.core.moderation import stage_protected_update
from app.db.session import get_db
from app.models.product import Product, ProductStatus
from app.models.product_set import ProductSet, ProductSetItem
from app.models.product_variant import ProductVariant
from app.models.user import User
from app.schemas.marketplace import KitCreate, KitItemOut, KitOut, KitUpdate

_KIT_PROTECTED_FIELDS = {"name", "grade_level", "description", "image_url"}

router = APIRouter(prefix="/kits", tags=["kits"])


async def _kit_out(kit: ProductSet, items: list[ProductSetItem], db: AsyncSession) -> KitOut:
    variant_ids = [it.variant_id for it in items]
    variants: dict[int, ProductVariant] = {}
    products: dict[int, Product] = {}
    if variant_ids:
        vs = (await db.scalars(select(ProductVariant).where(ProductVariant.id.in_(variant_ids)))).all()
        variants = {v.id: v for v in vs}
        product_ids = {v.product_id for v in vs}
        if product_ids:
            ps = (await db.scalars(select(Product).where(Product.id.in_(product_ids)))).all()
            products = {p.id: p for p in ps}

    items_out: list[KitItemOut] = []
    total = 0
    for it in items:
        v = variants.get(it.variant_id)
        p = products.get(v.product_id) if v else None
        price = v.price if v else None
        line_total = price * it.quantity if price is not None else None
        if line_total is not None:
            total += line_total
        items_out.append(KitItemOut(
            id=it.id,
            variant_id=it.variant_id,
            quantity=it.quantity,
            product_name=p.name if p else None,
            variant_name=v.variant_name if v else None,
            price=price,
            line_total=line_total,
        ))

    return KitOut(
        id=kit.id,
        shop_id=kit.shop_id,
        name=kit.name,
        grade_level=kit.grade_level,
        description=kit.description,
        image_url=kit.image_url,
        is_active=kit.is_active,
        created_at=kit.created_at,
        items=items_out,
        total=total,
        status=kit.status.value,
        rejected_reason=kit.rejected_reason,
        pending_edit=kit.pending_edit,
        submitted_at=kit.submitted_at,
    )


async def _load_items(db: AsyncSession, set_id: int) -> list[ProductSetItem]:
    return list((await db.scalars(
        select(ProductSetItem).where(ProductSetItem.set_id == set_id).order_by(ProductSetItem.id)
    )).all())


@router.get("", response_model=list[KitOut])
async def list_kits(
    grade_level: str | None = None,
    shop_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    """Faol va tasdiqlangan to'plamlar — User App "Sinflar" qatori uchun (auth kerak emas).
    Do'kon egasi/admin o'z (hali pending/rejected/nofaol) to'plamlarini ham ko'radi
    (admin panel "To'plamlar" ekrani — nofaollashtirilganini qayta faollashtira olishi kerak)."""
    can_see_all = shop_id is not None and await _can_view_unapproved_shop(db, shop_id, current_user)
    q = select(ProductSet)
    if not can_see_all:
        q = q.where(ProductSet.is_active.is_(True), ProductSet.status == ProductStatus.approved)
    if grade_level:
        q = q.where(ProductSet.grade_level == grade_level)
    if shop_id is not None:
        q = q.where(ProductSet.shop_id == shop_id)
    sets = (await db.scalars(q.order_by(ProductSet.grade_level, ProductSet.id))).all()
    return [await _kit_out(s, await _load_items(db, s.id), db) for s in sets]


@router.get("/{kit_id}", response_model=KitOut)
async def get_kit(
    kit_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    kit = await db.get(ProductSet, kit_id)
    if not kit or not kit.is_active:
        raise HTTPException(status_code=404, detail="To'plam topilmadi")
    if kit.status != ProductStatus.approved and (
        kit.shop_id is None or not await _can_view_unapproved_shop(db, kit.shop_id, current_user)
    ):
        raise HTTPException(status_code=404, detail="To'plam topilmadi")
    return await _kit_out(kit, await _load_items(db, kit.id), db)


async def _validate_variant_ids(db: AsyncSession, variant_ids: list[int]) -> None:
    found = (await db.scalars(
        select(ProductVariant.id).where(ProductVariant.id.in_(variant_ids))
    )).all()
    missing = set(variant_ids) - set(found)
    if missing:
        raise HTTPException(status_code=404, detail=f"Variant topilmadi: {sorted(missing)}")


@router.post("", response_model=KitOut, status_code=status.HTTP_201_CREATED)
async def create_kit(
    payload: KitCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _ensure_shop_owner(db, payload.shop_id, current_user)
    await _validate_variant_ids(db, [it.variant_id for it in payload.items])

    kit = ProductSet(
        shop_id=payload.shop_id,
        name=payload.name,
        grade_level=payload.grade_level,
        description=payload.description,
        image_url=payload.image_url,
        status=ProductStatus.pending,
    )
    db.add(kit)
    await db.flush()
    for it in payload.items:
        db.add(ProductSetItem(set_id=kit.id, variant_id=it.variant_id, quantity=it.quantity))
    await db.commit()
    await db.refresh(kit)
    return await _kit_out(kit, await _load_items(db, kit.id), db)


@router.put("/{kit_id}", response_model=KitOut)
async def update_kit(
    kit_id: int,
    payload: KitUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    kit = await db.get(ProductSet, kit_id)
    if not kit:
        raise HTTPException(status_code=404, detail="To'plam topilmadi")
    if kit.shop_id is not None:
        await _ensure_shop_owner(db, kit.shop_id, current_user)
    elif current_user.role.value != "admin":
        raise HTTPException(status_code=403, detail="Faqat admin")

    data = payload.model_dump(exclude_unset=True, exclude={"items"})
    # is_active — ko'rinish tugmasi, darhol qo'llanadi (moderatsiya emas)
    is_active = data.pop("is_active", None)
    if is_active is not None:
        kit.is_active = is_active
    # Nom/sinf/tavsif/rasm — himoyalangan (Product bilan bir xil qoida).
    # Items (tarkib) — mavjud tasdiqlangan variantlarga bog'lanadi, darhol
    # qo'llanadi (moderatsiya risk past, sotuvchiga tez moslashuv kerak).
    stage_protected_update(kit, {k: v for k, v in data.items() if k in _KIT_PROTECTED_FIELDS})

    if payload.items is not None:
        await _validate_variant_ids(db, [it.variant_id for it in payload.items])
        existing = await _load_items(db, kit.id)
        for it in existing:
            await db.delete(it)
        await db.flush()
        for it in payload.items:
            db.add(ProductSetItem(set_id=kit.id, variant_id=it.variant_id, quantity=it.quantity))

    await db.commit()
    await db.refresh(kit)
    return await _kit_out(kit, await _load_items(db, kit.id), db)


@router.delete("/{kit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_kit(
    kit_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    kit = await db.get(ProductSet, kit_id)
    if not kit:
        raise HTTPException(status_code=404, detail="To'plam topilmadi")
    if kit.shop_id is not None:
        await _ensure_shop_owner(db, kit.shop_id, current_user)
    elif current_user.role.value != "admin":
        raise HTTPException(status_code=403, detail="Faqat admin")
    await db.delete(kit)
    await db.commit()
