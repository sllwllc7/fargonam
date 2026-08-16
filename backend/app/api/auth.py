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
    is_refresh_token_active,
    revoke_refresh_token,
    verify_password,
)
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    AddPhoneRequest,
    ChangePasswordRequest,
    RefreshTokenRequest,
    TokenResponse,
    UpdateProfileRequest,
    UserLogin,
    UserOut,
    UserRegister,
)

router = APIRouter(prefix="/auth", tags=["auth"])
# Eski parol-asosidagi endpointlar — hech bir klient ishlatmaydi
# (STATIC_OTP bilan bog'liq emas, alohida so'rov bilan uzildi).
# main.py ATAYIN ulamaydi — kod saqlanadi, faqat routing'dan uziladi.
legacy_router = APIRouter(prefix="/auth", tags=["auth-legacy"])


# ── Eski endpointlar (backwards compatibility, ULANMAGAN — legacy_router) ──

@legacy_router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
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
        refresh_token=await create_refresh_token(user.id),
    )


@legacy_router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
async def login(
    request: Request,
    payload: UserLogin,
    db: AsyncSession = Depends(get_db),
):
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    if not user or not user.hashed_password or not verify_password(payload.password, user.hashed_password):
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
        refresh_token=await create_refresh_token(user.id),
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10/minute")
async def refresh_token(
    request: Request,
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Refresh token orqali yangi access token olish — rotation bilan: eski
    refresh token bir martalik, ishlatilgach darhol bekor qilinadi. Bekor
    qilingan (yoki allaqachon ishlatilgan) tokenni qayta yuborish rad
    etiladi — bu token o'g'irlanganda uni sezish/to'xtatish imkonini beradi."""
    data = decode_token(payload.refresh_token)
    if not data or data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yaroqsiz refresh token",
        )
    user_id_str = data.get("sub")
    jti = data.get("jti")
    if not user_id_str or not jti:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Yaroqsiz token payload")
    if not await is_refresh_token_active(user_id_str, jti):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sessiya bekor qilingan, qaytadan kiring",
        )
    user_id = int(user_id_str)
    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Foydalanuvchi topilmadi yoki faol emas",
        )
    await revoke_refresh_token(user_id_str, jti)
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=await create_refresh_token(user.id),
    )


@router.post("/logout")
async def logout(
    payload: RefreshTokenRequest,
    current_user: User = Depends(get_current_user),
):
    """Refresh tokenni serverda bekor qiladi — shu qurilmadagi sessiya
    tugaydi. Access token o'zining tabiiy muddati bilan tugaydi (qisqa
    muddatli bo'lgani uchun bu muammo emas)."""
    data = decode_token(payload.refresh_token)
    jti = data.get("jti") if data else None
    if jti:
        await revoke_refresh_token(str(current_user.id), jti)
    return {"status": "chiqildi"}


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


@router.post("/me/phone", response_model=UserOut)
@limiter.limit("5/minute")
async def add_phone(
    request: Request,
    payload: AddPhoneRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Telegram orqali kirgan foydalanuvchi profiliga telefon raqam qo'shadi.

    OTP tasdiqlashsiz — foydalanuvchi allaqachon autentifikatsiya qilingan
    sessiyada. Real SMS ulanganda bu yerga tasdiqlash bosqichi qo'shiladi.
    """
    existing = await db.scalar(
        select(User).where(User.phone == payload.phone, User.id != current_user.id)
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu telefon raqam boshqa hisobda ishlatilmoqda",
        )
    current_user.phone = payload.phone
    await db.commit()
    await db.refresh(current_user)
    return current_user


@legacy_router.post("/change-password")
@limiter.limit("3/minute")
async def change_password(
    request: Request,
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Parolni o'zgartirish (JSON body)."""
    if not current_user.hashed_password:
        raise HTTPException(status_code=400, detail="Siz OTP orqali kirgansiz, parol o'rnatilmagan")
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


@legacy_router.post("/forgot-password", response_model=ForgotPasswordResponse)
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
