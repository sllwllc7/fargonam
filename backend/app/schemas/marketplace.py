"""Marketplace uchun Pydantic sxemalari."""
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, model_validator

from app.models.order import DeliveryType, OrderStatus, PaymentMethod
from app.models.shop import ShopStatus


# ========== Shop ==========
class ShopCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    description: str | None = None


class ShopOut(BaseModel):
    id: int
    owner_id: int
    name: str
    description: str | None
    status: ShopStatus = ShopStatus.pending
    is_active: bool
    created_at: datetime
    model_config = {"from_attributes": True}


# ========== Category ==========
class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    slug: str = Field(min_length=1, max_length=140)
    parent_id: int | None = None
    icon: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    slug: str | None = Field(default=None, min_length=1, max_length=140)
    parent_id: int | None = None
    icon: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")


class CategoryReorderItem(BaseModel):
    id: int
    sort_order: int


class CategoryReorderRequest(BaseModel):
    items: list[CategoryReorderItem] = Field(min_length=1, max_length=200)


class CategoryOut(BaseModel):
    id: int
    name: str
    slug: str
    parent_id: int | None
    icon: str | None = None
    color: str | None = None
    sort_order: int = 0
    product_count: int = 0
    model_config = {"from_attributes": True}


# ========== Variant ==========
class VariantCreate(BaseModel):
    variant_name: str = Field(min_length=1, max_length=100)
    price: int = Field(gt=0)
    old_price: int | None = Field(default=None, gt=0)
    stock: int = Field(ge=0, default=0)
    sku: str | None = Field(default=None, max_length=64)
    attributes: dict = Field(default_factory=dict)
    image_url: str | None = None
    sort_order: int = 0


class VariantUpdate(BaseModel):
    variant_name: str | None = Field(default=None, min_length=1, max_length=100)
    price: int | None = Field(default=None, gt=0)
    old_price: int | None = Field(default=None, gt=0)
    stock: int | None = Field(default=None, ge=0)
    attributes: dict | None = None
    image_url: str | None = None
    is_active: bool | None = None
    sort_order: int | None = None


class VariantOut(BaseModel):
    id: int
    product_id: int
    sku: str
    variant_name: str
    price: int
    old_price: int | None
    stock: int
    attributes: dict
    image_url: str | None
    is_active: bool
    sort_order: int
    model_config = {"from_attributes": True}


# ========== Product ==========
class ProductCreate(BaseModel):
    shop_id: int
    category_id: int | None = None
    name: str = Field(min_length=1, max_length=200)
    brand: str | None = Field(default=None, max_length=100)
    description: str | None = None
    # mobile_seller joriy UI shu ikkitasini yuboradi — avtomatik "default"
    # variant yaratiladi (backend/app/api/products.py: create_product)
    price: Decimal = Field(gt=0)
    stock: int = Field(ge=0, default=0)


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    brand: str | None = Field(default=None, max_length=100)
    description: str | None = None
    # Berilsa — "default" variant yangilanadi (mobile_seller moslik)
    price: Decimal | None = Field(default=None, gt=0)
    stock: int | None = Field(default=None, ge=0)
    is_active: bool | None = None
    category_id: int | None = None


class ProductOut(BaseModel):
    id: int
    shop_id: int
    category_id: int | None
    name: str
    slug: str | None = None
    brand: str | None = None
    description: str | None
    image_url: str | None
    thumb_url: str | None = None
    is_active: bool
    created_at: datetime
    shop_name: str | None = None
    # Variant tanlash uchun (mobile_user)
    variants: list[VariantOut] = Field(default_factory=list)
    min_price: Decimal | None = None
    max_price: Decimal | None = None
    total_stock: int = 0
    # Eski moslik — "default" variantdan hisoblanadi (mobile_seller VA
    # mobile_user joriy UI hali shu maydonlarni o'qiydi, Flutter UI
    # yangilanmaguncha)
    price: Decimal | None = None
    stock: int | None = None
    # Moderatsiya — mobile_seller badge/xabar va admin moderatsiya navbati
    # uchun (mobile_user'ga chiqmaydi, chunki User App faqat status=approved
    # mahsulotlarni ko'radi)
    status: str = "approved"
    rejected_reason: str | None = None
    pending_edit: dict | None = None
    submitted_at: datetime | None = None
    model_config = {"from_attributes": True}


# ========== Cart ==========
class CartItemAdd(BaseModel):
    variant_id: int | None = None
    # Eski moslik — berilsa, mahsulotning "default" variantiga qo'shiladi
    product_id: int | None = None
    quantity: int = Field(ge=1, default=1)

    @model_validator(mode="after")
    def _check_target(self):
        if self.variant_id is None and self.product_id is None:
            raise ValueError("variant_id yoki product_id berilishi kerak")
        return self


class CartItemOut(BaseModel):
    id: int
    variant_id: int
    quantity: int
    variant_name: str | None = None
    price: int | None = None
    stock: int | None = None
    # Eski moslik nomlari (mobile_user joriy UI)
    product_id: int | None = None
    product_name: str | None = None
    product_price: str | None = None
    product_image_url: str | None = None
    # Variant o'chirilgan/nofaol bo'lsa false — checkout shu qatorni rad
    # etadi, xaridor buni oldindan ko'rib o'chirib tashlashi kerak
    is_available: bool = True
    model_config = {"from_attributes": True}


# ========== Order ==========
class OrderItemOut(BaseModel):
    id: int
    variant_id: int
    quantity: int
    price_at_purchase: Decimal
    variant_name: str | None = None
    # Eski moslik nomlari
    product_id: int | None = None
    product_name: str | None = None
    product_image_url: str | None = None
    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: int
    user_id: int
    total: Decimal
    status: OrderStatus
    payment_method: PaymentMethod = PaymentMethod.cash
    delivery_type: DeliveryType = DeliveryType.delivery
    delivery_address: str | None = None
    delivery_address_id: int | None = None
    # Faqat delivery_type=pickup'da to'ldiriladi — sotuvchi shu kod bo'yicha
    # xaridorni topib, savatni topshiradi
    pickup_code: str | None = None
    cancel_reason: str | None = None
    note: str | None = None
    # Faqat buyurtma sotuvchisi, admin va xaridorning o'ziga ko'rinadi —
    # OrderOut faqat shu uch tomon uchun scoped endpoint'larda ishlatiladi
    # (GET /orders, GET /seller/orders, GET /admin/orders)
    customer_phone: str | None = None
    customer_name: str | None = None
    created_at: datetime
    items: list[OrderItemOut]
    model_config = {"from_attributes": True}


# ========== Kit (ProductSet) — "Sinf to'plami" ==========
class KitItemCreate(BaseModel):
    variant_id: int
    quantity: int = Field(ge=1, default=1)


class KitItemOut(BaseModel):
    id: int
    variant_id: int
    quantity: int
    product_name: str | None = None
    variant_name: str | None = None
    price: int | None = None
    line_total: int | None = None


class KitCreate(BaseModel):
    shop_id: int
    name: str = Field(min_length=1, max_length=120)
    grade_level: str | None = Field(default=None, max_length=20)
    description: str | None = None
    image_url: str | None = None
    items: list[KitItemCreate] = Field(min_length=1)


class KitUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    grade_level: str | None = Field(default=None, max_length=20)
    description: str | None = None
    image_url: str | None = None
    is_active: bool | None = None
    # Berilsa — barcha itemlar shu ro'yxat bilan almashtiriladi
    items: list[KitItemCreate] | None = None


class KitOut(BaseModel):
    id: int
    shop_id: int | None
    name: str
    grade_level: str | None
    description: str | None
    image_url: str | None
    is_active: bool
    created_at: datetime
    items: list[KitItemOut] = Field(default_factory=list)
    total: int = 0
    status: str = "approved"
    rejected_reason: str | None = None
    pending_edit: dict | None = None
    submitted_at: datetime | None = None
    model_config = {"from_attributes": True}
