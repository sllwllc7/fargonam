"""Taksi modellari — DriverProfile va Ride."""
from datetime import datetime
from decimal import Decimal
from enum import Enum

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Numeric, String, Text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class DriverProfile(Base):
    """Haydovchi profili — User jadvaliga qo'shimcha ma'lumot."""
    __tablename__ = "driver_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True
    )
    car_model: Mapped[str] = mapped_column(String(100))  # masalan: "Cobalt"
    car_number: Mapped[str] = mapped_column(String(20))   # masalan: "01 A 123 BC"
    car_color: Mapped[str | None] = mapped_column(String(30), nullable=True)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    # Hozirgi joylashuv (keyinroq real-time uchun)
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class RideStatus(str, Enum):
    searching = "searching"    # haydovchi qidirilmoqda
    accepted = "accepted"      # haydovchi qabul qildi
    arrived = "arrived"        # haydovchi yetib keldi
    in_progress = "in_progress"  # sayohat boshlandi
    completed = "completed"    # tugadi
    cancelled = "cancelled"    # bekor qilindi


class Ride(Base):
    """Bitta taksi sayohati."""
    __tablename__ = "rides"

    id: Mapped[int] = mapped_column(primary_key=True)
    passenger_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    driver_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    status: Mapped[RideStatus] = mapped_column(
        SAEnum(RideStatus, name="ride_status"),
        default=RideStatus.searching,
        nullable=False,
        index=True,
    )
    # Manzillar (hozircha matn, keyinroq koordinatalar)
    pickup_address: Mapped[str] = mapped_column(String(300))
    destination_address: Mapped[str] = mapped_column(String(300))
    pickup_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    pickup_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    dest_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    dest_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    # Narx
    fare: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    # Vaqtlar
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
