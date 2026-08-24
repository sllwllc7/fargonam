"""
Ilova sozlamalari — .env faylidan o'qiladi.
Pydantic Settings xato qiymatlarni avtomatik tekshiradi.
"""
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str

    # Redis
    REDIS_URL: str

    # JWT
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15      # qisqa — Dio interceptor 401'da avtomatik yangilaydi
    REFRESH_TOKEN_EXPIRE_DAYS: int = 90        # 3 oy
    JWT_ALGORITHM: str = "HS256"

    # App
    DEBUG: bool = False

    # Security — CORS uchun ruxsat etilgan domenlar
    # .env da vergul bilan ajratilgan ro'yxat: ALLOWED_ORIGINS=http://localhost:3000,http://example.com
    ALLOWED_ORIGINS: str = ""

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Firebase push
    FCM_SERVER_KEY: str = ""
    FIREBASE_CREDENTIALS: str = ""

    # S3/MinIO storage
    S3_ENDPOINT: str = ""
    S3_ACCESS_KEY: str = ""
    S3_SECRET_KEY: str = ""
    S3_BUCKET: str = "fargonam"
    S3_PUBLIC_URL: str = ""  # Public URL prefix for files

    # Telegram login (mobile_user) — BotFather'dan olinadi
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_BOT_USERNAME: str = ""  # @ belgisiz, masalan: fargonam_login_bot
    TELEGRAM_WEBHOOK_SECRET: str = ""
    # /miniapp (Telegram Mini App) sinovi uchun alohida bot — bo'sh bo'lsa
    # TELEGRAM_BOT_TOKEN ishlatiladi. Asosiy login bot'idan mustaqil, shu
    # sababli sinov paytida fargonam_bot login oqimiga ta'sir qilmaydi.
    TELEGRAM_MINIAPP_BOT_TOKEN: str = ""
    # Mini App'ning o'zi ochiladigan HTTPS manzili — bot xabarlaridagi
    # WebApp tugmasi va setChatMenuButton shu URL'ga ishora qiladi.
    MINIAPP_URL: str = "https://api.fargonam.uz/miniapp/"
    # true = long-polling (ochiq HTTPS domen shart emas, lokal dev uchun).
    # false = webhook (production, domen kerak).
    TELEGRAM_USE_POLLING: bool = False
    # Admin huquqi avtomatik beriladigan Telegram foydalanuvchi ID'lari
    # (username emas, raqamli ID — @userinfobot orqali olinadi). Vergul bilan
    # ajratilgan ro'yxat: ADMIN_TELEGRAM_IDS=123456789,987654321
    ADMIN_TELEGRAM_IDS: str = ""

    # Sotuvchi web paneli (/dokon) — oddiy umumiy login/parol, Telegram/OTP
    # emas (2026-08-20: mobile_seller ilovasi to'xtatilib shu bilan
    # almashtirildi). SELLER_PASSWORD_HASH — ochiq parol emas, bcrypt hash
    # (backend/scripts/hash_password.py bilan generatsiya qilinadi).
    SELLER_LOGIN: str = ""
    SELLER_PASSWORD_HASH: str = ""

    # Admin web paneli (/admin-web) — 2026-08-21: Telegram login o'rniga
    # oddiy umumiy login/parol (foydalanuvchining o'z tanlovi bilan, bitta
    # egasi bo'lgan panel uchun). ADMIN_WEB_PASSWORD_HASH — bcrypt hash
    # (backend/scripts/hash_seller_password.py bilan generatsiya qilinadi,
    # xuddi shu skript ishlatiladi — ikkalasi ham bir xil hash_password()).
    ADMIN_WEB_LOGIN: str = ""
    ADMIN_WEB_PASSWORD_HASH: str = ""

    @field_validator("SECRET_KEY")
    @classmethod
    def secret_key_must_be_strong(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("SECRET_KEY kamida 32 belgi bo'lishi kerak")
        return v

    @property
    def cors_origins(self) -> list[str]:
        """ALLOWED_ORIGINS ni list ga aylantiradi."""
        if not self.ALLOWED_ORIGINS:
            return []
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    @property
    def admin_telegram_ids(self) -> set[str]:
        """ADMIN_TELEGRAM_IDS ni set ga aylantiradi."""
        if not self.ADMIN_TELEGRAM_IDS:
            return set()
        return {s.strip() for s in self.ADMIN_TELEGRAM_IDS.split(",") if s.strip()}

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


# Bitta umumiy instance — boshqa modullar shu ni import qiladi
settings = Settings()
