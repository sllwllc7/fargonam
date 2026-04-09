# Fargonam — Loyiha jurnali

> Bu fayl har sessiya oxirida yangilanadi. Yangi sessiya boshlanganda Claude **birinchi navbatda shu faylni o'qiydi** va shu yerdan davom etadi. Feron'ga "qaerdan boshlaymiz?" deb so'rashga hojat yo'q.

---

## Hozirgi holat (snapshot)

**Oxirgi yangilanish**: 2026-04-09 (2-sessiya, yakuniy)
**Hozirgi bosqich**: MVP to'liq tayyor — backend + admin web + mobile_seller + mobile_user, 2 ta APK build bo'lgan.
**Hozirgi modul**: Marketplace (birinchi MVP)

### Ishlayotgan narsalar
- ✅ Loyiha tuzilishi: `~/fargonam/{backend,mobile_user,mobile_seller,admin_web,docs}`
- ✅ PostgreSQL 17 — docker `fargonam_postgres`, port 5432, user `fargonam`, parol `parol123`, db `fargonam_db`
- ✅ Redis 7 — docker `fargonam_redis`, port 6379
- ✅ Python 3.13.12 (uv, `~/fargonam/backend/.venv`)
- ✅ FastAPI + SQLAlchemy async + asyncpg + alembic + pydantic-settings + jose + passlib
- ✅ `app/core/config.py` — Pydantic Settings, .env'dan o'qiydi
- ✅ `app/db/{base,session}.py` — async engine, `get_db` dependency
- ✅ `app/models/user.py` — User (phone, hashed_password, role: buyer/seller/admin)
- ✅ Alembic sozlangan (`alembic/env.py` Base.metadata + settings.DATABASE_URL'dan oladi), users jadvali migratsiya qilindi
- ✅ `app/core/security.py` — bcrypt hash, JWT (HS256) yaratish/dekod
- ✅ `app/api/auth.py` — `POST /auth/register`, `POST /auth/login`, `GET /auth/me` (Bearer token)
- ✅ E2E test (curl): register→login→me, dublikat 409, xato parol 401
- ✅ Marketplace modellari: Shop, Category, Product, CartItem, Order, OrderItem (+ OrderStatus enum)
- ✅ Migration #2 (`9f9a99913935_marketplace_jadvallar`) qo'llanildi — DBda 8 jadval
- ✅ Marketplace API endpointlari:
  - `GET/POST /shops`, `GET /shops/{id}` (POST faqat seller/admin)
  - `GET/POST /categories` (POST faqat admin)
  - `GET/POST /products`, `GET/PATCH/DELETE /products/{id}` (egasi yoki admin)
  - `GET/POST /cart`, `DELETE /cart/{id}`
  - `POST /orders` (checkout — stock kamaytiradi, savatchani tozalaydi), `GET /orders`
- ✅ E2E test (marketplace): seller→shop→product→buyer→cart→checkout. Stock 10→8 to'g'ri. 403 (buyer shop yaratishga urinish) ham ishlaydi.
- ✅ Image upload: `POST /products/{id}/image` (multipart, jpg/png/webp, max 5MB), lokal `backend/uploads/products/`, `/static` mount, eski rasm avtomatik o'chiriladi
- ✅ `app/core/storage.py` — keyinchalik S3/MinIO ga ko'chirish uchun bitta abstraksiya
- ✅ Migration #3 — `products.image_url`
- ✅ E2E test (image): yuklash, /static orqali ochish, 403 begona, 400 noto'g'ri MIME
- ✅ `app/schemas/common.py` — generic `Page[T]` (items, total, limit, offset)
- ✅ `GET /products` kengaytirildi: `q` (ilike), `min_price`, `max_price`, `total` qaytaradi
- ✅ E2E test (search/pagination): q, narx oralig'i, ikki bet — barchasi to'g'ri
- ✅ Admin endpointlar: `GET /admin/users`, `PATCH /admin/users/{id}` (rol/holat), `GET /admin/orders`, `PATCH /admin/orders/{id}` (status), `GET /admin/stats` (revenue paid+shipped+delivered'dan)
- ✅ `require_admin` dependency (RBAC)
- ✅ `scripts/create_admin.py` — birinchi admin yaratish/o'tkazish
- ✅ Birinchi admin: phone=`+998900000000`, parol=`admin12345` (id=5)
- ✅ `admin_web/index.html` — vanilla JS + Tailwind CDN, login + 4 tab (Statistika, Kategoriyalar, Foydalanuvchilar, Buyurtmalar)
- ✅ FastAPI'da `/admin-web` mount (`/admin` API band, shuning uchun `-web` qo'shildi)
- ✅ E2E test (admin): login, stats, users qidirish, orders, RBAC (buyer 403, anonim 401), kategoriya yaratish, order status o'zgartirish, admin web HTML 200, revenue stats yangilanishi
- ✅ **Android SDK + JDK 17 sudosiz o'rnatildi**: `~/jdk17`, `~/Android/Sdk` (cmdline-tools, platform-tools, platforms;android-36, build-tools;36.0.0)
- ✅ `~/.zshrc` ga `JAVA_HOME`, `ANDROID_HOME`, `PATH` qo'shildi
- ✅ `flutter doctor` — Android toolchain ✓ (faqat Chrome web yo'q, mobile uchun muhim emas)
- ✅ Flutter 3.41.6 + Android SDK 36 + JDK 17
- ✅ mobile_seller APK + mobile_user APK build bo'lgan
- ✅ Admin web panel ishlayapti

### Hali yo'q narsalar (post-MVP)
- ❌ Multi-image, push notification, to'lov tizimi, real server deploy
- ❌ Flutter loyihalari yaratilmagan (mobile_user, mobile_seller bo'sh)
- ❌ Admin panel
- ❌ `.env` fayl (faqat `.env.example` bor)
- ❌ Domen, brending, logo

---

## Keyingi qadamlar (tartib bilan)

### 1-bosqich: Backend asoslari ✅ TUGADI
- config, db, User, Alembic, auth, marketplace modellari va endpointlar — hammasi tayyor

### Keyingi bosqich (post-MVP yaxshilashlar)
- Real serverga deploy (Oracle Cloud Free Tier rejasi bor)
- To'lov tizimi (senior dasturchi bilan)
- Push notification (buyurtma holati o'zgarganda)
- Rasmlarni optimize/compress qilish
- mobile_seller'da buyurtmalar ekrani (hozircha yo'q, faqat backend API bor)
- App icon, splash screen, branding

### 2-bosqich: User Flutter app
1. `cd ~/fargonam/mobile_user && flutter create .` (yoki Android SDK kelganda)
2. Asosiy ekranlar: Splash, Login, Register, Home (kategoriyalar), Mahsulot, Savatcha, Buyurtma
3. State management: Riverpod yoki Bloc (qaror keyinroq)
4. Backend bilan ulanish: `dio` paketi

### 3-bosqich: Seller Flutter app
1. Do'kon yaratish, mahsulot yuklash, buyurtmalarni ko'rish

### 4-bosqich: Admin web
1. Oddiy HTML+JS yoki keyinroq qo'shamiz

---

## Muhim qarorlar (texnik)

| Qaror | Sabab |
|---|---|
| **Python 3.13** (3.14 emas) | 3.14 juda yangi, pydantic-core build qila olmadi |
| **uv** (pyenv emas) | Sudosiz, tez, ishonchli |
| **Docker** (mahalliy o'rnatish emas) | Toza, oson to'xtatiladi, ishlab chiqarishga yaqin |
| **Modular Monolith** | Mikroservis hozir keraksiz, kelajakda ajratish oson |
| **Marketplace birinchi** | Taksi'dan oson, yolg'iz sinash mumkin, asoslarni o'rgatadi |
| **Faqat Android (hozircha)** | iOS uchun Mac kerak, MVP'dan keyin Codemagic orqali iOS build |

## Muhim qarorlar (biznes — feron'dan)
- 2 ta mobil ilova: User + Seller/Driver
- Admin panel — alohida ilova emas, web/CLI
- MVP'da to'lov YO'Q (keyinroq senior bilan)
- Birinchi marketplace kategoriyasi: kiyim-kechak (keyin har xil)
- Hozircha localhost, MVP yaqinlashganda Oracle Cloud Free Tier
- Domen va brending hozircha yo'q

---

## Ochiq savollar (feron javob bersin)
- (hozircha yo'q)

---

## Kerakli buyruqlar (eslatma)

### Backend ishga tushirish
```bash
cd ~/fargonam/backend
.venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### Backendni to'xtatish
```bash
pkill -f "uvicorn app.main"
```

### Postgres/Redis boshqarish
```bash
docker ps                                       # holatni ko'rish
docker stop fargonam_postgres fargonam_redis    # to'xtatish
docker start fargonam_postgres fargonam_redis   # qaytadan ishga tushirish
docker logs fargonam_postgres                   # log ko'rish
```

### DB ga ulanish
```bash
docker exec -it fargonam_postgres psql -U fargonam -d fargonam_db
```

### Git
```bash
cd ~/fargonam && git status && git log --oneline
```

---

## Sessiyalar tarixi

### 2026-04-09 (2-sessiya)
- `.env` yaratildi (lokal SECRET_KEY generatsiya qilindi)
- `app/core/config.py` — Pydantic Settings
- `app/db/{base,session}.py` — async engine, Base, get_db
- **Muammo**: SQLAlchemy async `greenlet` paketini talab qildi → `uv pip install greenlet` (requirements.txt'ga qo'shildi)
- `app/models/user.py` — User modeli (UserRole enum: buyer/seller/admin)
- Alembic init -t async; `env.py`'da `target_metadata = Base.metadata`, URL settings'dan; `users` jadvali uchun migration yaratildi va qo'llanildi
- `app/core/security.py` — bcrypt hash, JWT helper'lar
- **Muammo**: passlib 1.7.4 + bcrypt 5.0 mos emas (`__about__` yo'q, "72 bytes" xatosi) → `bcrypt==4.0.1`'ga pin qilindi (requirements.txt yangilandi)
- `app/schemas/auth.py`, `app/api/deps.py` (OAuth2PasswordBearer + get_current_user), `app/api/auth.py` (register/login/me)
- `app/main.py`'ga auth router ulandi
- E2E test (curl): register→token, login→token, me→user, dublikat→409, xato parol→401 ✅
- **Auth tayyor bo'lgandan keyin marketplace bilan davom etildi:**
- 6 ta marketplace modeli yaratildi (Shop, Category, Product, CartItem, Order, OrderItem)
- Migration #2 autogenerate va upgrade — DBda 8 jadval
- 4 ta API router: shops, categories, products, cart (orders ham shu yerda)
- Schemas (`app/schemas/marketplace.py`) Pydantic v2 stilida
- Auth+RBAC: faqat seller/admin shop yaratadi; mahsulotni faqat egasi tahrirlaydi
- Checkout endpointi: stockni tekshiradi va kamaytiradi, savatchani tozalaydi, narxni satrda saqlaydi
- E2E curl test ketma-ketligi to'liq o'tdi: seller register → shop → product → buyer register → cart → checkout (stock 10→8 ✓)
- **Marketplace tayyor bo'lgandan keyin image upload qo'shildi:**
- `app/core/storage.py` — UPLOAD_ROOT, ensure_dirs, public_url (S3 ga ko'chirish uchun abstraksiya)
- Product modeliga `image_url` ustuni + migration #3
- `POST /products/{id}/image` — multipart, faqat jpg/png/webp, max 5MB, fayl nomi `{id}_{token}.{ext}`, eski rasmni avtomatik o'chiradi
- `/static` mountda `backend/uploads/` xizmat qiladi
- `.gitignore`: `backend/uploads/*` (lekin `.gitkeep` saqlanadi)
- E2E test: yuklash, /static dan o'qish, 403 (begona seller), 400 (text/plain) — barchasi to'g'ri
- **Image upload tayyor bo'lgandan keyin search/pagination qo'shildi:**
- `app/schemas/common.py` — generic `Page[T]` (items, total, limit, offset)
- `GET /products` kengaytirildi: `q` (name ilike), `min_price`, `max_price`, javob `Page[ProductOut]`
- E2E test: 4 ta mahsulot DB ga qo'shildi (Erkaklar shimi, Qishki kurtka, Sport futbolka + oldingi Futbolka), filter va pagination ishlayapti
- **Search/pagination tayyor bo'lgandan keyin admin web va Android SDK:**
- **MUHIM arxitektura aniqligi**: Feron aytdi — sotuvchilar admin webga kirmaydi, ular o'z biznes ilovasidan (mobile_seller) foydalanadi. Admin web faqat platforma adminlari uchun. Bu xotirada saqlandi.
- Admin endpointlar (`/admin/users`, `/admin/orders`, `/admin/stats`) + `require_admin` dependency
- `scripts/create_admin.py` va birinchi admin yaratildi (+998900000000 / admin12345)
- `admin_web/index.html` — vanilla JS + Tailwind CDN, sodda va kutubxonasiz. Login + 4 tab.
- FastAPI mountlar: `/static` (uploads), `/admin-web` (admin_web/) — `/admin` API band, shuning uchun `-web` qo'shimchasi
- E2E: admin login, stats, users, orders, RBAC, status PATCH, revenue qayta hisoblanishi — barchasi ✓
- **Android SDK fonda sudosiz o'rnatildi**: Temurin JDK 17 (~/jdk17), Android cmdline-tools (~/Android/Sdk), platform-tools, platforms;android-36, build-tools;36.0.0. ~/.zshrc'ga env vars qo'shildi.
- `flutter doctor` — Android toolchain ✓
- **To'xtagan joy**: backend + admin web + dev environment to'liq tayyor. Keyingi qadam — Flutter mobile ilovalarini yaratish (avval mobile_seller — chunki sotuvchi mahsulot qo'shsa, mobile_user uchun ko'rsatish narsa bo'ladi)

### Kerakli buyruqlar (yangilangan)

**Birinchi admin yaratish/qayta tiklash:**
```bash
cd ~/fargonam/backend
.venv/bin/python -m scripts.create_admin +998900000000 admin12345 "Admin"
```

**Admin webga kirish:**
1. Backendni ishga tushiring
2. Brauzerda: http://localhost:8000/admin-web/
3. Login: +998900000000 / admin12345

**Flutter Android uchun env (zshrc'da bor, lekin yangi shellda):**
```bash
export JAVA_HOME=$HOME/jdk17
export ANDROID_HOME=$HOME/Android/Sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

### 2026-04-08 (1-sessiya)
- Loyiha boshlandi, tech stack tasdiqlandi (Flutter + FastAPI + Postgres + Redis)
- Loyiha papkalari va git repo yaratildi
- Docker o'rnatildi, Postgres+Redis containerlari ishga tushirildi
- Python 3.14 muammosi → uv orqali Python 3.13.12 o'rnatildi
- FastAPI paketlari o'rnatildi, backend ishga tushdi (`http://localhost:8000`)
- Flutter 3.41.6 o'rnatildi (Android SDK hali yo'q)
- 1-commit: "Loyiha skeleti: backend, mobile, docker-compose"
- **To'xtagan joy**: backend ishlayapti, lekin DB modellari yo'q. Keyingi qadam — config, db session, User modeli.
