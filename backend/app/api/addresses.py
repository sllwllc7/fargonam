"""Saqlangan manzillar CRUD."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.saved_address import SavedAddress
from app.models.user import User

router = APIRouter(prefix="/addresses", tags=["addresses"])


class AddressCreate(BaseModel):
    label: str = Field(max_length=50)
    address: str = Field(max_length=300)
    region: str | None = Field(default=None, max_length=100)
    district: str | None = Field(default=None, max_length=100)
    landmark: str | None = Field(default=None, max_length=300)
    lat: float | None = None
    lng: float | None = None
    is_default: bool = False


class AddressUpdate(BaseModel):
    label: str | None = Field(default=None, max_length=50)
    address: str | None = Field(default=None, max_length=300)
    region: str | None = Field(default=None, max_length=100)
    district: str | None = Field(default=None, max_length=100)
    landmark: str | None = Field(default=None, max_length=300)
    lat: float | None = None
    lng: float | None = None
    is_default: bool | None = None


def _out(a: SavedAddress) -> dict:
    return {
        "id": a.id,
        "label": a.label,
        "address": a.address,
        "region": a.region,
        "district": a.district,
        "landmark": a.landmark,
        "lat": a.lat,
        "lng": a.lng,
        "is_default": a.is_default,
    }


async def _clear_other_defaults(db: AsyncSession, user_id: int, except_id: int | None = None) -> None:
    rows = (await db.scalars(
        select(SavedAddress).where(SavedAddress.user_id == user_id, SavedAddress.is_default.is_(True))
    )).all()
    for row in rows:
        if row.id != except_id:
            row.is_default = False


@router.get("")
async def list_addresses(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(
        select(SavedAddress).where(SavedAddress.user_id == current_user.id).order_by(SavedAddress.id.desc())
    )).all()
    return [_out(a) for a in rows]


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_address(payload: AddressCreate, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    addr = SavedAddress(
        user_id=current_user.id,
        label=payload.label,
        address=payload.address,
        region=payload.region,
        district=payload.district,
        landmark=payload.landmark,
        lat=payload.lat,
        lng=payload.lng,
        is_default=payload.is_default,
    )
    db.add(addr)
    await db.flush()
    if payload.is_default:
        await _clear_other_defaults(db, current_user.id, except_id=addr.id)
    await db.commit()
    await db.refresh(addr)
    return _out(addr)


@router.patch("/{address_id}")
async def update_address(
    address_id: int,
    payload: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    addr = await db.get(SavedAddress, address_id)
    if not addr or addr.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Manzil topilmadi")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(addr, field, value)
    if payload.is_default:
        await _clear_other_defaults(db, current_user.id, except_id=addr.id)
    await db.commit()
    await db.refresh(addr)
    return _out(addr)


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(address_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    addr = await db.get(SavedAddress, address_id)
    if not addr or addr.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Manzil topilmadi")
    await db.delete(addr)
    await db.commit()
