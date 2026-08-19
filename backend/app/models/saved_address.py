"""Saqlangan manzillar — Uy, Ish, va boshqalar."""
from sqlalchemy import Boolean, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class SavedAddress(Base):
    __tablename__ = "saved_addresses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[str] = mapped_column(String(50))  # "Uy", "Ish", "Boshqa"
    region: Mapped[str | None] = mapped_column(String(100), nullable=True)  # viloyat
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)  # tuman
    # Ko'cha/mahalla/uy — erkin matn (qidiruv+xarita orqali kiritiladi)
    address: Mapped[str] = mapped_column(String(300))
    # Mo'ljal/kuryer uchun izoh — MDH bozorida amalda majburiy (rasmiy manzil
    # ko'pincha to'liq emas)
    landmark: Mapped[str | None] = mapped_column(String(300), nullable=True)
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
