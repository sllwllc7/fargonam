"""Auth uchun Pydantic sxemalari (request/response)."""
import re
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.models.user import UserRole

# O'zbekiston telefon raqam formati: +998XXXXXXXXX yoki 998XXXXXXXXX
_PHONE_RE = re.compile(r"^\+?998\d{9}$")


class UserRegister(BaseModel):
    phone: str = Field(min_length=9, max_length=20)
    password: str = Field(min_length=8, max_length=72)
    full_name: str | None = Field(default=None, max_length=120)
    # Faqat buyer yoki seller — admin FAQAT boshqa admin yarata oladi
    role: UserRole = UserRole.buyer

    @field_validator("role")
    @classmethod
    def prevent_admin_registration(cls, v: UserRole) -> UserRole:
        if v == UserRole.admin:
            raise ValueError("Admin ro'yxatdan o'tish mumkin emas")
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = v.strip().replace(" ", "").replace("-", "")
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Telefon raqam formati noto'g'ri (masalan: +998901234567)")
        return cleaned

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not any(c.isdigit() for c in v):
            raise ValueError("Parolda kamida 1 ta raqam bo'lishi kerak")
        if not any(c.isalpha() for c in v):
            raise ValueError("Parolda kamida 1 ta harf bo'lishi kerak")
        return v


class UserLogin(BaseModel):
    phone: str = Field(min_length=9, max_length=20)
    password: str = Field(min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8, max_length=72)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        if not any(c.isdigit() for c in v):
            raise ValueError("Yangi parolda kamida 1 ta raqam bo'lishi kerak")
        if not any(c.isalpha() for c in v):
            raise ValueError("Yangi parolda kamida 1 ta harf bo'lishi kerak")
        return v


class UpdateProfileRequest(BaseModel):
    full_name: str | None = Field(default=None, max_length=120)


class AddPhoneRequest(BaseModel):
    phone: str = Field(min_length=9, max_length=20)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = v.strip().replace(" ", "").replace("-", "")
        if not _PHONE_RE.match(cleaned):
            raise ValueError("Telefon raqam formati noto'g'ri (masalan: +998901234567)")
        return cleaned


class UserOut(BaseModel):
    id: int
    phone: str | None
    full_name: str | None
    role: UserRole
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Telegram login ──────────────────────────────────────────────

class TelegramSessionResponse(BaseModel):
    session_id: str
    bot_url: str


class TelegramSessionStatusResponse(BaseModel):
    status: str  # "pending" | "confirmed"
    access_token: str | None = None
    refresh_token: str | None = None
    token_type: str = "bearer"
