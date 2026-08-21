"""
Fayl saqlash — lokal disk yoki S3/MinIO.
S3_ENDPOINT o'rnatilgan bo'lsa S3 ishlatadi, aks holda lokal disk.
"""
import logging
from io import BytesIO
from pathlib import Path

from app.core.config import settings

logger = logging.getLogger(__name__)

# ── Lokal disk sozlamalari ──────────────────────────────────
UPLOAD_ROOT = Path(__file__).resolve().parents[2] / "uploads"
PRODUCTS_DIR = UPLOAD_ROOT / "products"
CATEGORIES_DIR = UPLOAD_ROOT / "categories"
PUBLIC_PREFIX = "/static"

# ── S3 client (lazy init) ──────────────────────────────────
_s3_client = None
_use_s3 = bool(settings.S3_ENDPOINT and settings.S3_ACCESS_KEY and settings.S3_SECRET_KEY)


def _get_s3():
    """S3 client'ni lazy yaratish."""
    global _s3_client
    if _s3_client is not None:
        return _s3_client

    try:
        import boto3
        _s3_client = boto3.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT,
            aws_access_key_id=settings.S3_ACCESS_KEY,
            aws_secret_access_key=settings.S3_SECRET_KEY,
            region_name="us-east-1",
        )
        # Bucket yaratish (agar yo'q bo'lsa)
        try:
            _s3_client.head_bucket(Bucket=settings.S3_BUCKET)
        except Exception:
            _s3_client.create_bucket(Bucket=settings.S3_BUCKET)
            # Public o'qish uchun policy
            import json
            policy = {
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": ["s3:GetObject"],
                    "Resource": [f"arn:aws:s3:::{settings.S3_BUCKET}/*"],
                }],
            }
            _s3_client.put_bucket_policy(
                Bucket=settings.S3_BUCKET,
                Policy=json.dumps(policy),
            )
        logger.info(f"S3 storage ulandi: {settings.S3_ENDPOINT}/{settings.S3_BUCKET}")
        return _s3_client
    except ImportError:
        logger.warning("boto3 o'rnatilmagan, lokal storage ishlatiladi")
        return None
    except Exception as e:
        logger.warning(f"S3 ulanishda xato: {e}, lokal storage ishlatiladi")
        return None


def ensure_dirs() -> None:
    """Lokal papkalarni yaratish."""
    PRODUCTS_DIR.mkdir(parents=True, exist_ok=True)
    CATEGORIES_DIR.mkdir(parents=True, exist_ok=True)
    (UPLOAD_ROOT / "avatars").mkdir(parents=True, exist_ok=True)
    (UPLOAD_ROOT / "news").mkdir(parents=True, exist_ok=True)
    (UPLOAD_ROOT / "banners").mkdir(parents=True, exist_ok=True)


def save_file(relative_path: str, data: bytes, content_type: str = "image/jpeg") -> str:
    """
    Faylni saqlash — S3 yoki lokal.
    relative_path: masalan 'products/abc.jpg'
    Qaytaradi: public URL
    """
    if _use_s3:
        client = _get_s3()
        if client:
            try:
                client.upload_fileobj(
                    BytesIO(data),
                    settings.S3_BUCKET,
                    relative_path,
                    ExtraArgs={"ContentType": content_type},
                )
                return s3_public_url(relative_path)
            except Exception as e:
                logger.error(f"S3 yuklashda xato: {e}, lokal'ga yoziladi")

    # Fallback: lokal disk
    dest = UPLOAD_ROOT / relative_path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    return public_url(relative_path)


def delete_file(relative_path: str) -> None:
    """Faylni o'chirish — S3 yoki lokal."""
    if _use_s3:
        client = _get_s3()
        if client:
            try:
                client.delete_object(Bucket=settings.S3_BUCKET, Key=relative_path)
                return
            except Exception as e:
                logger.error(f"S3 o'chirishda xato: {e}")

    # Fallback: lokal
    path = UPLOAD_ROOT / relative_path
    try:
        path.unlink(missing_ok=True)
    except OSError:
        pass


def public_url(relative_path: str) -> str:
    """Lokal disk — public URL."""
    return f"{PUBLIC_PREFIX}/{relative_path.lstrip('/')}"


def s3_public_url(relative_path: str) -> str:
    """S3 — public URL."""
    if settings.S3_PUBLIC_URL:
        return f"{settings.S3_PUBLIC_URL.rstrip('/')}/{relative_path.lstrip('/')}"
    return f"{settings.S3_ENDPOINT}/{settings.S3_BUCKET}/{relative_path}"
