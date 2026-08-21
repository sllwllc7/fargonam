"""/dokon — sotuvchi web paneli (oddiy HTML+JS sahifa, admin_web'dan alohida).

2026-08-20: mobile_seller ilovasi to'xtatildi (oila/do'kondagilar uchun juda
murakkab edi — rasm yuklash, mahsulot qo'shish kabi kerak bo'lmagan
funksiyalar bilan). O'rniga faqat "buyurtmalarni ko'rish va tayyorlash" uchun
juda sodda web sahifa. Kirish — umumiy login/parol (`.env`dagi SELLER_LOGIN/
SELLER_PASSWORD_HASH), Telegram/OTP emas. Sessiya cookie orqali (30 kun).

Bir nechta odam bir vaqtda ochib turishi mumkin (ko'p telefon) — "kim qaysi
buyurtmani oldi" Redis'da `dokon:claim:{order_id}` kaliti bilan atomik
saqlanadi (SET NX — birinchi bosgan g'olib chiqadi), DB modeliga yangi ustun
qo'shilmadi (bu holat vaqtinchalik — buyurtma yakunlansa/tugatilsa tozalanadi,
Order modeliga singdirish shart emas).
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Cookie, Depends, HTTPException, Request, Response, status
from jose import JWTError, jwt
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.cart import enrich_order, transition_order_status
from app.core.config import settings
from app.core.middleware import limiter
from app.core.redis_client import get_redis
from app.core.security import verify_password
from app.db.session import get_db
from app.models.order import Order, OrderStatus

router = APIRouter(prefix="/dokon-api", tags=["dokon"])

COOKIE_NAME = "dokon_session"
SESSION_DAYS = 30
_CLAIM_PREFIX = "dokon:claim:"
_CLAIM_TTL = 60 * 60 * 24 * 2  # 2 kun — buyurtma yopilganda ham tozalanadi, bu faqat zaxira

STATUS_FILTERS = {
    "pending": OrderStatus.pending,
    "preparing": OrderStatus.preparing,
    "ready": OrderStatus.ready,
    "shipped": OrderStatus.shipped,
    "delivered": OrderStatus.delivered,
    "cancelled": OrderStatus.cancelled,
}


class LoginRequest(BaseModel):
    login: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=1, max_length=200)


class NameRequest(BaseModel):
    name: str = Field(min_length=1, max_length=60)


class StatusRequest(BaseModel):
    new_status: OrderStatus


class CancelRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=500)


def _make_token(name: str | None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=SESSION_DAYS)
    payload = {"sub": "dokon", "type": "dokon", "name": name, "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def _set_cookie(response: Response, name: str | None) -> None:
    response.set_cookie(
        key=COOKIE_NAME,
        value=_make_token(name),
        max_age=SESSION_DAYS * 86400,
        httponly=True,
        secure=True,
        samesite="lax",
        path="/",
    )


async def get_dokon_session(dokon_session: str | None = Cookie(default=None)) -> dict:
    """Cookie'ni dekod qiladi. Yaroqsiz/yo'q bo'lsa 401."""
    if not dokon_session:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Kirish talab qilinadi")
    try:
        payload = jwt.decode(dokon_session, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Sessiya tugagan, qayta kiring")
    if payload.get("type") != "dokon":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Kirish talab qilinadi")
    return payload


async def require_dokon_name(session: dict = Depends(get_dokon_session)) -> str:
    """Buyurtma bilan ishlash uchun ism kiritilgan bo'lishi shart — kim
    qaysi buyurtmani olganini bilish uchun."""
    name = session.get("name")
    if not name:
        raise HTTPException(status_code=400, detail="Avval ismingizni kiriting")
    return name


@router.post("/login")
@limiter.limit("5/minute")
async def dokon_login(request: Request, payload: LoginRequest, response: Response):
    if not settings.SELLER_LOGIN or not settings.SELLER_PASSWORD_HASH:
        raise HTTPException(status_code=503, detail="Sotuvchi paneli hali sozlanmagan")
    valid = payload.login.strip() == settings.SELLER_LOGIN and verify_password(
        payload.password, settings.SELLER_PASSWORD_HASH
    )
    if not valid:
        raise HTTPException(status_code=401, detail="Login yoki parol noto'g'ri")
    _set_cookie(response, name=None)
    return {"ok": True}


@router.post("/logout")
async def dokon_logout(response: Response):
    response.delete_cookie(COOKIE_NAME, path="/")
    return {"ok": True}


@router.get("/me")
async def dokon_me(session: dict = Depends(get_dokon_session)):
    return {"name": session.get("name")}


@router.post("/name")
async def dokon_set_name(payload: NameRequest, response: Response, session: dict = Depends(get_dokon_session)):
    name = payload.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Ism kiritilmadi")
    _set_cookie(response, name=name)
    return {"name": name}


@router.get("/orders/counts")
async def order_counts(
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.execute(
        select(Order.status, func.count(Order.id)).group_by(Order.status)
    )).all()
    counts = {s.value: 0 for s in OrderStatus}
    for st, n in rows:
        counts[st.value if hasattr(st, "value") else st] = n
    counts["all"] = sum(counts.values())
    return counts


@router.get("/orders")
async def list_orders(
    status_filter: str = "pending",
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    q = select(Order).order_by(Order.created_at.asc())
    if status_filter != "all":
        model_status = STATUS_FILTERS.get(status_filter)
        if model_status is None:
            raise HTTPException(status_code=400, detail="Noto'g'ri filtr")
        q = q.where(Order.status == model_status)
    orders = (await db.scalars(q)).all()

    redis = get_redis()
    result = []
    for o in orders:
        enriched = await enrich_order(o, db, include_phone=True)
        data = enriched.model_dump(mode="json")
        data["claimed_by"] = await redis.get(f"{_CLAIM_PREFIX}{o.id}")
        result.append(data)
    return result


@router.get("/orders/{order_id}")
async def get_order(
    order_id: int,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    order = (await db.scalars(select(Order).where(Order.id == order_id))).first()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    enriched = await enrich_order(order, db, include_phone=True)
    data = enriched.model_dump(mode="json")
    data["claimed_by"] = await get_redis().get(f"{_CLAIM_PREFIX}{order_id}")
    return data


@router.post("/orders/{order_id}/status")
async def change_status(
    order_id: int,
    payload: StatusRequest,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    order = (await db.scalars(select(Order).where(Order.id == order_id).with_for_update())).first()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    redis = get_redis()
    claim_key = f"{_CLAIM_PREFIX}{order_id}"

    # "Qabul qildim" — pending'dan preparing'ga o'tish, shu bilan birga
    # buyurtmani shu odam nomiga "band qiladi" (birinchi bosgan g'olib).
    if payload.new_status == OrderStatus.preparing:
        if order.status == OrderStatus.pending:
            claimed = await redis.set(claim_key, name, nx=True, ex=_CLAIM_TTL)
            if not claimed:
                current = await redis.get(claim_key)
                raise HTTPException(
                    status_code=409,
                    detail=f"Bu buyurtmani {current or 'boshqa xodim'} allaqachon oldi",
                )
        else:
            # Boshqa xodim orqamizdan allaqachon olib ulgurgan — status
            # o'zgargan, lekin bu so'rov hali eski (pending) ro'yxatdan
            # kelgan bo'lishi mumkin (poll oralig'i ~12s). Aniq ayt.
            current = await redis.get(claim_key)
            if current and current != name:
                raise HTTPException(status_code=409, detail=f"Bu buyurtmani {current} allaqachon oldi")

    # Qolgan holatlar (yoki noto'g'ri o'tish) uchun tekshiruv va push
    # yuborish transition_order_status ichida — bu yerda takrorlanmaydi.
    await transition_order_status(order, payload.new_status, db, actor="seller")

    if payload.new_status in (OrderStatus.delivered, OrderStatus.cancelled):
        await redis.delete(claim_key)

    enriched = await enrich_order(order, db, include_phone=True)
    data = enriched.model_dump(mode="json")
    data["claimed_by"] = await redis.get(claim_key)
    return data


@router.post("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: int,
    payload: CancelRequest,
    name: str = Depends(require_dokon_name),
    db: AsyncSession = Depends(get_db),
):
    order = (await db.scalars(select(Order).where(Order.id == order_id).with_for_update())).first()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    await transition_order_status(
        order, OrderStatus.cancelled, db, actor="seller", cancel_reason=f"{payload.reason} (bekor qildi: {name})"
    )
    await get_redis().delete(f"{_CLAIM_PREFIX}{order_id}")

    enriched = await enrich_order(order, db, include_phone=True)
    return enriched.model_dump(mode="json")
