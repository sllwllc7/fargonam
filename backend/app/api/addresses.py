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
    lat: float | None = None
    lng: float | None = None


@router.get("")
async def list_addresses(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(select(SavedAddress).where(SavedAddress.user_id == current_user.id))).all()
    return [{"id": a.id, "label": a.label, "address": a.address, "lat": a.lat, "lng": a.lng} for a in rows]


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_address(payload: AddressCreate, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    addr = SavedAddress(user_id=current_user.id, label=payload.label, address=payload.address, lat=payload.lat, lng=payload.lng)
    db.add(addr)
    await db.commit()
    await db.refresh(addr)
    return {"id": addr.id, "label": addr.label, "address": addr.address}


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(address_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    addr = await db.get(SavedAddress, address_id)
    if not addr or addr.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Manzil topilmadi")
    await db.delete(addr)
    await db.commit()
