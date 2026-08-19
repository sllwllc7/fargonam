"""Telegram bot yangilanishlarini long-polling orqali olish.

Webhook ochiq HTTPS domen talab qiladi — lokal dev'da bu yo'q, shuning
uchun `TELEGRAM_USE_POLLING=true` bo'lsa, backend Telegram'ning
`getUpdates` (long-polling) metodi orqali o'zi so'rab turadi. Ikkalasi
bir vaqtda ishlay olmaydi (Telegram konflikt beradi), shuning uchun
polling boshlashdan oldin webhook o'chiriladi.
"""
import asyncio
import logging

import httpx

from app.core.config import settings
from app.db.session import AsyncSessionLocal

logger = logging.getLogger("fargonam.telegram_polling")


def _api_url(method: str) -> str:
    return f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/{method}"


async def run_polling_loop() -> None:
    from app.api.telegram_auth import process_telegram_update  # circular import oldini olish

    async with httpx.AsyncClient(timeout=40) as client:
        await client.post(_api_url("deleteWebhook"))
        logger.info("Telegram long-polling boshlandi")

        offset = 0
        while True:
            try:
                resp = await client.get(
                    _api_url("getUpdates"),
                    params={"offset": offset, "timeout": 30},
                )
                data = resp.json()
                for update in data.get("result", []):
                    offset = update["update_id"] + 1
                    async with AsyncSessionLocal() as db:
                        await process_telegram_update(update, db)
            except asyncio.CancelledError:
                raise
            except Exception:
                logger.exception("Telegram polling xatosi, 3s dan keyin qayta urinamiz")
                await asyncio.sleep(3)
