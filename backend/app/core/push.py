"""
Firebase Cloud Messaging v1 API orqali push notification yuborish.

Service Account JSON kerak:
  - firebase_credentials.json ni backend/ papkasiga qo'ying
  - yoki FIREBASE_CREDENTIALS env o'zgaruvchisida yo'lini ko'rsating
"""
import json
import logging
from pathlib import Path

import google.auth.transport.requests
from google.oauth2 import service_account
import httpx

logger = logging.getLogger(__name__)

# ── Firebase sozlamalari ────────────────────────────────────
_credentials = None
_project_id: str | None = None
_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"


def _init_firebase() -> bool:
    """Service account credentials'ni yuklash va OAuth2 token olish."""
    global _credentials, _project_id

    if _credentials is not None:
        return True

    # Credentials faylini topish
    cred_path = None

    # 1. Env orqali
    from app.core.config import settings
    if settings.FIREBASE_CREDENTIALS:
        cred_path = settings.FIREBASE_CREDENTIALS

    # 2. Default fayl
    if not cred_path:
        default = Path(__file__).resolve().parents[2] / "firebase_credentials.json"
        if default.exists():
            cred_path = str(default)

    if not cred_path or not Path(cred_path).exists():
        logger.warning("Firebase credentials topilmadi. Push notification ishlamaydi.")
        return False

    try:
        _credentials = service_account.Credentials.from_service_account_file(
            cred_path,
            scopes=[_FCM_SCOPE],
        )
        with open(cred_path) as f:
            _project_id = json.load(f).get("project_id")

        logger.info(f"Firebase initialized: project={_project_id}")
        return True
    except Exception as e:
        logger.error(f"Firebase credentials yuklashda xato: {e}")
        return False


async def _get_access_token() -> str | None:
    """OAuth2 access token olish (blocking call'ni threadpool'da bajarish)."""
    if not _init_firebase():
        return None

    import asyncio
    try:
        # Blocking HTTP call'ni event loop'ni bloklamamaslik uchun threadpool'da bajarish
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(
            None,
            lambda: _credentials.refresh(google.auth.transport.requests.Request()),
        )
        return _credentials.token
    except Exception as e:
        logger.error(f"Firebase access token olishda xato: {e}")
        return None


async def send_push(token: str, title: str, body: str, data: dict | None = None) -> bool:
    """
    FCM v1 API orqali bitta qurilmaga push yuborish.
    """
    access_token = await _get_access_token()
    if not access_token or not _project_id:
        logger.warning(f"Push yuborilmadi (credentials yo'q): {title}")
        return False

    url = f"https://fcm.googleapis.com/v1/projects/{_project_id}/messages:send"

    message = {
        "message": {
            "token": token,
            "notification": {
                "title": title,
                "body": body,
            },
            "android": {
                "priority": "high",
                "notification": {
                    "sound": "default",
                    "channel_id": "fargonam_default",
                },
            },
        }
    }

    if data:
        message["message"]["data"] = {k: str(v) for k, v in data.items()}

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                url,
                json=message,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                timeout=10,
            )
            if resp.status_code == 200:
                logger.info(f"Push yuborildi: {title} -> {token[:20]}...")
                return True
            else:
                error_data = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else resp.text
                logger.warning(f"FCM v1 xato [{resp.status_code}]: {error_data}")

                # Token yaroqsiz — o'chirish kerak
                if resp.status_code == 404 or (resp.status_code == 400 and "UNREGISTERED" in str(error_data)):
                    await _remove_invalid_token(token)

    except Exception as e:
        logger.error(f"FCM yuborishda xato: {e}")

    return False


async def _remove_invalid_token(token: str) -> None:
    """Yaroqsiz FCM tokenni bazadan o'chirish."""
    try:
        from app.db.session import AsyncSessionLocal
        from app.models.fcm_token import FcmToken
        from sqlalchemy import select

        async with AsyncSessionLocal() as db:
            existing = await db.scalar(select(FcmToken).where(FcmToken.token == token))
            if existing:
                await db.delete(existing)
                await db.commit()
                logger.info(f"Yaroqsiz FCM token o'chirildi: {token[:20]}...")
    except Exception as e:
        logger.error(f"Token o'chirishda xato: {e}")


async def send_push_to_user(user_id: int, title: str, body: str, data: dict | None = None) -> int:
    """
    Foydalanuvchining barcha qurilmalariga push yuborish.
    Muvaffaqiyatli yuborilganlar sonini qaytaradi.
    """
    from app.db.session import AsyncSessionLocal
    from app.models.fcm_token import FcmToken
    from sqlalchemy import select

    async with AsyncSessionLocal() as db:
        tokens = (await db.scalars(
            select(FcmToken).where(FcmToken.user_id == user_id)
        )).all()

    sent = 0
    for t in tokens:
        if await send_push(t.token, title, body, data):
            sent += 1
    return sent


# ── Tayyor notification funksiyalari ────────────────────────

async def notify_order_status(user_id: int, order_id: int, status: str) -> None:
    """Buyurtma holati o'zgarganda push yuborish."""
    labels = {
        "paid": "To'landi ✓",
        "shipped": "Yo'lga chiqdi 🚚",
        "delivered": "Yetkazildi ✓",
        "cancelled": "Bekor qilindi ✗",
    }
    label = labels.get(status, status)
    await send_push_to_user(
        user_id,
        f"Buyurtma #{order_id}",
        label,
        data={"type": "order", "order_id": str(order_id)},
    )


async def notify_new_message(user_id: int, sender_name: str) -> None:
    """Yangi xabar kelganda push yuborish."""
    await send_push_to_user(
        user_id,
        "Yangi xabar 💬",
        f"{sender_name} sizga yozdi",
        data={"type": "chat"},
    )


async def notify_ride_status(user_id: int, ride_id: int, status: str) -> None:
    """Sayohat holati o'zgarganda push yuborish."""
    labels = {
        "accepted": "Haydovchi topildi! 🚕",
        "arrived": "Haydovchi yetib keldi! 📍",
        "in_progress": "Sayohat boshlandi",
        "completed": "Sayohat tugadi ✓",
        "cancelled": "Sayohat bekor qilindi",
    }
    label = labels.get(status, status)
    await send_push_to_user(
        user_id,
        "Fargonam Taxi",
        label,
        data={"type": "ride", "ride_id": str(ride_id)},
    )


async def notify_new_order(seller_user_id: int, order_id: int) -> None:
    """Sotuvchiga yangi buyurtma kelganda push yuborish."""
    await send_push_to_user(
        seller_user_id,
        "Yangi buyurtma! 🛒",
        f"Buyurtma #{order_id} keldi",
        data={"type": "seller_order", "order_id": str(order_id)},
    )
