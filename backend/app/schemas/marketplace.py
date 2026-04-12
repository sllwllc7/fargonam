"""Marketplace uchun Pydantic sxemalari."""
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.order import OrderStatus, PaymentMethod


# ========== Shop ==========
class ShopCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    description: str | None = None


class ShopOut(BaseModel):
    id: int
    owner_id: int
    name: str
    description: str | None
    is_active: bool
    created_at: datetime
    model_config = {"from_attributes": True}


# ========== Category ==========
class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    slug: str = Field(min_length=1, max_length=140)
    parent_id: int | None = None


class CategoryOut(BaseModel):
    id: int
    name: str
    slug: str
    parent_id: int | None
    model_config = {"from_attributes": True}


# ========== Product ==========
class ProductCreate(BaseModel):
    shop_id: int
    category_id: int | None = None
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None
    price: Decimal = Field(gt=0)
    stock: int = Field(ge=0, default=0)


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None
    price: Decimal | None = Field(default=None, gt=0)
    stock: int | None = Field(default=None, ge=0)
    is_active: bool | None = None
    category_id: int | None = None


class ProductOut(BaseModel):
    id: int
    shop_id: int
    category_id: int | None
    name: str
    description: str | None
    price: Decimal
    stock: int
    image_url: str | None
    is_active: bool
    created_at: datetime
    shop_name: str | None = None
    model_config = {"from_attributes": True}


# ========== Cart ==========
class CartItemAdd(BaseModel):
    product_id: int
    quantity: int = Field(ge=1, default=1)


class CartItemOut(BaseModel):
    id: int
    product_id: int
    quantity: int
    # Mahsulot tafsilotlari (GET /cart javobida qo'shiladi)
    product_name: str | None = None
    product_price: str | None = None
    product_image_url: str | None = None
    model_config = {"from_attributes": True}


# ========== Order ==========
class OrderItemOut(BaseModel):
    id: int
    product_id: int
    quantity: int
    price_at_purchase: Decimal
    product_name: str | None = None
    product_image_url: str | None = None
    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: int
    user_id: int
    total: Decimal
    status: OrderStatus
    payment_method: PaymentMethod = PaymentMethod.cash
    delivery_address: str | None = None
    created_at: datetime
    items: list[OrderItemOut]
    model_config = {"from_attributes": True}
