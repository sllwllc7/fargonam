# Fargonam — To'liq Texnik Topshiriq (TZ)

> Bu hujjat Fargonam loyihasining 2026-08-17 holatiga ko'ra to'liq tavsifi. Boshqa AI
> yordamchilarga (ChatGPT, Gemini, Claude web va h.k.) loyiha kontekstini berish uchun
> yozilgan — undan foydalanganda **"HOZIRGI HOLAT" va "KELAJAK REJASI" bo'limlarini
> aralashtirmang**: loyihada ikkita alohida hujjat guruhi bor — biri hozir qurilayotgan MVP,
> ikkinchisi uzoq muddatli maqsadli arxitektura. Ular ataylab bir-biridan ajratilgan.
>
> **UI/DIZAYN — HAL QILINDI (2026-08-18 dan):** 2026-08-17 dagi "ochiq masala" holati
> yopildi. Yagona dizayn manbai endi `docs/DESIGN.md` ("Fargonam — Ink Blue", brend rangi
> `#16305C`, Manrope+Inter) — batafsil §7ga qarang. Stitch orqali mokap yasash to'xtatildi;
> UI to'g'ridan-to'g'ri Flutterda quriladi. Texnik/funksional tarkib (qaysi ekran nima
> qiladi, qaysi ma'lumot API'dan keladi) — bundan avval ham o'zgarmagan edi.

---

## 1. Loyiha nima

**Fargonam** — Farg'ona vodiysi (Farg'ona, Andijon, Namangan viloyatlari) uchun mo'ljallangan
hududiy **Super App**. Yakuniy maqsad — bitta ilovada uchta yo'nalishni birlashtirish:

1. **Marketplace** — onlayn savdo (bugungi kunda faol qism)
2. **Taksi/eltuv agregatori** (Yandex Go/Uzum kabi, mahalliylashtirilgan)
3. **Yangiliklar/ijtimoiy tarmoq** (hududiy yangiliklar, e'lonlar)

Kelajakda AI-assistent ham qo'shiladi (savdo/taksi bo'yicha yordamchi sifatida).

Loyiha egasi (foydalanuvchi) — bitta oilaviy biznes egasi, dastlab **o'quv qurollari
do'koni**ni onlaynga chiqarish bilan boshlagan, keyin buni butun hudud uchun platforma qilib
kengaytirish niyatida.

To'liq strategik hujjatlar (lokal fayllar, boshqa AI'ga tashlash uchun mavjud emas — faqat
mazmuni pastda qisqartirilgan): `Super App System Architecture Guide.pdf` va `Super App -
Loyiha Master Strategiyasi va Texnik Specification.docx`, ikkalasi ham 2026-08-12 da
foydalanuvchi tomonidan rasman tasdiqlangan texnik/biznes yo'nalish sifatida.

---

## 2. Biznes bosqichlari (roadmap)

### 1-bosqich — MVP (2026-yil Avgust, **HOZIR SHU BOSQICHDAMIZ**)

- Faqat **bitta monodo'kon** faol: o'quv qurollari (maktab buyumlari, daftar, ruchka va h.k.).
- Bu ko'p-sotuvchili marketplace EMAS — tashqi sotuvchilar yo'q, hamma tovarni loyiha egasi
  (oila biznesi) sotadi.
- To'lov usuli — **faqat offline**: kuryer POS-terminali orqali yetkazib berish paytida
  (naqd/karta). Onlayn to'lov integratsiyasi yo'q.
- Yetkazib berish — hozircha **bepul** (`delivery_fee` maydoni ham yo'q).
- Qolgan modullar (Taksi, AI, Yangiliklar) UI'da ko'rinadi, lekin **"Tez orada" holatida** —
  funksional emas, faqat skelet/placeholder.
- Maqsad: real xaridorlar bilan sinash, asosiy marketplace oqimini (katalog → savat →
  checkout → kuryer) mustahkamlash.

### 2-bosqich — Kengaytirish (2026-yil Sentabr+)

Ketma-ket, bittadan yoqiladi:
- Taksi/eltuv agregatori (to'liq funksional)
- AI Assistant
- Yangiliklar moduli
- Onlayn to'lovlar: Click, Payme, Uzum, xalqaro kartalar

### Muhim qoida

Yangi funksiya so'ralganda, u qaysi bosqichga tegishli ekanini aniqlash kerak. **1-bosqichda
2-bosqich funksiyalarini (taksi, AI) to'liq qurishga urinilmaydi** — faqat skelet/"coming
soon" darajasida qoldiriladi. Bu — loyiha egasining aniq talabi, resurslarni tarqatmaslik
uchun.

---

## 3. Texnik stack (hozirgi, amalda ishlatilayotgan)

| Qatlam | Texnologiya |
|---|---|
| Xaridor mobil ilova | Flutter (`mobile_user`) |
| Sotuvchi/haydovchi mobil ilova | Flutter (`mobile_seller`) |
| Admin panel | Oddiy statik HTML+JS (`admin_web/index.html`, bitta fayl, SPA uslubida) |
| Backend | FastAPI (Python) |
| Ma'lumotlar bazasi | PostgreSQL |
| Kesh/tezkor ma'lumot | Redis |
| Deploy | Docker (faqat Postgres+Redis uchun konteyner), nginx, systemd, Linux VPS |
| Auth | Telegram login (bot orqali, OTP/parol EMAS) |
| State management (Flutter) | Riverpod |
| Mobile struktura | Flat `lib/features/<modul>/` (feature-module, lekin qat'iy clean
architecture emas) |

**Muhim:** hozirgi backend struktura **flat** — `backend/app/{api,core,db,models,schemas}/`.
Schema-isolation (bounded context bo'yicha alohida PostgreSQL schema) hali YO'Q — bu haqda
6-bo'limda batafsil.

---

## 4. Backend — hozirgi amalga oshirilgan API va modellar

`backend/app/api/` da mavjud modullar (barchasi bitta flat FastAPI app ichida, versiyalanmagan
— `/api/v1/` emas, to'g'ridan-to'g'ri):

- `auth.py` — Telegram asosida login (eski parol-asosidagi `/auth/register`/`/auth/login`
  ham hali kod ichida qoladi, lekin hech bir klient ishlatmaydi)
- `telegram_auth.py` — Telegram bot orqali session ochish/polling
- `products.py`, `categories.py`, `shops.py` — katalog
- `cart.py` — savat, checkout, Idempotency-Key qo'llab-quvvatlaydi
- `addresses.py` — saqlangan manzillar
- `favorites.py`, `reviews.py` — sevimlilar, sharhlar
- `seller.py` — sotuvchi paneli (mahsulot qo'shish/tahrirlash, buyurtmalarni boshqarish)
- `admin.py` — admin panel backend (foydalanuvchi/do'kon/buyurtma boshqaruvi, KYC tasdiqlash)
- `news.py`, `announcements.py`, `feed.py` — yangiliklar/ijtimoiy modul skeleti
- `rides.py`, `ride_ratings.py` — taksi modul skeleti
- `chat.py`, `ws.py` — chat/WebSocket
- `notifications.py`, `push.py` — bildirishnomalar (FCM)
- `profile.py`, `app_config.py` — foydalanuvchi profili, ilova sozlamalari

`backend/app/models/` dagi asosiy jadvallar: `user`, `shop`, `product`, `product_variant`,
`product_image`, `product_set` (skelet), `category`, `cart`, `order`, `saved_address`,
`favorite`, `review`, `ride`, `ride_rating`, `news`, `news_interaction`, `announcement`,
`banner`, `notification`, `fcm_token`, `message`, `app_config`.

21 ta Alembic migratsiya qo'llangan (hozirgi head'gacha).

### Marketplace — eng rivojlangan modul

2026-08-13 da **mahsulot-variant modeli** to'liq backend darajasida amalga oshirildi (masalan
"Daftar" mahsuloti 12/36/48/96-varoqli variantlarga ega, har biri alohida narx/stok/SKU):

- `product_variants` jadvali: `sku`, `variant_name`, `price` (INTEGER, so'm — kasrsiz),
  `stock`, `attributes JSONB` (+GIN index), `image_url`, `sort_order`.
- `products.price`/`stock` olib tashlandi, o'rniga variant orqali hisoblanadi.
- To'liq backward compatibility saqlangan: eski Flutter kod (`product_id` bilan ishlaydigan)
  hozir ham backend darajasida ishlaydi — avtomatik "Standart" variantga yo'naltiriladi.
- Bitta oilaviy do'kon bo'lgani uchun **`seller_id` alohida ustun yo'q** — bu ko'p-sotuvchili
  marketplace emas, `products.shop_id → shops.owner_id` yetarli. Shu sababli **order
  splitting** (bir nechta sotuvchidan iborat savatni parent/child order'larga bo'lish) hali
  YO'Q — kerak ham emas, chunki hozircha bitta sotuvchi bor.
- **Qolgan ish (4-bosqich, hali boshlanmagan):** Flutter UI tomoni — variant tanlash
  bottom-sheet, tap-to-edit miqdor kiritish, checkout'da saqlangan manzil tanlash. Backend
  tayyor, faqat mobil ilova hali eski (variant-oldi) UI bilan ishlayapti.
- **5-bosqich (kelajak, faqat skelet):** `product_sets`/`product_set_items` — tayyor
  to'plamlar (masalan "1-sinf uchun maktab to'plami"), Fargonam o'zi tuzadi, tashqi maktab
  bilan rasmiy integratsiya (OCR va h.k.) YO'Q — juda sodda modeldan foydalaniladi.

### Taksi va Yangiliklar

Faqat skelet: DB jadvallari va asosiy CRUD endpoint bor (`rides.py`, `ride_ratings.py`,
`news.py`), lekin real dispatch/matching logikasi, geolokatsiya, real-time kuzatuv — YO'Q.
Bu 2-bosqich ishi.

---

## 5. Mobil ilovalar va admin panel — hozirgi holat

### mobile_user (xaridor ilovasi)

Pastki navigatsiya — **o'zgarmas** deb belgilangan, 5 tab, aniq shu tartibda: **Do'kon (Market)
| Taxi | Home (markaziy) | AI | Profil**. Yangi funksiya kerak bo'lsa mavjud tab ichiga
qo'shiladi, yangi tab qo'shilmaydi.

Feature papkalar: `addresses`, `ai_assistant` (skelet), `auth`, `cart`, `chat`, `favorites`,
`help`, `home`, `legal`, `marketplace`, `news` (skelet), `notifications`, `onboarding`,
`orders`, `products`, `profile`, `search`, `shell`, `shops`, `splash`, `stories`, `taxi`
(skelet).

Auth — Telegram login (bot orqali session-polling), eski parol-asosidagi login/register
ekranlari o'chirilgan.

### mobile_seller (sotuvchi/haydovchi ilovasi)

2026-08-13 dan ishga tushirilgan (avval "keyinroq" deyilgan edi). Bir xil qurilmada
mobile_user bilan yonma-yon o'rnatiladi (alohida `applicationId`). Feature papkalar: `auth`,
`dashboard`, `driver` (kelajakdagi taksi-haydovchi funksiyasi uchun skelet), `orders`,
`products`, `shop`, `legal`.

#### mobile_user ↔ mobile_seller bog'lanishi (2026-08-16 dan amalda)

Ikkala ilova ham **bitta umumiy backend**ka ulanadi — alohida sotuvchi-server yo'q, faqat
rol (`buyer`/`seller`/`admin`) foydalanuvchini ajratadi:

- **Auth:** ikkalasi ham `/auth/telegram/*` orqali kiradi, `role` parametri farqlaydi
  (yangi foydalanuvchi uchun boshlang'ich rol; mavjud foydalanuvchi o'z roli bilan kiradi).
- **Buyurtma oqimi (real-time):** xaridor `mobile_user`da buyurtma bersa, backend uni
  darhol sotuvchiga yetkazadi — `mobile_seller`da shu maqsadda `ws_service.dart`
  (WebSocket) va `push_service.dart` (FCM push) qo'shildi (2026-08-16, `6a7d114`
  commit). Ilova ochiq bo'lmasa ham push bildirishnoma keladi.
- **Pickup kod bilan bog'lanish** (yangi, 2026-08-16): xaridor checkout'da
  `delivery_type=pickup` tanlasa (do'kondan o'zi olib ketish), backend **4 xonali
  noyob kod** generatsiya qiladi (`orders.pickup_code`, DB darajasida unique). Bu kod
  xaridorga `mobile_user`da ko'rsatiladi, sotuvchi esa `mobile_seller`dagi buyurtma
  kartochkasida shu kodni ko'rib, xaridor do'konga kelganda tasdiqlash uchun ishlatadi —
  ikkala ilova o'rtasidagi jismoniy tasdiqlash ko'prigi shu.
- **Seller buyurtma kartochkasi** (`seller_orders_screen.dart`, 2026-08-16 yangilangan):
  `delivery` turdagi buyurtmalarda xaridorning yetkazib berish manzili to'g'ridan-to'g'ri
  ko'rinadi; mijoz telefon raqami bosilsa `tel:` orqali darhol qo'ng'iroq qiladi.
- **Admin panel** ikkalasidan ham ma'lumot ko'radi (`ShopAdminOut`ga `owner_phone`/
  `product_count` qo'shilgan) — sotuvchi va uning do'koni/buyurtmalari bitta joyda
  nazorat qilinadi.

### admin_web

Bitta HTML fayl (`admin_web/index.html`), SPA uslubida (ko'p ekran bitta faylda, alohida
fayl+iframe emas — bu loyihaning qat'iy talabi). Do'kon KYC tasdiqlash, foydalanuvchi/buyurtma
boshqaruvi, dashboard statistika. Auth — Telegram login, `ADMIN_TELEGRAM_IDS` orqali ruxsat
etilgan Telegram ID'lar avtomatik `admin` rolini oladi.

---

## 6. Maqsadli (uzoq muddatli) arxitektura — HALI QURILMAGAN

Bu bo'lim — **kelajak uchun tasdiqlangan yo'nalish**, hozirgi kod bunga hali mos emas. Rasmiy
manba: `Super App System Architecture Guide.pdf` (2026-08-12 da tasdiqlangan).

### Asosiy tamoyil: Modular Monolith + DDD

Mikroservisga **erta o'tish taqiqlangan** — kichik jamoa uchun ortiqcha operatsion
murakkablik. Backend bitta deploy qilinadigan artifact bo'lib qoladi, lekin domenlar orasidagi
chegara til darajasida (modul/import) ta'minlanadi.

### Bounded context'lar

`Identity`, `Marketplace`, `Mobility`, `Wallet` — har biri **alohida PostgreSQL schema**da
(`identity.*`, `marketplace.*`, `mobility.*`, `wallet.*`). Domenlararo to'g'ridan-to'g'ri
jadval query TAQIQLANADI — faqat interfeys/service funksiyalari orqali.

**Joriy gap:** backend hozircha flat (`app/{api,core,db,models,schemas}/`), schema-isolation
yo'q. Bu — kelajakdagi katta refactor, foydalanuvchi tasdiqlamaguncha boshlanmaydi.

### Wallet/moliyaviy operatsiyalar (2-bosqich, onlayn to'lov bilan birga keladi)

Double-entry bookkeeping (`SUM(Debits) = SUM(Credits)` doim to'g'ri bo'lishi kerak). Balans
yangilanishi pessimistic lock (`SELECT ... FOR UPDATE`) yoki optimistic concurrency (`version`
ustuni) bilan himoyalanadi — race condition'ga yo'l qo'yilmaydi.

### Idempotency

To'lov, buyurtma, dispatch endpoint'larida idempotency key majburiy (checkout'da bu allaqachon
qo'llangan — 8-bo'limga qarang).

### Inventory (overselling oldini olish)

Ikki bosqichli reservation: avval Redis'da vaqtinchalik decrement (TTL ~15 daqiqa), to'lov
tasdiqlangach DB'da optimistic lock bilan permanent commit. **Hozircha qo'llanilmagan** — MVP-1
offline to'lov bo'lgani uchun oddiy DB stock check yetarli.

### Mobility (taksi, 2-bosqich)

Geospatial indexing uchun **Uber H3** (hexagonal grid) tavsiya etiladi — Geohash/QuadTree
emas, chunki H3 uniform neighbor distance beradi, surge pricing va batch dispatch matching
uchun mos. Haydovchi lokatsiyasi Redis'da (`GEOADD`/`HSET`), TTL ~15 soniya (faollik belgisi
sifatida).

### Event-driven aloqa

NATS JetStream (Kafka emas — yengil operatsion yuk). Transactional Outbox Pattern: business
yozuv va event bitta DB tranzaksiyasida `outbox_events` jadvaliga yoziladi, alohida worker uni
broker'ga yuboradi.

### Search

MeiliSearch — katalog qidiruvi uchun (Postgres asosiy transactional DB, MeiliSearch faqat
read-optimized index, CDC orqali sync). Hozircha oddiy `Product.name.ilike()` ishlatiladi
(FTS/GIN index'siz) — bitta do'kon hajmida bu muammo emas, katta katalog bo'lganda kerak
bo'ladi.

### Kengroq platforma checklist seriyasi (00-05)

Foydalanuvchidan alohida, juda batafsil "00 — PLATFORM CORE" va shunga o'xshash
(01_MARKETPLACE, 02_TAXI va h.k.) checklist hujjatlar ham kelgan — bular production-grade
to'liq platforma uchun (go_router+StatefulShellRoute, get_it+injectable DI, Bloc/Cubit, qat'iy
clean architecture, versioned `app/api/v1/`, Sentry, CI/CD, Payme/Click to'liq webhook). Bular
ham **faqat kelajak rejasi**, hozirgi MVP-1 kod bazasi (Riverpod, flat struktura, Telegram
login) bilan bir nechta joyda to'g'ridan-to'g'ri zid — ataylab hozircha qo'llanilmaydi.

---

## 7. UI/dizayn — HAL QILINDI (2026-08-18)

Bu bo'limda ilgari (2026-08-13) qabul qilingan, keyin 2026-08-17 da olib tashlangan UI
qarorlari bo'lgan — bir nechta yo'nalish (Kutuku dizayn tizimi, keyin mebel-ilova shakl
tili + Midnight Indigo rang) ketma-ket sinab ko'rilib, hech biri loyiha egasiga
to'liq yoqmagandi. **2026-08-18 da yakuniy yo'nalish tasdiqlandi:**

- **Yagona dizayn manbai:** `docs/DESIGN.md` ("Fargonam — Ink Blue").
- **Brend rangi:** `#16305C` (siyoh ko'k). Shakl tili, spacing, majburiy governance
  qoidalari (rang+icon+matn, container-pattern xato/ogohlantirish, yagona warning tokeni)
  avvalgi "Ishonch" (`#0B6E4F` zumrad, 2026-08-17) qoralamasidan o'zgarishsiz qoldi — faqat
  brend rangi almashtirildi.
- **Shrift:** Manrope (sarlavhalar) + Inter (matn/narx).
- **Ish tartibi o'zgardi:** Stitch orqali mokap yasash **to'xtatildi** — natija ishonchsiz
  chiqdi. Bundan buyon UI to'g'ridan-to'g'ri Flutterda quriladi, alohida mokap
  tayyorlanmaydi. `stitch_markdown_project_documentation/` papkasi va undagi eski
  `DESIGN.md` (Midnight Indigo/Kutuku Violet asosli) endi ishonchsiz — hech qanday yangi
  ish shunga tayanmasin.

**Nima sinab ko'rilgan va rad etilgan (takrorlanmasin uchun eslatma):**
- Kutuku UI kit (Poppins shrift, binafsha #514EB7 → keyin Midnight Indigo'ga
  qayta ranglangan, pill-shakldagi tugmalar).
- Binafsha/lavanda glassmorphism (bulut-fayl ilovasi Pinterest referensidan shakl
  olingan) — faqat HTML prototip darajasida sinaldi, kodga tatbiq qilinmadi.
- Mebel-ilova (oq fon, Midnight Indigo #212842, "hamma narsa dumaloq" qoidalari) —
  qisman kodga tatbiq qilingan edi, keyin to'liq qaytarib tashlangan (git orqali).
- "Ishonch" zumrad-yashil qoralamasi (`#0B6E4F`, 2026-08-17) — brend rangi keyinchalik
  ink-blue'ga almashtirildi, qolgan struktura saqlandi (yuqoriga qarang).

Kodda mavjud bo'lgan ikkita parallel eski token-tizim (9-bo'limga qarang) shu qaror
asosida birlashtirilmoqda — `core/theme/` tuzilishi qoladi, `core/theme.dart` o'chiriladi.

Texnik/funksional tomon (qaysi ekranda qanday ma'lumot, qanday amal bajariladi) bu
bilan bog'liq emas va o'zgarmagan — masalan miqdor input, savat, checkout oqimi hali ham
avvalgidek ishlaydi, faqat ularning **ko'rinishi** yangilanmoqda. Miqyos eslatmasi:
~60 kategoriya/~1000 variantli katalog uchun qidiruv/filtr/saralash/pagination MVP-1
qamroviga kiradi — bu ro'yxat/grid ekranlarining UI qarorlariga ta'sir qiladi.

---

## 8. Xavfsizlik holati

### Tuzatilgan (2026-08-13)

Tashqi audit checklist (AUDIT_CHECKLIST.md) asosida real kod bazasiga solishtirib filtrlangan,
6 ta P0 xavfsizlik muammosi tuzatildi:

1. **`STATIC_OTP="5555"` butunlay olib tashlandi.** Uchala klient (mobile_user, mobile_seller,
   admin_web) endi FAQAT Telegram login ishlatadi.
2. Access token muddati 30 kundan **15 daqiqaga** tushirildi.
3. Refresh token **rotation + revocation** qo'shildi (`/auth/logout`, Redis'da jti ro'yxati,
   qayta ishlatilgan token rad etiladi).
4. `DEBUG=true` production'ga chiqib ketmasligi — `deploy_backend.sh` serverdagi `.env`da
   majburan `false` qiladi.
5. Keystore parollari kod bazasidan (`build.gradle.kts`) gitignored `key.properties`ga
   ko'chirildi.
6. `POST /orders`ga **Idempotency-Key** qo'llab-quvvatlashi qo'shildi (Redis SET NX) — tarmoq
   retry'lari qo'sh buyurtma yaratmaydi. `android:allowBackup="false"` qo'yildi.

### Hali TUZATILMAGAN (audit topilmalari, kam muhim)

- UX/checkout: buyurtma tasdiqi ekrani yo'q, saqlangan manzillar checkout'da ishlatilmaydi,
  grid kartochkada stock badge yo'q, mahsulot detail sahifasida faqat 1 rasm ko'rsatiladi
  (backend ko'p rasmni qo'llab-quvvatlaydi, UI ishlatmaydi).
- Testlar **0%** (mobile ham, backend ham), CI/CD yo'q.
- `flutter_screenutil` yo'q (500+ hardcoded o'lcham), 30tadan 14 ekranda `SafeArea` yo'q.
- `mobile_user/android/app/src/main/AndroidManifest.xml`da
  `android:usesCleartextTraffic="true"` — HTTP trafikka ruxsat beradi. nginx'da hozircha faqat
  `listen 80` (HTTPS/certbot sozlanmagan). **Bu ikkisi bog'liq — production'ga chiqishdan oldin
  albatta hal qilinishi kerak.**
- `forgot_password` endpoint stub (hech ish qilmaydi, Telegram foydalanuvchilariga tegishli
  emas — muhim emas).

### Jarayonda

**Telegram login production'ga hali chiqarilmagan.** Backend va uchala klient kodi tayyor.
Production'ga chiqarishdan oldin qolgan: `TELEGRAM_USE_POLLING=false` qilib HTTPS domenda
`set_telegram_webhook.py` skriptini ishga tushirish (hozircha polling rejimida ishlaydi, bu
production uchun mos emas).

### Umumiy xulosa

**Loyiha hali real (keng) foydalanuvchilarga ochiq qilib bo'lmaydi** — asosan HTTPS/webhook
production sozlamalari va cleartext traffic muammosi tufayli. Ikkita eng jiddiy CRITICAL
muammo (STATIC_OTP, DEBUG leak) hal qilingan, qolganlari operatsion sozlash darajasida.

---

## 9. Hal qilinmagan kichik texnik nizolar

- ~~`mobile_user`da ikkita parallel dizayn-token tizimi bor~~ — **2026-08-18 da
  birlashtirilmoqda.** `core/theme/app_colors.dart` + `app_radius.dart` + `app_spacing.dart`
  + `app_text_styles.dart` + `app_shadows.dart` + `app_theme.dart` (fayl/joylashuv
  tuzilishi qoladi, chunki allaqachon jonli — `main.dart`dagi `MaterialApp`ga ulangan) —
  ichidagi qiymatlar `docs/DESIGN.md`ning yangi Ink Blue tizimiga yangilandi (Poppins →
  Manrope+Inter, Kutuku pill-radius → DESIGN.mdning 8/12/16/24px shkalasi). Legacy
  `core/theme.dart` (jonli emas edi, faqat 21 ta ekran unga bog'langan edi) o'chirilmoqda —
  o'sha ekranlar yangi `core/theme/` tokenlariga ko'chirilmoqda. Batafsil reja:
  `/home/feron/.claude/plans/scalable-yawning-hickey.md` (shu sessiyada saqlangan).

---

## 10. Xulosa — boshqa AI bilan gaplashishda e'tiborga olinsin

Fargonam hozir **MVP-1 bosqichida**: bitta o'quv-qurollari do'koni, offline to'lov, marketplace
modul eng rivojlangan (variant model backend'da tayyor, Flutter UI qoladi). `mobile_user` va
`mobile_seller` bitta backend orqali real-time bog'langan (buyurtma push/WebSocket bilan
sotuvchiga yetadi, pickup buyurtmalarda 4 xonali kod ikkala ilova o'rtasida tasdiqlash
ko'prigi vazifasini bajaradi — 5-bo'limga qarang). Taksi/AI/Yangiliklar — faqat skelet.
Backend — flat FastAPI monolit, hali bounded-context schema-isolation'ga o'tmagan (bu —
tasdiqlangan uzoq muddatli reja, hoziroq boshlanmaydi). Xavfsizlikning eng jiddiy qismlari
yopilgan, lekin production HTTPS/webhook sozlamalari va bir nechta UX/test qoldiqlari hali
bor.

**UI/dizayn haqida so'ralsa — 7-bo'limga qarang: hech qanday vizual yo'nalish
tasdiqlanmagan, oldindan rang/uslub taklif qilishdan saqlaning, loyiha egasi bilan ochiq
suhbat orqali variantlar taklif qiling.**

Yangi g'oya yoki funksiya taklif qilinganda, avval **qaysi bosqichga tegishli ekanini**
(MVP-1 vs 2-bosqich vs uzoq-muddatli arxitektura) aniqlashtirish kerak — bu loyihaning eng
ko'p qaytariladigan qoidasi.
