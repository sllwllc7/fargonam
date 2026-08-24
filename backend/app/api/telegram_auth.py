"""Telegram bot orqali login — session-polling oqimi.

Uchala klient ham (mobile_user, mobile_seller, admin_web) shu endpoint'larni
ishlatadi — telefon+OTP butunlay olib tashlangan.

Oqim:
1. POST /auth/telegram/session — ilova bir martalik session yaratadi
   (ixtiyoriy `role` — yangi foydalanuvchi uchun boshlang'ich rol).
2. Ilova Telegram botni ochadi (`bot_url`), foydalanuvchi "Start" bosadi.
3. Telegram bizning webhook'imizga /start xabarini yuboradi — shu yerda
   session `telegram_id` bilan bog'lanadi va User topiladi/yaratiladi.
4. Ilova GET /auth/telegram/session/{id} bilan pollaydi, tasdiqlangach
   JWT token oladi.

`settings.ADMIN_TELEGRAM_IDS` ro'yxatidagi Telegram ID orqali kirgan
foydalanuvchiga har safar avtomatik `role=admin` beriladi. Ro'yxatdan
olib tashlangan foydalanuvchi keyingi safar kirganda huquqi ham avtomatik
qaytariladi (do'kon egasi bo'lsa 'seller', aks holda 'buyer').
"""
import hashlib
import hmac
import json
import logging
import uuid
from datetime import datetime, timezone
from urllib.parse import parse_qsl

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.middleware import limiter
from app.core.redis_client import get_redis
from app.core.security import create_access_token, create_refresh_token
from app.core.telegram_bot import send_message
from app.db.session import AsyncSessionLocal
from app.models.shop import Shop
from app.models.user import User, UserRole
from app.schemas.auth import TelegramSessionResponse, TelegramSessionStatusResponse, TokenResponse

logger = logging.getLogger("fargonam.telegram_auth")

router = APIRouter(prefix="/auth/telegram", tags=["auth"])

_SESSION_PREFIX = "tg_session:"
_SESSION_TTL = 300  # 5 daqiqa


@router.post("/session", response_model=TelegramSessionResponse)
@limiter.limit("10/minute")
async def create_session(request: Request, role: str = "buyer"):
    """Yangi Telegram login sessiyasi yaratadi.

    `role` — yangi (hali mavjud bo'lmagan) foydalanuvchi uchun boshlang'ich
    rol: mobile_user "buyer" (default), mobile_seller "seller" yuboradi.
    Mavjud foydalanuvchi uchun bu e'tiborga olinmaydi — u o'z roli bilan
    kiradi. "admin" faqat DEBUG=true bo'lganda qabul qilinadi (admin_web
    lokal sinovi uchun dev bypass sentinel) — productionda hech kim shu
    yo'l bilan o'zini admin qila olmasligi kerak."""
    if not settings.TELEGRAM_BOT_USERNAME:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Telegram login hali sozlanmagan",
        )
    if role not in ("buyer", "seller", "admin"):
        role = "buyer"
    if role == "admin" and not settings.DEBUG:
        role = "buyer"
    session_id = uuid.uuid4().hex
    redis = get_redis()

    if settings.DEBUG:
        # Lokal dev'da bot tasdiqlashni talab qilmaymiz — sessiya darhol
        # "confirmed" bo'ladi. Production'da DEBUG har doim majburan false
        # (deploy_backend.sh), shu sababli bu bypass u yerda hech qachon
        # ishlamaydi.
        user_id = await _get_or_create_dev_user(role)
        await redis.set(
            f"{_SESSION_PREFIX}{session_id}",
            json.dumps({"status": "confirmed", "user_id": user_id}),
            ex=_SESSION_TTL,
        )
        logger.warning("DEBUG=true: Telegram tasdiqlash chetlab o'tildi (dev user_id=%s)", user_id)
        return TelegramSessionResponse(
            session_id=session_id,
            bot_url=f"https://t.me/{settings.TELEGRAM_BOT_USERNAME}?start={session_id}",
        )

    await redis.set(
        f"{_SESSION_PREFIX}{session_id}",
        json.dumps({"status": "pending", "role": role}),
        ex=_SESSION_TTL,
    )
    return TelegramSessionResponse(
        session_id=session_id,
        bot_url=f"https://t.me/{settings.TELEGRAM_BOT_USERNAME}?start={session_id}",
    )


@router.get("/session/{session_id}", response_model=TelegramSessionStatusResponse)
@limiter.limit("40/minute")  # ilova 2s intervalda polling qiladi (~30/min) — tasodifiy limitga urilmaslik uchun zaxira
async def poll_session(request: Request, session_id: str):
    """Ilova bu endpoint'ni pollab, sessiya tasdiqlanganini kutadi."""
    redis = get_redis()
    key = f"{_SESSION_PREFIX}{session_id}"
    raw = await redis.get(key)
    if raw is None:
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Sessiya muddati tugagan, qaytadan urinib ko'ring",
        )
    data = json.loads(raw)
    if data.get("status") != "confirmed":
        return TelegramSessionStatusResponse(status="pending")

    user_id = data["user_id"]
    await redis.delete(key)  # bir martalik ishlatish
    return TelegramSessionStatusResponse(
        status="confirmed",
        access_token=create_access_token(user_id),
        refresh_token=await create_refresh_token(user_id),
    )


_DEV_TELEGRAM_IDS = {"buyer": -1001, "seller": -1002, "admin": -1003}


async def _get_or_create_dev_user(role: str) -> int:
    """Faqat DEBUG=true rejimida chaqiriladi — sentinel telegram_id bilan
    doimiy test foydalanuvchisini topadi yoki yaratadi."""
    telegram_id = _DEV_TELEGRAM_IDS[role]
    async with AsyncSessionLocal() as db:
        user = await db.scalar(select(User).where(User.telegram_id == telegram_id))
        if user is None:
            user = User(
                telegram_id=telegram_id,
                phone=None,
                full_name=f"Dev {role.capitalize()}",
                role=UserRole(role),
                hashed_password=None,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
        return user.id


async def process_telegram_update(update: dict, db: AsyncSession) -> None:
    """Bitta Telegram update'ni qayta ishlaydi — webhook va long-polling
    ikkalasi ham shu funksiyani chaqiradi (yagona logika)."""
    msg = update.get("message")
    if not msg or "text" not in msg:
        return

    text: str = msg["text"]
    if not text.startswith("/start "):
        return

    session_id = text.removeprefix("/start ").strip()
    tg_user = msg.get("from") or {}
    telegram_id = tg_user.get("id")
    chat_id = msg.get("chat", {}).get("id", telegram_id)
    if not telegram_id:
        return

    redis = get_redis()
    key = f"{_SESSION_PREFIX}{session_id}"
    raw = await redis.get(key)
    if raw is None:
        await send_message(chat_id, "Sessiya topilmadi. Ilovada qaytadan urinib ko'ring.")
        return
    session_data = json.loads(raw)

    is_admin_id = str(telegram_id) in settings.admin_telegram_ids
    user = await db.scalar(select(User).where(User.telegram_id == telegram_id))
    if user is None:
        full_name = " ".join(
            filter(None, [tg_user.get("first_name"), tg_user.get("last_name")])
        ) or None
        role = UserRole.seller if session_data.get("role") == "seller" else UserRole.buyer
        if is_admin_id:
            role = UserRole.admin
        user = User(
            telegram_id=telegram_id,
            phone=None,
            full_name=full_name,
            role=role,
            hashed_password=None,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    elif not user.is_active:
        await send_message(chat_id, "Hisobingiz faol emas.")
        return
    elif is_admin_id and user.role != UserRole.admin:
        user.role = UserRole.admin
        await db.commit()
        await db.refresh(user)
    elif not is_admin_id and user.role == UserRole.admin:
        # ADMIN_TELEGRAM_IDS'dan olib tashlangan — huquq qaytariladi.
        # Do'kon egasi bo'lsa 'seller' (o'z buyurtmalarini boshqarish
        # huquqi saqlansin), aks holda oddiy 'buyer'.
        owns_shop = await db.scalar(select(Shop.id).where(Shop.owner_id == user.id))
        user.role = UserRole.seller if owns_shop else UserRole.buyer
        await db.commit()
        await db.refresh(user)

    await redis.set(
        key,
        json.dumps({"status": "confirmed", "user_id": user.id}),
        ex=_SESSION_TTL,
    )
    await send_message(chat_id, "✅ Fargonam ilovasiga muvaffaqiyatli kirdingiz! Ilovaga qaytishingiz mumkin.")


async def upsert_telegram_user(db: AsyncSession, tg_user: dict) -> User:
    """Telegram foydalanuvchisini `telegram_id` bo'yicha topadi yoki yaratadi.

    Mini App (`/auth/telegram/webapp`) va miniapp bot'ning o'z `/start`
    ishlovchisi (`app/core/telegram_miniapp_bot.py`) ikkalasi ham shu
    funksiyani chaqiradi — bitta joyda, bir xil qoida bilan. Eski
    session-polling oqimi (`process_telegram_update`, yuqorida) bunga
    tegmaydi va o'zgarmaydi.

    Telegram'dan kelgan xom maydonlar (username/ism/til) har safar
    yangilanadi. `full_name` esa faqat birinchi yaratilishda shundan
    hosil qilinadi — foydalanuvchi keyin profilda o'zgartirsa, keyingi
    kirishlarda qayta yozib yuborilmaydi."""
    telegram_id = tg_user.get("id")
    username = tg_user.get("username")
    first_name = tg_user.get("first_name")
    last_name = tg_user.get("last_name")
    language_code = tg_user.get("language_code")
    is_admin_id = str(telegram_id) in settings.admin_telegram_ids

    user = await db.scalar(select(User).where(User.telegram_id == telegram_id))
    if user is None:
        full_name = " ".join(filter(None, [first_name, last_name])) or None
        user = User(
            telegram_id=telegram_id,
            phone=None,
            full_name=full_name,
            telegram_username=username,
            telegram_first_name=first_name,
            telegram_last_name=last_name,
            language_code=language_code,
            role=UserRole.admin if is_admin_id else UserRole.buyer,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    changed = False
    for field, value in (
        ("telegram_username", username),
        ("telegram_first_name", first_name),
        ("telegram_last_name", last_name),
        ("language_code", language_code),
    ):
        if getattr(user, field) != value:
            setattr(user, field, value)
            changed = True
    if is_admin_id and user.role != UserRole.admin:
        user.role = UserRole.admin
        changed = True
    if changed:
        await db.commit()
        await db.refresh(user)
    return user


class TelegramWebAppAuthRequest(BaseModel):
    init_data: str


def _validate_webapp_init_data(init_data: str, bot_token: str) -> dict:
    """Telegram Mini App `initData` imzosini tekshiradi (Telegram hujjatidagi
    HMAC-SHA256 algoritmi) va parslangan maydonlar lug'atini qaytaradi."""
    pairs = dict(parse_qsl(init_data, strict_parsing=False))
    received_hash = pairs.pop("hash", None)
    if not received_hash:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="initData imzosi yo'q")
    data_check_string = "\n".join(f"{k}={v}" for k, v in sorted(pairs.items()))
    secret_key = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    computed_hash = hmac.new(secret_key, data_check_string.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(computed_hash, received_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="initData imzosi noto'g'ri")
    auth_date = int(pairs.get("auth_date", "0") or "0")
    if auth_date and (datetime.now(timezone.utc).timestamp() - auth_date) > 86400:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="initData muddati tugagan, Mini App'ni qayta oching")
    return pairs


@router.post("/webapp", response_model=TokenResponse)
@limiter.limit("30/minute")
async def telegram_webapp_login(request: Request, payload: TelegramWebAppAuthRequest):
    """Telegram Mini App ichida ishga tushganda chaqiriladi — foydalanuvchi
    Telegram'da allaqachon autentifikatsiya qilingani uchun bot/session-polling
    oqimi (yuqoridagi /session) shart emas, `initData` imzosi tekshirilib
    to'g'ridan-to'g'ri JWT beriladi."""
    bot_token = settings.TELEGRAM_MINIAPP_BOT_TOKEN or settings.TELEGRAM_BOT_TOKEN
    if not bot_token:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Telegram login hali sozlanmagan",
        )
    pairs = _validate_webapp_init_data(payload.init_data, bot_token)
    user_raw = pairs.get("user")
    if not user_raw:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Foydalanuvchi ma'lumoti yo'q")
    tg_user = json.loads(user_raw)
    telegram_id = tg_user.get("id")
    if not telegram_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Telegram ID topilmadi")

    async with AsyncSessionLocal() as db:
        user = await upsert_telegram_user(db, tg_user)
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Hisobingiz faol emas")

        return TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=await create_refresh_token(user.id),
        )


@router.post("/webhook/{secret}")
async def telegram_webhook(secret: str, request: Request):
    """Telegram bot API webhook — foydalanuvchi botda "Start" bosganda chaqiriladi.

    Production'da (ochiq HTTPS domen bo'lganda) ishlatiladi. Lokal
    dev'da esa `TELEGRAM_USE_POLLING=true` bilan long-polling ishlatiladi
    (`app/core/telegram_polling.py`) — domen shart emas."""
    if not settings.TELEGRAM_WEBHOOK_SECRET or secret != settings.TELEGRAM_WEBHOOK_SECRET:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)

    update = await request.json()
    async with AsyncSessionLocal() as db:
        await process_telegram_update(update, db)
    return {"ok": True}
