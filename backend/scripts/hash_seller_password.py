"""
/dokon (sotuvchi web paneli) uchun parol hash generatsiya qilish.

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.hash_seller_password yangi_parol

Ikkita qator chiqadi — qaysi joyga qaysi birini yozish kerak pastda
aniq yozilgan. Sabab: docker-compose serverdagi ROOT .env faylini
o'qiyotganda "$so'z" ko'rinishidagi qismlarni o'zgaruvchi deb tushunib,
aniqlanmasa jimgina bo'sh qatorga almashtiradi — bcrypt hash tarkibida
bunday qismlar tasodifan chiqib qolishi mumkin (masalan "$jE0l5lt"),
va login har doim 500 xato bilan tushib ketadi. Shu holatni oldini
olish uchun har "$" "$$" qilib ikki marta yozilgan versiya kerak
(faqat ROOT .env uchun — lokal backend/.env uchun emas).
"""
import sys

from app.core.security import hash_password


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Foydalanish: python -m scripts.hash_seller_password <yangi_parol>")
        sys.exit(1)
    plain_hash = hash_password(sys.argv[1])
    escaped_hash = plain_hash.replace("$", "$$")
    print(f"Lokal backend/.env uchun (o'zgarishsiz):\n  SELLER_PASSWORD_HASH={plain_hash}\n")
    print(f"Serverdagi ROOT .env uchun (docker-compose, $ -> $$):\n  SELLER_PASSWORD_HASH={escaped_hash}")
