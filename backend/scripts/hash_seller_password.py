"""
/dokon va /admin-web statik login/parol uchun bcrypt hash generatsiya
qilish (ikkalasi ham shu skriptni ishlatadi).

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.hash_seller_password yangi_parol [ENV_NOMI]

ENV_NOMI ixtiyoriy — chop etilayotgan qatorlardagi kalit nomi (standart:
SELLER_PASSWORD_HASH). Admin panel uchun: ... yangi_parol ADMIN_WEB_PASSWORD_HASH

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
    if len(sys.argv) not in (2, 3):
        print("Foydalanish: python -m scripts.hash_seller_password <yangi_parol> [ENV_NOMI]")
        sys.exit(1)
    env_name = sys.argv[2] if len(sys.argv) == 3 else "SELLER_PASSWORD_HASH"
    plain_hash = hash_password(sys.argv[1])
    escaped_hash = plain_hash.replace("$", "$$")
    print(f"Lokal backend/.env uchun (o'zgarishsiz):\n  {env_name}={plain_hash}\n")
    print(f"Serverdagi ROOT .env uchun (docker-compose, $ -> $$):\n  {env_name}={escaped_hash}")
