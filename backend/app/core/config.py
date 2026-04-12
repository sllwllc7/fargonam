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
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
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

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )


# Bitta umumiy instance — boshqa modullar shu ni import qiladi
settings = Settings()
