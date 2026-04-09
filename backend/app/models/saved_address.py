"""Saqlangan manzillar — Uy, Ish, va boshqalar."""
from sqlalchemy import Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class SavedAddress(Base):
    __tablename__ = "saved_addresses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[str] = mapped_column(String(50))  # "Uy", "Ish", "Boshqa"
    address: Mapped[str] = mapped_column(String(300))
    lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    lng: Mapped[float | None] = mapped_column(Float, nullable=True)
