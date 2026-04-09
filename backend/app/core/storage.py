"""
Lokal disk faylga saqlash yordamchilari.
Keyinchalik S3/MinIO ga oson ko'chirish uchun bitta joyda turadi.
"""
from pathlib import Path

# backend/ ildizidan boshlab uploads/
UPLOAD_ROOT = Path(__file__).resolve().parents[2] / "uploads"
PRODUCTS_DIR = UPLOAD_ROOT / "products"
PUBLIC_PREFIX = "/static"  # FastAPI mount path


def ensure_dirs() -> None:
    PRODUCTS_DIR.mkdir(parents=True, exist_ok=True)


def public_url(relative_path: str) -> str:
    """Disk yo'lini public URL'ga o'giradi.
    relative_path — UPLOAD_ROOT'ga nisbatan, masalan 'products/abc.jpg'.
    """
    return f"{PUBLIC_PREFIX}/{relative_path.lstrip('/')}"
