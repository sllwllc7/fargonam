"""Order va OrderItem modellari."""
from datetime import datetime
from decimal import Decimal
from enum import Enum

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.db.base import Base


class OrderStatus(str, Enum):
    pending = "pending"
    paid = "paid"
    shipped = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"


class PaymentMethod(str, Enum):
    cash = "cash"        # Naqd olishda
    card = "card"        # Plastik karta (kuryerga)
    payme = "payme"      # Payme (keyinchalik)
    click = "click"      # Click (keyinchalik)


class DeliveryType(str, Enum):
    delivery = "delivery"  # Kuryer orqali yetkazib berish
    pickup = "pickup"      # Xaridor do'kondan o'zi olib ketadi (pickup_code bilan)


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    status: Mapped[OrderStatus] = mapped_column(
        SAEnum(OrderStatus, name="order_status"),
        default=OrderStatus.pending,
        nullable=False,
        index=True,
    )
    payment_method: Mapped[PaymentMethod] = mapped_column(
        SAEnum(PaymentMethod, name="payment_method"),
        default=PaymentMethod.cash,
        nullable=False,
    )
    delivery_type: Mapped[DeliveryType] = mapped_column(
        SAEnum(DeliveryType, name="delivery_type"),
        default=DeliveryType.delivery,
        nullable=False,
        server_default=DeliveryType.delivery.value,
    )
    # Yetkazib berish manzili — buyurtma paytidagi "surat" (matn), keyin
    # SavedAddress o'zgarsa ham eski buyurtmada to'g'ri ko'rinishi uchun.
    # pickup buyurtmalarda bo'sh qoladi.
    delivery_address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Qaysi saqlangan manzildan olinganiga ishora (o'chirilsa ham buyurtma qolaveradi)
    delivery_address_id: Mapped[int | None] = mapped_column(
        ForeignKey("saved_addresses.id", ondelete="SET NULL"), nullable=True
    )
    # 4 xonali pickup kod (faqat delivery_type=pickup'da) — butun tarix
    # bo'yicha unikal, hech qachon qayta ishlatilmaydi (DB darajasida
    # unique constraint bilan kafolatlangan — NULL qiymatlar to'qnashmaydi).
    pickup_code: Mapped[str | None] = mapped_column(String(4), unique=True, nullable=True)
    # Bekor qilinganda sabab (xaridor bekor qilsa odatda bo'sh, sotuvchi
    # "Bajarib bo'lmaydi" desa to'ldiriladi)
    cancel_reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", lazy="selectin"
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(
        ForeignKey("orders.id", ondelete="CASCADE"), index=True
    )
    variant_id: Mapped[int] = mapped_column(
        ForeignKey("product_variants.id", ondelete="RESTRICT"), index=True
    )
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    # Buyurtma berilgan paytdagi narx — keyin mahsulot narxi o'zgarsa ham saqlanib qoladi
    price_at_purchase: Mapped[Decimal] = mapped_column(Numeric(12, 2))

    order: Mapped["Order"] = relationship(back_populates="items")
