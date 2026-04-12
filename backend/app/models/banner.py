"""Banner/Promo modeli — admin reklama videolari va rasmlari uchun (story formatda)."""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class Banner(Base):
    __tablename__ = "banners"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    # Story matni (qisqa tavsif)
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    # media_url — rasm yoki video URL (lokal /static/ yoki tashqi link)
    media_url: Mapped[str] = mapped_column(String(500))
    # link_url — banner bosilganda qaerga o'tish (ixtiyoriy)
    link_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
