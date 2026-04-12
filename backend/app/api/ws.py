"""WebSocket endpointlar — real-time chat va taksi tracking."""
import asyncio
import json
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt

from app.core.config import settings

router = APIRouter(tags=["websocket"])

# ── Ulangan foydalanuvchilar ────────────────────────────────
# user_id -> set[WebSocket]
_chat_connections: dict[int, set[WebSocket]] = {}
# ride_id -> set[WebSocket]
_ride_connections: dict[int, set[WebSocket]] = {}


def _verify_token(token: str) -> int | None:
    """JWT tokendan user_id olish — faqat access token qabul qilinadi."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        # Refresh token bilan ulanishga ruxsat yo'q
        if payload.get("type") != "access":
            return None
        user_id = payload.get("sub")
        return int(user_id) if user_id else None
    except (JWTError, ValueError):
        return None


async def _broadcast_to_user(user_id: int, data: dict[str, Any]) -> None:
    """Berilgan foydalanuvchiga xabar yuborish."""
    conns = _chat_connections.get(user_id, set())
    dead = set()
    for ws in conns:
        try:
            await ws.send_json(data)
        except Exception:
            dead.add(ws)
    conns -= dead


async def notify_user(user_id: int, event_type: str, payload: dict[str, Any]) -> None:
    """Foydalanuvchiga real-time event yuborish.

    Ishlatiladigan joylarida (orders, notifications, rides) chaqiriladi.
    Agar foydalanuvchi ulangan bo'lmasa, jimgina o'tib ketadi
    (push notification alohida yuboriladi).

    Example:
        await notify_user(user_id, 'order_status', {
            'order_id': 5,
            'status': 'shipped',
            'message': 'Buyurtmangiz yo\\'lga chiqdi!'
        })
    """
    await _broadcast_to_user(user_id, {
        "type": event_type,
        **payload,
    })


async def _broadcast_to_ride(ride_id: int, data: dict[str, Any]) -> None:
    """Berilgan sayohatdagi barcha ulangan foydalanuvchilarga yuborish."""
    conns = _ride_connections.get(ride_id, set())
    dead = set()
    for ws in conns:
        try:
            await ws.send_json(data)
        except Exception:
            dead.add(ws)
    conns -= dead


# ── Chat WebSocket ──────────────────────────────────────────

@router.websocket("/ws/chat")
async def chat_ws(websocket: WebSocket):
    """
    Chat WebSocket.
    Ulanish: ws://host/ws/chat?token=JWT_TOKEN
    Xabar yuborish: {"type": "message", "receiver_id": 123, "text": "Salom"}
    Xabar olish: {"type": "message", "sender_id": 1, "text": "...", "created_at": "..."}
    """
    token = websocket.query_params.get("token")
    user_id = _verify_token(token) if token else None
    if user_id is None:
        await websocket.close(code=4001, reason="Noto'g'ri token")
        return

    await websocket.accept()
    _chat_connections.setdefault(user_id, set()).add(websocket)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "message":
                receiver_id = data.get("receiver_id")
                text = data.get("text", "")
                if receiver_id and text:
                    # DB'ga saqlash (lazy import)
                    from app.db.session import AsyncSessionLocal as async_session
                    from app.models.message import Message

                    async with async_session() as db:
                        msg = Message(
                            sender_id=user_id,
                            receiver_id=receiver_id,
                            text=text,
                        )
                        db.add(msg)
                        await db.commit()
                        await db.refresh(msg)

                        outgoing = {
                            "type": "message",
                            "id": msg.id,
                            "sender_id": user_id,
                            "receiver_id": receiver_id,
                            "text": text,
                            "created_at": msg.created_at.isoformat(),
                        }
                        # Qabul qiluvchiga yuborish
                        await _broadcast_to_user(receiver_id, outgoing)
                        # Yuboruvchiga tasdiqlash
                        await websocket.send_json({**outgoing, "is_mine": True})

            elif msg_type == "typing":
                receiver_id = data.get("receiver_id")
                if receiver_id:
                    await _broadcast_to_user(receiver_id, {
                        "type": "typing",
                        "sender_id": user_id,
                    })

    except WebSocketDisconnect:
        pass
    finally:
        _chat_connections.get(user_id, set()).discard(websocket)


# ── Ride Tracking WebSocket ─────────────────────────────────

@router.websocket("/ws/ride/{ride_id}")
async def ride_ws(websocket: WebSocket, ride_id: int):
    """Sayohat kuzatish — faqat yo'lovchi yoki haydovchi ulana oladi."""
    token = websocket.query_params.get("token")
    user_id = _verify_token(token) if token else None
    if user_id is None:
        await websocket.close(code=4001, reason="Noto'g'ri token")
        return

    # Ride ownership tekshiruvi
    from app.db.session import AsyncSessionLocal
    from app.models.ride import Ride
    async with AsyncSessionLocal() as db:
        ride = await db.get(Ride, ride_id)
        if not ride or (ride.passenger_id != user_id and ride.driver_id != user_id):
            await websocket.close(code=4003, reason="Bu sayohatga ruxsat yo'q")
            return

    await websocket.accept()
    _ride_connections.setdefault(ride_id, set()).add(websocket)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "location":
                # Haydovchi joylashuvini barcha kuzatuvchilarga yuborish
                await _broadcast_to_ride(ride_id, {
                    "type": "location",
                    "lat": data.get("lat"),
                    "lng": data.get("lng"),
                    "user_id": user_id,
                })

            elif msg_type == "status":
                # Status o'zgarishini yuborish
                await _broadcast_to_ride(ride_id, {
                    "type": "status",
                    "status": data.get("status"),
                    "user_id": user_id,
                })

    except WebSocketDisconnect:
        pass
    finally:
        _ride_connections.get(ride_id, set()).discard(websocket)
