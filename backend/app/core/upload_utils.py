"""Fayl yuklash uchun umumiy tekshiruvlar — magic bytes, hajm."""

# Fayl boshidagi baytlardan haqiqiy formatni aniqlash
_MAGIC_BYTES = {
    b"\xff\xd8\xff": ".jpg",
    b"\x89PNG\r\n\x1a\n": ".png",
    b"RIFF": ".webp",
}


def validate_image(contents: bytes, max_bytes: int = 5 * 1024 * 1024) -> str:
    """
    Rasm faylni tekshiradi.
    Qaytaradi: fayl kengaytmasi (.jpg, .png, .webp)
    Xato bo'lsa: ValueError tashlaydi
    """
    if not contents:
        raise ValueError("Bo'sh fayl")
    if len(contents) > max_bytes:
        raise ValueError(f"Fayl {max_bytes // 1024 // 1024}MB dan katta")

    for magic, ext in _MAGIC_BYTES.items():
        if contents[:len(magic)] == magic:
            if ext == ".webp" and contents[8:12] != b"WEBP":
                continue
            return ext

    raise ValueError("Fayl haqiqiy rasm emas (JPEG, PNG yoki WebP kerak)")
