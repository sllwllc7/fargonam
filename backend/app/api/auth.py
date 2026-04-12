"""Auth endpointlar — OTP login, me, refresh, change-password."""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.middleware import limiter
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.db.session import get_db
from app.models.user import User, UserRole
from app.schemas.auth import (
    ChangePasswordRequest,
    RefreshTokenRequest,
    TokenResponse,
    UpdateProfileRequest,
    UserLogin,
    UserOut,
    UserRegister,
)

# SMS server ulangandan keyin bu o'zgaradi
STATIC_OTP = "5555"

router = APIRouter(prefix="/auth", tags=["auth"])


# ── OTP endpointlar ────────────────────────────────────────────

class SendOtpRequest(BaseModel):
    phone: str

class SendOtpResponse(BaseModel):
    status: str
    is_new_user: bool

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str
    full_name: str | None = None
    role: str = "buyer"


@router.post("/send-otp", response_model=SendOtpResponse)
@limiter.limit("5/minute")
async def send_otp(
    request: Request,
    payload: SendOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    """OTP yuborish (hozircha statik 5555)."""
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    # Haqiqiy SMS shu yerda yuboriladi (keyinroq Eskiz.uz ulanganda)
    return SendOtpResponse(status="ok", is_new_user=user is None)


@router.post("/verify-otp", response_model=TokenResponse)
@limiter.limit("10/minute")
async def verify_otp(
    request: Request,
    payload: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    """OTP tasdiqlash — yangi foydalanuvchi yaratadi yoki mavjudini tizimga kirgazadi."""
    if payload.otp != STATIC_OTP:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP kod noto'g'ri",
        )
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    if user is None:
        # Yangi foydalanuvchi — ro'yxatdan o'tkazish
        try:
            role = UserRole(payload.role)
        except ValueError:
            role = UserRole.buyer
        user = User(
            phone=payload.phone,
            full_name=payload.full_name,
            role=role,
            hashed_password=None,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    elif not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hisob faol emas",
        )
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


# ── Eski endpointlar (backwards compatibility) ─────────────────

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(
    request: Request,
    payload: UserRegister,
    db: AsyncSession = Depends(get_db),
):
    existing = await db.scalar(select(User).where(User.phone == payload.phone))
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu telefon raqam ro'yxatdan o'tgan",
        )
    user = User(
        phone=payload.phone,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
async def login(
    request: Request,
    payload: UserLogin,
    db: AsyncSession = Depends(get_db),
):
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Telefon yoki parol noto'g'ri",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hisob faol emas",
        )
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10/minute")
async def refresh_token(
    request: Request,
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Refresh token orqali yangi access token olish."""
    data = decode_token(payload.refresh_token)
    if not data or data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yaroqsiz refresh token",
        )
    user_id = int(data["sub"])
    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Foydalanuvchi topilmadi yoki faol emas",
        )
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.get("/me", response_model=UserOut)
async def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserOut)
async def update_profile(
    payload: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Profil ma'lumotlarini yangilash (JSON body)."""
    if payload.full_name is not None:
        current_user.full_name = payload.full_name.strip() or None
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.post("/change-password")
@limiter.limit("3/minute")
async def change_password(
    request: Request,
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Parolni o'zgartirish (JSON body)."""
    if not verify_password(payload.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Eski parol noto'g'ri")
    current_user.hashed_password = hash_password(payload.new_password)
    await db.commit()
    return {"status": "parol o'zgartirildi"}


class ForgotPasswordRequest(BaseModel):
    phone: str


class ForgotPasswordResponse(BaseModel):
    status: str
    message: str


@router.post("/forgot-password", response_model=ForgotPasswordResponse)
@limiter.limit("3/minute")
async def forgot_password(
    request: Request,
    payload: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    """Parolni tiklash so'rovi. Hozircha admin qo'lda tiklaydi.

    Kelajakda SMS kod yuborish qo'shiladi. Hozir esa faqat so'rovni ro'yxatga
    oladi va admin Telegram orqali yangi parol yuboradi.
    """
    # Foydalanuvchi borligini tekshirish (lekin borligini oshkor qilmaslik —
    # xavfsizlik uchun bir xil javob qaytariladi)
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    if user:
        # Admin'ga xabar qoldirish (notifications jadvaliga yoki log'ga)
        # TODO: Real SMS xizmatini ulash
        pass
    return ForgotPasswordResponse(
        status="ok",
        message=(
            "Agar ushbu raqam ro'yxatdan o'tgan bo'lsa, qo'llab-quvvatlash "
            "xizmati siz bilan bog'lanadi. Tezkor yordam uchun: "
            "@fargonam_support"
        ),
    )
