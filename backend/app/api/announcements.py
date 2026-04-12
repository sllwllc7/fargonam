"""E'lonlar API — admin yaratadi, hamma ko'radi."""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.push import send_push_to_user
from app.db.session import get_db
from app.models.announcement import Announcement
from app.models.user import User

router = APIRouter(prefix="/announcements", tags=["announcements"])


class AnnouncementCreate(BaseModel):
    title: str = Field(max_length=300)
    body: str = Field(max_length=5000)
    type: str = Field(default="info", pattern=r"^(info|event|emergency|promo)$")
    priority: str = Field(default="normal", pattern=r"^(normal|important|urgent)$")
    event_date: str | None = None


@router.get("")
async def list_announcements(
    db: AsyncSession = Depends(get_db),
    limit: int = Query(default=20, le=100),
):
    """Faol e'lonlar (auth kerak emas)."""
    rows = (await db.scalars(
        select(Announcement)
        .where(Announcement.is_active.is_(True))
        .order_by(Announcement.id.desc())
        .limit(limit)
    )).all()
    return [
        {
            "id": a.id,
            "title": a.title,
            "body": a.body,
            "type": a.type,
            "priority": a.priority,
            "event_date": a.event_date.isoformat() if a.event_date else None,
            "created_at": a.created_at.isoformat(),
        }
        for a in rows
    ]


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_announcement(
    payload: AnnouncementCreate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin e'lon yaratadi. Urgent bo'lsa — barcha userlarga push yuboradi."""
    from datetime import datetime
    event_dt = None
    if payload.event_date:
        try:
            event_dt = datetime.fromisoformat(payload.event_date)
        except ValueError:
            pass

    ann = Announcement(
        author_id=admin.id,
        title=payload.title,
        body=payload.body,
        type=payload.type,
        priority=payload.priority,
        event_date=event_dt,
    )
    db.add(ann)
    await db.commit()
    await db.refresh(ann)

    # Urgent bo'lsa — barcha userlarga push
    if payload.priority == "urgent":
        from app.models.user import User as UserModel
        user_ids = (await db.scalars(select(UserModel.id).where(UserModel.is_active.is_(True)))).all()
        for uid in user_ids:
            await send_push_to_user(uid, f"⚠️ {payload.title}", payload.body, data={"type": "system"})

    return {"id": ann.id, "title": ann.title}
