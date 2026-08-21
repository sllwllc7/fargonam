"""Category modeli — daraxt shaklida (parent_id self-FK)."""
from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    slug: Mapped[str] = mapped_column(String(140), unique=True, index=True)
    parent_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True
    )
    icon: Mapped[str | None] = mapped_column(String(64), nullable=True)
    color: Mapped[str | None] = mapped_column(String(7), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    # Rasm — ikonkadan ustun turadi (bor bo'lsa UI rasmni ko'rsatadi, aks
    # holda ikonkaga qaytadi). image_url — siqilgan asosiy, thumb_url —
    # kvadrat preview (process_product_image bilan bir xil qayta ishlov).
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    thumb_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
