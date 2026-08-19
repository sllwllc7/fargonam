"""Fargonam APK tarqatish boti — mustaqil, oddiy Telegram bot.

Auth uchun ishlatiladigan bot bilan (backend/app/api/telegram_auth.py)
bir xil TELEGRAM_BOT_TOKEN ishlatiladi. Telegram bitta bot uchun faqat
bitta yetkazish usulini (webhook YOKI getUpdates polling) qo'llab-
quvvatlaydi — shuning uchun bu bot yagona poller bo'lib ishlaydi:
oddiy "/start", tugma bosishlar va "/versiya"ni o'zi javob beradi,
"/start <session_id>" (login deep-link) kelsa esa uni backend'ning
mavjud webhook endpoint'iga (`/auth/telegram/webhook/{secret}`)
ichki HTTP so'rov bilan uzatadi — shu orqali auth oqimi backend
kodini o'zgartirmasdan ishlay oladi.
"""
import glob
import logging
import os
import re
from datetime import datetime

import httpx
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import Application, CallbackQueryHandler, CommandHandler, ContextTypes

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("fargonam.apk_bot")

BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
APK_DIR = os.environ.get("APK_DIR", "/apks")
MAX_TELEGRAM_FILE = 50 * 1024 * 1024  # Bot API limiti

_webhook_secret = os.environ.get("TELEGRAM_WEBHOOK_SECRET", "")
_backend_url = os.environ.get("BACKEND_INTERNAL_URL", "http://backend:8000")
AUTH_WEBHOOK_URL = f"{_backend_url}/auth/telegram/webhook/{_webhook_secret}" if _webhook_secret else None

APP_LABELS = {"user": "Foydalanuvchi ilovasi", "seller": "Sotuvchi ilovasi"}
FILENAME_RE = re.compile(r"^fargonam-(user|seller)-(?P<version>.+)\.apk$")


def _find_apk(kind: str) -> tuple[str, str, datetime] | None:
    """`kind` ('user'/'seller') uchun eng so'nggi APK faylini topadi.

    Returns (fayl_yo'li, versiya, build_vaqti) yoki topilmasa None.
    """
    candidates = []
    for path in glob.glob(os.path.join(APK_DIR, f"fargonam-{kind}-*.apk")):
        match = FILENAME_RE.match(os.path.basename(path))
        if match:
            candidates.append((path, match.group("version"), datetime.fromtimestamp(os.path.getmtime(path))))
    if not candidates:
        return None
    return max(candidates, key=lambda c: c[2])


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if context.args:
        # "/start <session_id>" — bu login deep-link, APK bot emas,
        # auth oqimi javob berishi kerak.
        if AUTH_WEBHOOK_URL is None:
            logger.warning("TELEGRAM_WEBHOOK_SECRET sozlanmagan — login deep-link tashlab yuborildi")
            return
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                await client.post(AUTH_WEBHOOK_URL, json=update.to_dict())
        except httpx.HTTPError:
            logger.exception("Login update'ni backend'ga uzatib bo'lmadi")
        return

    keyboard = InlineKeyboardMarkup(
        [
            [InlineKeyboardButton("Foydalanuvchi ilovasi", callback_data="apk:user")],
            [InlineKeyboardButton("Sotuvchi ilovasi", callback_data="apk:seller")],
        ]
    )
    await update.message.reply_text(
        "Assalomu alaykum! Fargonam ilovasini shu yerdan yuklab olishingiz mumkin.",
        reply_markup=keyboard,
    )


async def send_apk(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()
    kind = query.data.removeprefix("apk:")
    found = _find_apk(kind)
    if found is None:
        await query.message.reply_text(
            f"{APP_LABELS[kind]} uchun hali APK build qilinmagan. Birozdan so'ng qaytadan urinib ko'ring."
        )
        return

    path, version, _built_at = found
    size = os.path.getsize(path)
    if size > MAX_TELEGRAM_FILE:
        await query.message.reply_text(
            f"{APP_LABELS[kind]} fayli ({size // (1024 * 1024)} MB) Telegram orqali yuborish uchun juda katta.\n"
            "Fargonam.uz saytidan to'g'ridan-to'g'ri yuklab oling."
        )
        return

    caption = (
        f"{APP_LABELS[kind]} — versiya {version}\n\n"
        "Sozlamalar → Xavfsizlik → Noma'lum manbalarga ruxsat bering"
    )
    with open(path, "rb") as apk_file:
        await query.message.reply_document(document=apk_file, filename=os.path.basename(path), caption=caption)


async def versiya(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    lines = []
    for kind, label in APP_LABELS.items():
        found = _find_apk(kind)
        if found is None:
            lines.append(f"{label}: hali build qilinmagan")
        else:
            _path, version, built_at = found
            lines.append(f"{label}: {version} ({built_at.strftime('%Y-%m-%d %H:%M')})")
    await update.message.reply_text("\n".join(lines))


def main() -> None:
    application = Application.builder().token(BOT_TOKEN).build()
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("versiya", versiya))
    application.add_handler(CallbackQueryHandler(send_apk, pattern=r"^apk:"))
    logger.info("Fargonam APK bot ishga tushdi (APK_DIR=%s)", APK_DIR)
    application.run_polling(drop_pending_updates=True, allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
