"""AppConfig API — ilova sozlamalarini olish va yangilash."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.db.session import get_db
from app.models.app_config import AppConfig
from app.models.user import User

router = APIRouter(prefix="/app-config", tags=["app-config"])

# Standart kalit-qiymatlar — DB da yo'q bo'lsa shu qaytariladi
_DEFAULTS: dict[str, str] = {
    "maintenance_mode": "false",
    "maintenance_message": "Texnik ishlar olib borilmoqda. Tez orada qaytamiz.",
    "min_app_version_user": "1.0.0",
    "min_app_version_seller": "1.0.0",
    "delivery_price": "15000",
    "min_order_amount": "0",
    "support_phone": "+998901234567",
    "support_telegram": "@fargonam_support",
}


async def _get_all(db: AsyncSession) -> dict[str, str]:
    """DB + default qiymatlarni birlashtiradi."""
    rows = (await db.scalars(select(AppConfig))).all()
    result = dict(_DEFAULTS)
    for row in rows:
        result[row.key] = row.value
    return result


@router.get("")
async def get_config(db: AsyncSession = Depends(get_db)):
    """Barcha sozlamalar — ilovalar startup'da shu endpointni chaqiradi."""
    return await _get_all(db)


@router.get("/admin")
async def get_config_admin(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin uchun — tavsiflar bilan to'liq ro'yxat."""
    all_vals = await _get_all(db)
    rows = {r.key: r for r in (await db.scalars(select(AppConfig))).all()}
    return [
        {
            "key": k,
            "value": all_vals[k],
            "description": rows[k].description if k in rows else "",
            "updated_at": rows[k].updated_at.isoformat() if k in rows else None,
        }
        for k in all_vals
    ]


class ConfigUpdate(BaseModel):
    value: str
    description: str = ""


@router.put("/{key}")
async def set_config(
    key: str,
    body: ConfigUpdate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — bitta sozlamani yangilash."""
    row = await db.get(AppConfig, key)
    if row is None:
        row = AppConfig(key=key, value=body.value, description=body.description)
        db.add(row)
    else:
        row.value = body.value
        if body.description:
            row.description = body.description
    await db.commit()
    return {"key": key, "value": body.value}


@router.post("/bulk")
async def set_config_bulk(
    updates: dict[str, str],
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin — bir vaqtda ko'p sozlamani yangilash."""
    for key, value in updates.items():
        row = await db.get(AppConfig, key)
        if row is None:
            db.add(AppConfig(key=key, value=value))
        else:
            row.value = value
    await db.commit()
    return {"updated": len(updates)}
