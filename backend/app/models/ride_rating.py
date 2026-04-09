"""Haydovchiga baho — sayohat tugagandan keyin."""
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class RideRating(Base):
    __tablename__ = "ride_ratings"

    id: Mapped[int] = mapped_column(primary_key=True)
    ride_id: Mapped[int] = mapped_column(
        ForeignKey("rides.id", ondelete="CASCADE"), unique=True, index=True
    )
    passenger_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    driver_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    rating: Mapped[int] = mapped_column(Integer, nullable=False)  # 1-5
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
