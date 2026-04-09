"""Auth uchun Pydantic sxemalari (request/response)."""
from datetime import datetime

from pydantic import BaseModel, Field

from app.models.user import UserRole


class UserRegister(BaseModel):
    phone: str = Field(min_length=9, max_length=20)
    password: str = Field(min_length=6, max_length=72)
    full_name: str | None = Field(default=None, max_length=120)
    role: UserRole = UserRole.buyer


class UserLogin(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: int
    phone: str
    full_name: str | None
    role: UserRole
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
