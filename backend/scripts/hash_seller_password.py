"""
/dokon (sotuvchi web paneli) uchun parol hash generatsiya qilish.

Ishlatish:
    cd ~/fargonam/backend
    .venv/bin/python -m scripts.hash_seller_password yangi_parol

Chiqqan qiymatni serverdagi .env faylida SELLER_PASSWORD_HASH= ga yozib,
backend konteynerini qayta ishga tushirish kerak
(docker compose -f docker-compose.prod.yml up -d --build backend).
"""
import sys

from app.core.security import hash_password


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Foydalanish: python -m scripts.hash_seller_password <yangi_parol>")
        sys.exit(1)
    print(hash_password(sys.argv[1]))
