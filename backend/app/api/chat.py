"""Chat endpointlar — xabar yuborish va o'qish."""
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import or_, select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.middleware import limiter
from app.core.push import notify_new_message
from app.db.session import get_db
from app.models.message import Message
from app.models.user import User

router = APIRouter(prefix="/chat", tags=["chat"])


class MessageSend(BaseModel):
    receiver_id: int
    text: str = Field(min_length=1, max_length=2000)
    context_type: str | None = None  # "order" yoki "ride"
    context_id: int | None = None


@router.get("/conversations")
async def my_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchining barcha suhbatlari (oxirgi xabar bilan)."""
    msgs = (await db.scalars(
        select(Message).where(
            or_(Message.sender_id == current_user.id, Message.receiver_id == current_user.id)
        ).order_by(Message.id.desc())
    )).all()

    # Har bir suhbatdosh uchun oxirgi xabar
    seen = set()
    convos = []
    for m in msgs:
        other_id = m.receiver_id if m.sender_id == current_user.id else m.sender_id
        if other_id in seen:
            continue
        seen.add(other_id)
        other = await db.get(User, other_id)
        unread = await db.scalar(
            select(Message).where(
                Message.sender_id == other_id,
                Message.receiver_id == current_user.id,
                Message.is_read.is_(False),
            )
        )
        convos.append({
            "user_id": other_id,
            "user_name": other.full_name or other.phone if other else "Noma'lum",
            "last_message": m.text[:100],
            "last_time": m.created_at.isoformat(),
            "has_unread": unread is not None,
        })
    return convos


@router.get("/messages/{user_id}")
async def get_messages(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=50, le=200),
):
    """Ikki foydalanuvchi orasidagi xabarlar."""
    msgs = (await db.scalars(
        select(Message).where(
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == user_id),
                and_(Message.sender_id == user_id, Message.receiver_id == current_user.id),
            )
        ).order_by(Message.id.desc()).limit(limit)
    )).all()

    # O'qilmagan xabarlarni o'qilgan deb belgilash
    for m in msgs:
        if m.receiver_id == current_user.id and not m.is_read:
            m.is_read = True
    await db.commit()

    return [
        {
            "id": m.id,
            "sender_id": m.sender_id,
            "text": m.text,
            "is_mine": m.sender_id == current_user.id,
            "is_read": m.is_read,
            "created_at": m.created_at.isoformat(),
        }
        for m in reversed(msgs)
    ]


@router.post("/send", status_code=status.HTTP_201_CREATED)
@limiter.limit("30/minute")
async def send_message(
    request: Request,
    payload: MessageSend,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    receiver = await db.get(User, payload.receiver_id)
    if not receiver:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    msg = Message(
        sender_id=current_user.id,
        receiver_id=payload.receiver_id,
        text=payload.text,
        context_type=payload.context_type,
        context_id=payload.context_id,
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)
    # Push notification
    sender_name = current_user.full_name or current_user.phone
    await notify_new_message(payload.receiver_id, sender_name)

    return {"id": msg.id, "text": msg.text, "created_at": msg.created_at.isoformat()}
