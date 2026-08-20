"""
Xavfsizlik middleware'lari — OWASP tavsiyalariga asosan.
- Security headers (X-Frame-Options, HSTS, CSP va boshqalar)
- Rate limiting (slowapi)
- Global exception handler
"""
import logging

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import settings

logger = logging.getLogger("fargonam.security")


# ── Rate Limiter ──────────────────────────────────────────────
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"],
    storage_uri=settings.REDIS_URL,
)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Har bir javobga xavfsizlik headerlarini qo'shadi."""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        # Clickjacking himoyasi
        response.headers["X-Frame-Options"] = "DENY"

        # MIME sniffing himoyasi
        response.headers["X-Content-Type-Options"] = "nosniff"

        # XSS filter
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # Referrer ma'lumotlarini cheklash
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # iframe, object, embed'larni bloklash (faqat o'z domendan).
        # style-src/font-src Google Fonts (Figtree, admin_web) uchun kengaytirilgan —
        # mobil ilovaga ta'sir yo'q (Flutter CSP'ni umuman o'qimaydi).
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
            "font-src 'self' https://fonts.gstatic.com; "
            "img-src 'self' data:; "
            "frame-ancestors 'none'"
        )

        # Permissions-Policy — keraksiz API'larni o'chirish
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=(self), payment=()"
        )

        # HTTPS bo'lganda HSTS
        if not settings.DEBUG:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )

        return response


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Kutilmagan xatolarni ushlaydi — ichki tafsilotlarni yashiradi."""
    logger.exception("Kutilmagan xato: %s %s", request.method, request.url.path)

    # DEBUG rejimda batafsil xato
    if settings.DEBUG:
        detail = str(exc)
    else:
        detail = "Ichki server xatosi"

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": detail},
    )


def setup_security(app: FastAPI) -> None:
    """Barcha security middleware'larni ilovaga ulaydi."""
    # Security headers
    app.add_middleware(SecurityHeadersMiddleware)

    # Rate limiting
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # Global exception handler — 500 xatolar uchun
    app.add_exception_handler(Exception, global_exception_handler)
