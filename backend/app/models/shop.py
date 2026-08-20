"""Shop modeli — sotuvchining do'koni."""
from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class ShopStatus(str, Enum):
    """Do'kon KYC holati."""
    pending = "pending"      # Admin tasdiqini kutmoqda
    approved = "approved"    # Tasdiqlangan — mahsulot yuklash mumkin
    rejected = "rejected"    # Rad etilgan


class Shop(Base):
    __tablename__ = "shops"

    id: Mapped[int] = mapped_column(primary_key=True)
    owner_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # KYC holati — yangi do'konlar pending bo'ladi
    status: Mapped[ShopStatus] = mapped_column(
        SAEnum(ShopStatus, name="shop_status"),
        default=ShopStatus.pending,
        nullable=False,
        server_default="pending",
    )
    # Admin izohi (rad etish sababi yoki eslatma)
    admin_note: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Yoqilsa — bu do'kon mahsulotlari moderatsiyasiz to'g'ridan-to'g'ri
    # tasdiqlanadi (hozircha standart o'chiq, kelajakda ishlatish uchun).
    is_trusted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
