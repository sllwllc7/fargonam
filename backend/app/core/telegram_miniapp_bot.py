"""Telegram Mini App bot'ining o'z `/start` ishlovchisi va long-polling'i.

Asosiy login bot (`fargonam_bot`, `TELEGRAM_BOT_TOKEN`) — mobile_user/
mobile_seller/admin_web uchun session-polling oqimi, `telegram_polling.py`
+ `process_telegram_update` orqali ishlaydi va bu faylga umuman tegishli
emas (BUZILMASIN talabi — shu sababli alohida fayl, alohida polling loop).

Bu bot (`TELEGRAM_MINIAPP_BOT_TOKEN`) faqat Mini App uchun: /start bosilganda
foydalanuvchi bazada upsert qilinadi, xush kelibsiz xabari + "Do'konni
ochish" (WebApp) va "Raqamni ulashish" (contact) tugmalari beriladi, Menu
Button ham WebApp'ga sozlanadi. Webhook infratuzilmasi hali yo'q (production
domenda ham), shuning uchun bu bot doim long-polling orqali ishlaydi —
ochiq HTTPS domen shart emas.
"""
import asyncio
import logging
import uuid

import httpx
from sqlalchemy import select

from app.core.config import settings
from app.core.redis_client import get_redis
from app.core.telegram_bot import call_bot_api, send_message
from app.db.session import AsyncSessionLocal

logger = logging.getLogger("fargonam.telegram_miniapp_bot")

# Production 4 ta uvicorn worker'da ishlaydi — har biri o'z startup
# event'ida shu funksiyani chaqiradi. Telegram bitta bot tokenida faqat
# bitta getUpdates ulanishiga ruxsat beradi (409 Conflict), shuning uchun
# Redis orqali "faqat bitta worker poll qiladi" qulfi kerak.
_LOCK_KEY = "miniapp_bot:poll_lock"
_LOCK_TTL = 45

WELCOME_TEXT = (
    "Assalomu alaykum! 👋\n\n"
    "Fargonam — Farg'ona vodiysi o'quv qurollari do'koniga xush kelibsiz.\n\n"
    "Quyidagi tugma orqali do'konni oching va xarid qilishni boshlang."
)


def _menu_button(url: str) -> dict:
    return {"type": "web_app", "text": "Do'konni ochish", "web_app": {"url": url}}


def _welcome_keyboard(url: str) -> dict:
    return {
        "keyboard": [
            [{"text": "🛍 Do'konni ochish", "web_app": {"url": url}}],
            [{"text": "📱 Raqamni ulashish", "request_contact": True}],
        ],
        "resize_keyboard": True,
    }


async def _handle_start(chat_id: int, tg_user: dict, bot_token: str) -> None:
    from app.api.telegram_auth import upsert_telegram_user  # circular import oldini olish

    async with AsyncSessionLocal() as db:
        await upsert_telegram_user(db, tg_user)

    await call_bot_api(
        "setChatMenuButton",
        bot_token,
        {"chat_id": chat_id, "menu_button": _menu_button(settings.MINIAPP_URL)},
    )
    await send_message(
        chat_id,
        WELCOME_TEXT,
        bot_token=bot_token,
        reply_markup=_welcome_keyboard(settings.MINIAPP_URL),
    )


async def _handle_contact(chat_id: int, contact: dict, tg_user: dict) -> None:
    """"Raqamni ulashish" tugmasi bosilganda keladi. Faqat o'zining
    raqamini ulashganini tasdiqlaymiz (`user_id` mos kelishi shart) —
    boshqa birovning kontaktini bosib yuborish orqali soxta bog'lashning
    oldi olinadi."""
    phone = contact.get("phone_number")
    contact_user_id = contact.get("user_id")
    if not phone or contact_user_id != tg_user.get("id"):
        return

    phone = "+" + phone.lstrip("+")
    async with AsyncSessionLocal() as db:
        from app.models.user import User

        user = await db.scalar(select(User).where(User.telegram_id == tg_user.get("id")))
        if user and not user.phone:
            user.phone = phone
            await db.commit()


async def process_miniapp_update(update: dict, bot_token: str) -> None:
    msg = update.get("message")
    if not msg:
        return
    chat_id = msg.get("chat", {}).get("id")
    tg_user = msg.get("from") or {}
    if not chat_id or not tg_user.get("id"):
        return

    text = msg.get("text") or ""
    if text.startswith("/start"):
        await _handle_start(chat_id, tg_user, bot_token)
        return

    contact = msg.get("contact")
    if contact:
        await _handle_contact(chat_id, contact, tg_user)


def _api_url(method: str, bot_token: str) -> str:
    return f"https://api.telegram.org/bot{bot_token}/{method}"


async def _acquire_or_wait_lock(worker_id: str) -> None:
    """Faqat bitta worker poll qilishi kerak — Redis NX qulfi orqali
    "yetakchi" tanlanadi. Boshqalar qulf bo'shashini kutib turadi (yetakchi
    yiqilsa TTL tugab, kutayotganlardan biri egallab oladi)."""
    redis = get_redis()
    while True:
        acquired = await redis.set(_LOCK_KEY, worker_id, nx=True, ex=_LOCK_TTL)
        if acquired:
            return
        await asyncio.sleep(_LOCK_TTL / 3)


async def _renew_lock(worker_id: str) -> None:
    redis = get_redis()
    current = await redis.get(_LOCK_KEY)
    if current == worker_id:
        await redis.expire(_LOCK_KEY, _LOCK_TTL)


async def run_miniapp_polling_loop() -> None:
    bot_token = settings.TELEGRAM_MINIAPP_BOT_TOKEN
    if not bot_token:
        return

    worker_id = uuid.uuid4().hex
    await _acquire_or_wait_lock(worker_id)

    async with httpx.AsyncClient(timeout=40) as client:
        await client.post(_api_url("deleteWebhook", bot_token))
        # Botning standart Menu Button'i — hali /start bermagan foydalanuvchi
        # ham (masalan botni oldin boshqa sababda ochgan bo'lsa) tugmani ko'radi.
        await call_bot_api(
            "setChatMenuButton", bot_token, {"menu_button": _menu_button(settings.MINIAPP_URL)}
        )
        logger.info("Miniapp bot long-polling boshlandi (worker=%s)", worker_id)

        offset = 0
        while True:
            try:
                await _renew_lock(worker_id)
                resp = await client.get(
                    _api_url("getUpdates", bot_token),
                    params={"offset": offset, "timeout": 30},
                )
                data = resp.json()
                for update in data.get("result", []):
                    offset = update["update_id"] + 1
                    await process_miniapp_update(update, bot_token)
            except asyncio.CancelledError:
                raise
            except Exception:
                logger.exception("Miniapp bot polling xatosi, 3s dan keyin qayta urinamiz")
                await asyncio.sleep(3)
