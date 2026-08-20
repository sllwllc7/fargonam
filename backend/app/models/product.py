"""Product modeli — parent mahsulot (umumiy nom). Narx/stok endi ProductVariant'da."""
from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class ProductStatus(str, Enum):
    """Moderatsiya holati — Web Admin Panel tasdiqlaydi/rad etadi."""
    draft = "draft"
    pending = "pending"      # Sotuvchi yubordi, admin tekshiruvini kutmoqda
    approved = "approved"    # Tasdiqlangan — User App'da ko'rinadi
    rejected = "rejected"    # Rad etilgan (rejected_reason'ga qara)


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    shop_id: Mapped[int] = mapped_column(
        ForeignKey("shops.id", ondelete="CASCADE"), index=True
    )
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True
    )
    name: Mapped[str] = mapped_column(String(200))
    slug: Mapped[str | None] = mapped_column(String(220), unique=True, nullable=True, index=True)
    brand: Mapped[str | None] = mapped_column(String(100), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Parent darajasidagi "asosiy" rasm (kartochka uchun) — variantlar o'z rasmini
    # bersa shuni bekor qiladi, aks holda shu ko'rsatiladi
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Kvadrat preview (400x400 JPEG) — Pillow bilan yuklashda generatsiya qilinadi
    thumb_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # ── Moderatsiya ──────────────────────────────────────────
    status: Mapped[ProductStatus] = mapped_column(
        SAEnum(ProductStatus, name="product_status"),
        default=ProductStatus.pending,
        nullable=False,
        server_default="pending",
    )
    rejected_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    moderated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    moderated_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    # Tasdiqlangan mahsulotga himoyalangan maydon (nom/rasm/tavsif/kategoriya)
    # o'zgarishi shu yerga JSON sifatida yoziladi — LIVE qator (yuqoridagi
    # maydonlar) tasdiqlangan holicha qoladi, User App eskisini ko'rsatishda
    # davom etadi. Admin tasdiqlasa shu diff qatorga qo'llanadi va tozalanadi.
    # Narx/zaxira (ProductVariant.price/stock) bunga kirmaydi — doim darhol.
    pending_edit: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
