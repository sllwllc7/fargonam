"""Mahsulot/to'plam moderatsiyasi — himoyalangan maydon o'zgarishini
stagelash (`pending_edit`) va admin tasdiqlash/rad etish.

Narx/zaxira (`ProductVariant.price`/`stock`) bu yerga kirmaydi — ular DOIM
darhol o'zgaradi, chaqiruvchi kod alohida to'g'ridan-to'g'ri yangilaydi.

Boshqa (himoyalangan: nom/rasm/tavsif/kategoriya/parametr) maydonlar —
mahsulot hozir 'approved' bo'lsa LIVE qatorga yozilmaydi, `pending_edit`
JSON'ga stagelanadi, `status` 'pending'ga tushadi — User App eski
(tasdiqlangan) qiymatlarni ko'rsatishda davom etadi. Admin tasdiqlasa
`approve()` shu diffni qatorga qo'llaydi."""
from datetime import datetime, timezone

from app.models.product import ProductStatus


def stage_protected_update(obj, changed_fields: dict) -> None:
    """`obj` — `Product` yoki `ProductSet`. `changed_fields` — faqat
    himoyalangan (moderatsiya talab qiladigan) maydonlar."""
    if not changed_fields:
        return
    if obj.status == ProductStatus.approved:
        obj.pending_edit = {**(obj.pending_edit or {}), **changed_fields}
        obj.status = ProductStatus.pending
        obj.submitted_at = datetime.now(timezone.utc)
    elif obj.pending_edit is not None:
        # Avval approved bo'lgan, hali qayta tasdiqlanmagan — diff yangilanadi
        obj.pending_edit = {**obj.pending_edit, **changed_fields}
        if obj.status == ProductStatus.rejected:
            obj.status = ProductStatus.pending
            obj.rejected_reason = None
            obj.submitted_at = datetime.now(timezone.utc)
    else:
        # Hech qachon approved bo'lmagan (yangi/pending/rejected) — himoya
        # qiladigan "eski versiya" yo'q, to'g'ridan-to'g'ri qatorga yoziladi
        for field, value in changed_fields.items():
            setattr(obj, field, value)
        if obj.status == ProductStatus.rejected:
            obj.status = ProductStatus.pending
            obj.rejected_reason = None
            obj.submitted_at = datetime.now(timezone.utc)


def approve(obj, admin_id: int) -> None:
    """Admin tasdiqlaydi — stagelangan o'zgarish (bo'lsa) qatorga qo'llanadi."""
    if obj.pending_edit:
        for field, value in obj.pending_edit.items():
            setattr(obj, field, value)
        obj.pending_edit = None
    obj.status = ProductStatus.approved
    obj.rejected_reason = None
    obj.moderated_at = datetime.now(timezone.utc)
    obj.moderated_by = admin_id


def reject(obj, admin_id: int, reason: str) -> None:
    """Admin rad etadi — `pending_edit` (bo'lsa) saqlanib qoladi, seller
    "Tahrirlash"da o'zi yuborgan variantini qayta ko'radi."""
    obj.status = ProductStatus.rejected
    obj.rejected_reason = reason
    obj.moderated_at = datetime.now(timezone.utc)
    obj.moderated_by = admin_id


def admin_direct_edit(obj, changed_fields: dict) -> None:
    """Admin "tuzatib tasdiqlash" — o'zi to'g'ridan-to'g'ri tahrirlaydi,
    staging kerak emas (bu tahrir moderatsiyaning o'zi). `approve()` bilan
    birga chaqiriladi."""
    for field, value in changed_fields.items():
        setattr(obj, field, value)
    obj.pending_edit = None
