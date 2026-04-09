"""Haydovchiga baho endpointlari."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.ride import Ride, RideStatus
from app.models.ride_rating import RideRating
from app.models.user import User

router = APIRouter(prefix="/ride-ratings", tags=["ride-ratings"])


class RatingCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str | None = None


@router.post("/{ride_id}", status_code=status.HTTP_201_CREATED)
async def rate_ride(
    ride_id: int,
    payload: RatingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Sayohat topilmadi")
    if ride.passenger_id != current_user.id:
        raise HTTPException(status_code=403, detail="Faqat yo'lovchi baho qo'yishi mumkin")
    if ride.status != RideStatus.completed:
        raise HTTPException(status_code=400, detail="Faqat tugagan sayohatga baho qo'yiladi")
    existing = await db.scalar(select(RideRating).where(RideRating.ride_id == ride_id))
    if existing:
        existing.rating = payload.rating
        existing.comment = payload.comment
        await db.commit()
        return {"status": "yangilandi"}
    rr = RideRating(
        ride_id=ride_id,
        passenger_id=current_user.id,
        driver_id=ride.driver_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(rr)
    await db.commit()
    return {"status": "qo'shildi"}


@router.get("/driver/{driver_id}")
async def driver_rating(driver_id: int, db: AsyncSession = Depends(get_db)):
    """Haydovchining o'rtacha reytingi."""
    avg = await db.scalar(select(func.avg(RideRating.rating)).where(RideRating.driver_id == driver_id))
    total = await db.scalar(select(func.count()).select_from(
        select(RideRating).where(RideRating.driver_id == driver_id).subquery()
    ))
    return {"avg_rating": round(float(avg), 1) if avg else None, "total_ratings": total or 0}
