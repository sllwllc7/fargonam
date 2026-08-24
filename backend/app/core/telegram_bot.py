"""Telegram Bot API bilan minimal integratsiya — faqat xabar yuborish uchun.

To'liq kutubxona (aiogram va h.k.) kerak emas: bizga bot API'ning bitta
metodi (`sendMessage`) va tashqi webhook orqali keladigan update'larni
JSON sifatida o'qish kifoya.
"""
import httpx

from app.core.config import settings


def _api_url(method: str, bot_token: str | None = None) -> str:
    token = bot_token or settings.TELEGRAM_BOT_TOKEN
    return f"https://api.telegram.org/bot{token}/{method}"


async def send_message(
    chat_id: int,
    text: str,
    bot_token: str | None = None,
    reply_markup: dict | None = None,
) -> None:
    """Botdan foydalanuvchiga xabar yuboradi. Xato bo'lsa jim yutiladi —
    webhook javobi baribir Telegram'ga 200 qaytarishi kerak.

    `bot_token` berilmasa asosiy login bot (`TELEGRAM_BOT_TOKEN`) ishlatiladi —
    eski chaqiruvlar o'zgarishsiz ishlayveradi. Miniapp bot xabarlari
    (masalan buyurtma holati) o'z tokenini aniq beradi."""
    token = bot_token or settings.TELEGRAM_BOT_TOKEN
    if not token:
        return
    payload = {"chat_id": chat_id, "text": text}
    if reply_markup is not None:
        payload["reply_markup"] = reply_markup
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            await client.post(_api_url("sendMessage", token), json=payload)
    except httpx.HTTPError:
        pass


async def call_bot_api(method: str, bot_token: str, payload: dict) -> dict | None:
    """Telegram Bot API'ning istalgan metodini chaqiradi (masalan
    `setChatMenuButton`). Xato bo'lsa `None` qaytaradi, jim yutiladi."""
    if not bot_token:
        return None
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(_api_url(method, bot_token), json=payload)
            return resp.json()
    except httpx.HTTPError:
        return None
