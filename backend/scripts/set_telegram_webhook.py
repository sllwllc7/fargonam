"""Telegram bot webhook'ni o'rnatish — bir martalik operatsion skript.

Backend HTTPS (nginx) ortida ishga tushgandan keyin, `.env`da
TELEGRAM_BOT_TOKEN, TELEGRAM_WEBHOOK_SECRET va API domeni tayyor bo'lgach
ishga tushiring. Telegram HTTP webhook qabul qilmaydi — domen HTTPS
bo'lishi shart.

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.set_telegram_webhook https://api.fargonam.uz
"""
import asyncio
import sys

import httpx

from app.core.config import settings


async def main(base_url: str) -> None:
    if not settings.TELEGRAM_BOT_TOKEN or not settings.TELEGRAM_WEBHOOK_SECRET:
        print("❌ TELEGRAM_BOT_TOKEN va TELEGRAM_WEBHOOK_SECRET .env'da to'ldirilishi kerak")
        sys.exit(1)

    webhook_url = f"{base_url.rstrip('/')}/auth/telegram/webhook/{settings.TELEGRAM_WEBHOOK_SECRET}"
    api_url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/setWebhook"

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            api_url,
            json={
                "url": webhook_url,
                "secret_token": settings.TELEGRAM_WEBHOOK_SECRET,
            },
        )
    print(resp.status_code, resp.json())


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Foydalanish: python -m scripts.set_telegram_webhook <https://api-domen>")
        sys.exit(1)
    asyncio.run(main(sys.argv[1]))
