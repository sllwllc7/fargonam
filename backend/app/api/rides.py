"""Taksi endpointlar — yo'lovchi va haydovchi uchun."""
from datetime import datetime, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.ride import DriverProfile, Ride, RideStatus
from app.models.user import User
from app.schemas.ride import (
    DriverProfileCreate,
    DriverProfileOut,
    RideOut,
    RideRequest,
    RideStatusUpdate,
)

router = APIRouter(prefix="/rides", tags=["rides"])

# MVP: soddagina bazaviy narx
BASE_FARE = Decimal("15000")  # 15,000 so'm


async def _ride_to_out(ride: Ride, db: AsyncSession) -> RideOut:
    """Ride modelni RideOut'ga o'giradi, haydovchi ma'lumotlari bilan."""
    out = RideOut.model_validate(ride)
    if ride.driver_id:
        driver = await db.get(User, ride.driver_id)
        if driver:
            out.driver_name = driver.full_name
            out.driver_phone = driver.phone
        dp = await db.scalar(
            select(DriverProfile).where(DriverProfile.user_id == ride.driver_id)
        )
        if dp:
            out.car_model = dp.car_model
            out.car_number = dp.car_number
            out.car_color = dp.car_color
    return out


# ==================== YO'LOVCHI ====================

@router.post("", response_model=RideOut, status_code=status.HTTP_201_CREATED)
async def request_ride(
    payload: RideRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Yo'lovchi taksi chaqiradi."""
    # Faol ride borligini tekshirish
    active = await db.scalar(
        select(Ride).where(
            Ride.passenger_id == current_user.id,
            Ride.status.in_([RideStatus.searching, RideStatus.accepted, RideStatus.arrived, RideStatus.in_progress]),
        )
    )
    if active:
        raise HTTPException(status_code=400, detail="Sizda allaqachon faol sayohat bor")

    ride = Ride(
        passenger_id=current_user.id,
        pickup_address=payload.pickup_address,
        destination_address=payload.destination_address,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        dest_lat=payload.dest_lat,
        dest_lng=payload.dest_lng,
        fare=BASE_FARE,
    )
    db.add(ride)
    await db.commit()
    await db.refresh(ride)
    return await _ride_to_out(ride, db)


@router.get("/my", response_model=list[RideOut])
async def my_rides(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    active_only: bool = Query(default=False),
):
    """Yo'lovchining sayohatlari."""
    stmt = select(Ride).where(Ride.passenger_id == current_user.id)
    if active_only:
        stmt = stmt.where(Ride.status.in_([
            RideStatus.searching, RideStatus.accepted, RideStatus.arrived, RideStatus.in_progress,
        ]))
    stmt = stmt.order_by(Ride.id.desc())
    rides = (await db.scalars(stmt)).all()
    return [await _ride_to_out(r, db) for r in rides]


@router.post("/{ride_id}/cancel", response_model=RideOut)
async def cancel_ride(
    ride_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Yo'lovchi yoki haydovchi bekor qiladi."""
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Sayohat topilmadi")
    if ride.passenger_id != current_user.id and ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu sizning sayohatingiz emas")
    if ride.status in (RideStatus.completed, RideStatus.cancelled):
        raise HTTPException(status_code=400, detail="Bu sayohat allaqachon tugagan")
    ride.status = RideStatus.cancelled
    await db.commit()
    await db.refresh(ride)
    return await _ride_to_out(ride, db)


# ==================== HAYDOVCHI ====================

@router.post("/driver/profile", response_model=DriverProfileOut, status_code=status.HTTP_201_CREATED)
async def create_driver_profile(
    payload: DriverProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Haydovchi profilini yaratish (mashina ma'lumotlari)."""
    existing = await db.scalar(
        select(DriverProfile).where(DriverProfile.user_id == current_user.id)
    )
    if existing:
        existing.car_model = payload.car_model
        existing.car_number = payload.car_number
        existing.car_color = payload.car_color
        await db.commit()
        await db.refresh(existing)
        return existing
    dp = DriverProfile(
        user_id=current_user.id,
        car_model=payload.car_model,
        car_number=payload.car_number,
        car_color=payload.car_color,
    )
    db.add(dp)
    await db.commit()
    await db.refresh(dp)
    return dp


@router.post("/driver/online", response_model=DriverProfileOut)
async def toggle_online(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Haydovchi onlayn/oflayn holatini almashtiradi."""
    dp = await db.scalar(
        select(DriverProfile).where(DriverProfile.user_id == current_user.id)
    )
    if not dp:
        raise HTTPException(status_code=404, detail="Avval profil yarating")
    dp.is_online = not dp.is_online
    await db.commit()
    await db.refresh(dp)
    return dp


@router.get("/driver/available", response_model=list[RideOut])
async def available_rides(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Haydovchi uchun kutayotgan (searching) sayohatlar."""
    dp = await db.scalar(
        select(DriverProfile).where(DriverProfile.user_id == current_user.id)
    )
    if not dp or not dp.is_online:
        raise HTTPException(status_code=400, detail="Avval onlayn rejimga o'ting")
    rides = (await db.scalars(
        select(Ride).where(Ride.status == RideStatus.searching).order_by(Ride.id.desc())
    )).all()
    return [await _ride_to_out(r, db) for r in rides]


@router.post("/{ride_id}/accept", response_model=RideOut)
async def accept_ride(
    ride_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Haydovchi sayohatni qabul qiladi."""
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Sayohat topilmadi")
    if ride.status != RideStatus.searching:
        raise HTTPException(status_code=400, detail="Bu sayohat allaqachon olingan")
    # Haydovchining faol ride'i borligini tekshirish
    active = await db.scalar(
        select(Ride).where(
            Ride.driver_id == current_user.id,
            Ride.status.in_([RideStatus.accepted, RideStatus.arrived, RideStatus.in_progress]),
        )
    )
    if active:
        raise HTTPException(status_code=400, detail="Sizda allaqachon faol sayohat bor")
    ride.driver_id = current_user.id
    ride.status = RideStatus.accepted
    ride.accepted_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(ride)
    return await _ride_to_out(ride, db)


@router.post("/{ride_id}/status", response_model=RideOut)
async def update_ride_status(
    ride_id: int,
    payload: RideStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Haydovchi sayohat holatini yangilaydi (arrived, in_progress, completed)."""
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Sayohat topilmadi")
    if ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu sizning sayohatingiz emas")

    # Holat o'tishlarini tekshirish
    allowed = {
        RideStatus.accepted: [RideStatus.arrived, RideStatus.cancelled],
        RideStatus.arrived: [RideStatus.in_progress, RideStatus.cancelled],
        RideStatus.in_progress: [RideStatus.completed],
    }
    if payload.status not in allowed.get(ride.status, []):
        raise HTTPException(status_code=400, detail=f"{ride.status} → {payload.status} ruxsat etilmagan")

    ride.status = payload.status
    if payload.status == RideStatus.completed:
        ride.completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(ride)
    return await _ride_to_out(ride, db)


@router.get("/{ride_id}", response_model=RideOut)
async def get_ride(
    ride_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Bitta sayohat tafsilotlari."""
    ride = await db.get(Ride, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Sayohat topilmadi")
    if ride.passenger_id != current_user.id and ride.driver_id != current_user.id:
        raise HTTPException(status_code=403, detail="Ruxsat yo'q")
    return await _ride_to_out(ride, db)
