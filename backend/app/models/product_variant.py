"""ProductVariant — bitta parent mahsulotning sotiladigan turi (masalan '12 varoqli daftar').

Narx/stok/SKU shu darajada saqlanadi, parent (`Product`) faqat umumiy nom/tavsif.
Turli mahsulot turlarida atribut turlari har xil bo'lgani uchun (daftarda varoq
soni, ruchkada rang) qat'iy ustunlar o'rniga moslashuvchan `attributes` JSONB
ishlatiladi."""
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class ProductVariant(Base):
    __tablename__ = "product_variants"
    __table_args__ = (
        CheckConstraint("price > 0", name="ck_variant_price_positive"),
        CheckConstraint("stock >= 0", name="ck_variant_stock_nonneg"),
        CheckConstraint(
            "old_price IS NULL OR old_price > price", name="ck_variant_old_price_gt_price"
        ),
        Index("ix_variants_attributes_gin", "attributes", postgresql_using="gin"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(
        ForeignKey("products.id", ondelete="CASCADE"), index=True
    )
    sku: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    # Foydalanuvchi ko'radigan nom: "12 varoqli", "24 rangli"
    variant_name: Mapped[str] = mapped_column(String(100))
    # Narx — so'mda, butun son (tiyin/kasr yo'q, yaxlitlash xatosidan qochish uchun)
    price: Mapped[int] = mapped_column(Integer)
    old_price: Mapped[int | None] = mapped_column(Integer, nullable=True)
    stock: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    # Moslashuvchan atributlar: {"varoq_soni": 48} yoki {"rang": "ko'k"} va h.k.
    attributes: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Variantlar to'g'ri tartibda chiqishi uchun (12, 36, 48, 96 — alifbo bo'yicha emas)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
