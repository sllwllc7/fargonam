"""Yuklangan mahsulot rasmini qayta ishlash: max o'lcham, siqish, kvadrat preview.

Sotuvchi telefondan yuklagan xom rasm katta bo'lishi mumkin (bir necha MB,
4000px+, EXIF orientatsiyasi bilan) — bu yerda bitta joyda hal qilinadi,
har bir yuklash endpointi qayta yozmaydi.
"""
import io

from PIL import Image, ImageOps, UnidentifiedImageError

MAX_DIMENSION = 1200
THUMB_SIZE = 400
JPEG_QUALITY = 85


def process_product_image(contents: bytes) -> tuple[bytes, bytes]:
    """Qaytaradi: (asosiy_rasm_bytes, kvadrat_preview_bytes) — ikkalasi ham JPEG.

    Xato bo'lsa (buzilgan yoki dekodlab bo'lmaydigan fayl): ValueError.
    """
    try:
        img = Image.open(io.BytesIO(contents))
        img.load()
    except (UnidentifiedImageError, OSError):
        raise ValueError("Fayl haqiqiy rasm emas yoki buzilgan")

    img = ImageOps.exif_transpose(img)
    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")
    elif img.mode == "L":
        img = img.convert("RGB")

    img.thumbnail((MAX_DIMENSION, MAX_DIMENSION), Image.LANCZOS)
    main_buf = io.BytesIO()
    img.save(main_buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)

    width, height = img.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    square = img.crop((left, top, left + side, top + side))
    square = square.resize((THUMB_SIZE, THUMB_SIZE), Image.LANCZOS)
    thumb_buf = io.BytesIO()
    square.save(thumb_buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)

    return main_buf.getvalue(), thumb_buf.getvalue()
