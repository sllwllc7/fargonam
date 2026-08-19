"""Telegram Bot API bilan minimal integratsiya — faqat xabar yuborish uchun.

To'liq kutubxona (aiogram va h.k.) kerak emas: bizga bot API'ning bitta
metodi (`sendMessage`) va tashqi webhook orqali keladigan update'larni
JSON sifatida o'qish kifoya.
"""
import httpx

from app.core.config import settings


def _api_url(method: str) -> str:
    return f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/{method}"


async def send_message(chat_id: int, text: str) -> None:
    """Botdan foydalanuvchiga xabar yuboradi. Xato bo'lsa jim yutiladi —
    webhook javobi baribir Telegram'ga 200 qaytarishi kerak."""
    if not settings.TELEGRAM_BOT_TOKEN:
        return
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            await client.post(_api_url("sendMessage"), json={"chat_id": chat_id, "text": text})
    except httpx.HTTPError:
        pass
