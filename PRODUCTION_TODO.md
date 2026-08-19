# Fargonam — Productionga Chiqish Uchun To'liq Ishlar Ro'yxati

> 2026-08-15. Bu hujjat kod bazasini real o'qib chiqib tuzilgan — taxmin emas, har bir band
> aniq fayl/qatorga asoslangan. Ko'lam: **MVP-1** (faqat o'quv qurollari monodo'koni, offline
> to'lov — `CLAUDE.md`dagi 1-bosqich). Taksi/AI/Yangiliklar 2-bosqich, bu hujjatga kirmaydi.

Muhim tuzatish: avvalgi suhbatda "ekranlar deyarli tayyor" deyilgan edi — bu xato edi. Screen
fayli mavjudligi ish tugallanganini anglatmaydi. Pastda — nima chinakam yetishmayotgani.

---

## P0 — Bloklovchi (productionga chiqmasdan oldin SHART)

### 1. Seller ↔ Buyer bog'lanishi butunlay yo'q — ENG MUHIM MUAMMO

**Nima bo'lyapti:** Xaridor buyurtma bersa, sotuvchi (`mobile_seller`) buyurtmani ko'radi, lekin
**kimga yetkazishni bilmaydi**:

- Backend `OrderOut` sxemasida (`backend/app/schemas/marketplace.py:170`) faqat `user_id`
  qaytadi — xaridorning ismi, telefoni, Telegram'i **umuman yo'q**.
- `delivery_address` maydoni backend javobida **bor**, lekin `mobile_seller/lib/features/orders/seller_orders_screen.dart`dagi
  `_OrderCard` uni hech qayerda chizmaydi — faqat mahsulot nomi/soni/narxi va status tugmasi
  bor.
- Natija: sotuvchi buyurtmani "To'landi → Yo'lda → Yetkazildi" qilib belgilay oladi, lekin
  qayerga, kimga, qanday bog'lanib yetkazishni bilmaydi — **bu real ishlatib bo'lmaydigan
  holat**.

**Kerakli o'zgarish:**
1. Backend: `User` modelida `phone`/`full_name`/`telegram_id` bor — `OrderOut`ga (yoki
   sotuvchiga maxsus `SellerOrderOut` sxemasiga) `customer_name`, `customer_phone` qo'shish
   (join orqali). `backend/app/api/seller.py:35` (`seller_orders`) shu join'ni qilishi kerak.
2. `mobile_seller`: `_OrderCard`ga — mijoz ismi/telefoni (bosilsa qo'ng'iroq qiladigan
   `tel:` link), to'liq yetkazib berish manzili (`delivery_address`), agar bor bo'lsa mo'ljal/
   izoh maydoni ko'rinadigan qilish.
3. **Sizning aniq stsenariyingiz** ("kimdir to'liq bozor qildi → seller Buyurtmalar tab'ida
   ko'radi → bosib kirsa hamma tafsilot bor → mahsulotlarni yig'ib qo'yadi") — buning uchun
   yetarli: (1) va (2) bandlari + har bir mahsulot qatoriga **"✓ Tayyorlandi" checkbox**
   qo'shish (ixtiyoriy, lekin ko'p pozitsiyali buyurtmada foydali — sotuvchi qaysi tovarni
   allaqachon yig'ganini belgilab boradi).
4. **Telegram orqali eslatma:** buyurtma kelganda sotuvchiga push/Telegram xabar yuborish
   (backend'da `notify_order_status` bor, lekin yangi buyurtma kelganda sotuvchiga xabar
   ketadimi — tekshirish kerak, `cart.py`dagi checkout logikasi ko'rib chiqilishi kerak).

**Nega P0:** siz aytganidek — bu funksiya bo'lmasa, real xaridor buyurtma bersa ham sotuvchi uni
jismonan bajara olmaydi. Bu MVP-1'ning ASOSIY oqimi, "tez orada" emas.

### 2. Admin panelidagi buzilgan/yo'q joylar

Kod tekshirilganda aniq topilgan (taxmin emas):

- `admin_web/index.html:670` — Buyurtmalar jadvalida "Mijoz" ustuni `o.user_phone`ni
  chaqiradi, bu maydon `OrderOut`da yo'q → doim ID raqami ko'rinadi. Yuqoridagi #1-band bilan
  bir vaqtda tuzatiladi (backend customer info qo'shilgach, shu yerga ham ulanadi).
- `admin_web/index.html:603` — Do'konlar jadvalida `s.owner_phone` va `s.product_count`
  (`:605`) — ikkalasi ham `ShopAdminOut` sxemasida yo'q (`backend/app/api/admin.py:154`) →
  doim bo'sh/0. Backend sxemaga join qo'shish kerak.
- **"Taksi buyurtmalar" bo'limi ishlamaydi** — `admin_web/index.html:720` `GET /rides`
  chaqiradi, lekin backendda bunday endpoint yo'q (`backend/app/api/rides.py`da faqat
  `/rides/my`, `/rides/driver/available`, `/rides/{id}` bor — admin-wide ro'yxat yo'q). MVP-1'da
  taksi "tez orada" bo'lgani uchun past prioritet, lekin admin panelda bosilganda xato
  chiqishi user-experience uchun yomon — hoziroq bu bo'limni sidebar'dan olib tashlash yoki
  "Tez orada" belgisi qo'yish arzon tuzatish.

**Nega P0:** buyurtma/do'kon boshqarish — kunlik ishlatiladigan asosiy admin funksiyasi, hozir
noto'g'ri ma'lumot ko'rsatib operatsion xatoga olib kelishi mumkin (masalan noto'g'ri odamga
qo'ng'iroq qilish xavfi, agar ID raqami telefon deb noto'g'ri o'qilsa).

### 3. Production HTTPS + Telegram webhook

(Avvalgi javobda aytilgan, hali dolzarb): `TELEGRAM_USE_POLLING=false` + `set_telegram_webhook.py`
+ nginx'da HTTPS/certbot + `android:usesCleartextTraffic="false"`. Bularsiz login production
domenda ishonchli ishlamaydi.

---

## P1 — Muhim, lekin blokировать qilmaydi (tez orada qilinishi kerak)

### 4. Admin panel — yetishmayotgan funksiyalar

- **Buyurtma/do'kon detail oynasi yo'q** — hozir faqat jadval qatori, ichidagi mahsulot
  ro'yxati/variant/to'liq manzilni ko'rish uchun modal kerak.
- **Foydalanuvchi rolini o'zgartirish UI'da yo'q** — backend qo'llab-quvvatlaydi
  (`PATCH /admin/users/{id}`, `role` maydoni bor, `backend/app/api/admin.py:53`), lekin
  `admin_web`da faqat "Blok/Faollashtirish" tugmasi bor, rol tanlash yo'q.
- **Mahsulot/variant boshqaruvi admin orqali yo'q** — hozir faqat `mobile_seller` yoki
  `/docs` orqali qo'lda. Bitta oilaviy do'kon bo'lgani uchun past-o'rta prioritet, lekin
  admin tezkor narx/stock tuzatish imkoniyati bo'lishi foydali.
- **"KYC" aslida hujjat tekshiruvi emas** — `Shop.status` shunchaki pending/approved/rejected
  belgisi, hech qanday pasport/litsenziya fayli yuklanmaydi (`backend/app/models/shop.py:20`).
  MVP-1'da bitta ishonchli do'kon bo'lgani uchun kam muhim, lekin nom sifatida "KYC" chalg'ituvchi.
- Qidiruv/filtr faqat foydalanuvchilar va buyurtmalarda bor (holat bo'yicha), sana oralig'i
  bo'yicha filtr yo'q.
- Statistika sahifasi — raqamlar bor, lekin grafik/trend (kunlik/haftalik daromad) yo'q.
- Eksport (CSV/Excel) hech qayerda yo'q — buxgalteriya/hisobot uchun kerak bo'lishi mumkin.

### 5. Marketplace variant UI (Flutter, mobile_user) — 4-bosqich

Backend to'liq tayyor (2026-08-13dan), Flutter UI hali yangilanmagan (`marketplace_variant_plan`
xotirasida batafsil reja bor): variant tanlash bottom-sheet, tap-to-edit miqdor, PDP variant
chip'lari, manzil viloyat/tuman dropdown + xarita pin.

### 6. Mahsulot detali — ko'p rasm galereyasi

Backend ko'p rasmni qo'llab-quvvatlaydi (`product_images` jadvali), `product_detail_screen.dart`
faqat 1 ta rasm ko'rsatadi (PageView/carousel yo'q).

### 7. Katalog kartochkasida stock badge yo'q

"Sotuvda N dona" yoki "Tugagan" belgisi yo'q — xaridor faqat PDP'ga kirgach biladi.

---

## P2 — Sifat va uzoq muddatli (production'ni bloklamaydi, lekin risk)

### 8. UI/UX real sifat muammolari — kod darajasida tasdiqlangan (screenshot emas, lekin aniq)

Sabab endi aniq — ikkita asosiy narsa, ikkalasi ham "arzon" taassurotning haqiqiy manbai:

- **Rang-sxema uzilishi tab chegarasida.** `core/widgets/`dagi BARCHA qayta-ishlatiladigan
  komponentlar (`app_button.dart`, `app_card.dart`, `app_chip.dart`, `app_input.dart`,
  `app_badge.dart`, `app_empty_state.dart`, `app_shimmer.dart`, `app_cached_image.dart`,
  `app_error_state.dart`) `core/theme/app_colors.dart` (Kutuku binafsha #514EB7) import qiladi.
  Shu komponentlar orqali **butun marketplace oqimi** (`marketplace_screen.dart`,
  `product_detail_screen.dart`, `cart_screen.dart`, `orders_screen.dart`,
  `order_detail_screen.dart`, `search_screen.dart`, `profile_screen.dart`,
  `addresses_screen.dart`, `product_groups_screen.dart`) binafsha. Shu bilan bir vaqtda
  `home_feed_screen.dart`, `shops_list_screen.dart`, `taxi_screen.dart`, `chat_screen.dart`,
  `news_screen.dart`, `notifications_screen.dart`, `onboarding_screen.dart`,
  `splash_screen.dart` — `core/theme.dart` (Fargonam indigo+cream) ishlatadi. Natija:
  foydalanuvchi pastki tabda **Do'kon**ga o'tganda ilova rangi bir zumda indigo'dan binafshaga
  sakraydi — bu eng ko'p bosiladigan tab chegarasi, tasodifiy joyda emas.
- **Ishlamaydigan reyting UI, foydalanuvchiga chalg'ituvchi ko'rinadi.**
  `marketplace_screen.dart:659-663`da `product['rating']` o'qib "Top" badge chiqarishga
  urinadi, `product_detail_screen.dart:736-803`da to'liq yulduzcha-reyting+sharh widget'i
  render qilinadi — lekin backend `ProductOut` sxemasida `rating`/`avg_rating` UMUMAN YO'Q,
  shuning uchun bu UI hech qachon to'lmaydi, "soxta"/tugallanmagan taassurot beradi.
- Qo'shimcha texnik signal: `flutter_screenutil` yo'q (masalan `home_feed_screen.dart`da 175 ta,
  `cart_screen.dart`da 83 ta xom o'lcham qiymati), 25 screen'dan 15 tasida `SafeArea` yo'q.
  Bular ikkinchi darajali — asosiy "arzonlik" sababi yuqoridagi ikki band.

**Tuzatish:** (a) marketplace oqimini ham `core/theme.dart` (Fargonam indigo+cream)ga
o'tkazish — ikkita AppColors'dan birini "yagona" qilish qarori (avval foydalanuvchiga
tasdiqlatish kerak, [[feedback_flag_scope_conflicts]]); (b) `rating` backend'da hisoblanmaguncha
reyting UI'ni ekrandan olib turish (o'lik/soxta elementni ko'rsatmaslik chirik ko'rsatishdan
yaxshi).

### 8b. mobile_seller — qo'shimcha topilmalar

- `driver_screen.dart` (949 qator) — **stub emas, to'liq qurilgan** (online/offline toggle,
  haydovchi profil, faol ride view), `main.dart`da rol-tanlash orqali ulangan. Lekin backend
  `rides.py` hali skelet bo'lgani uchun bu ekran hozircha **ishlamaydi/soxta holatda** —
  ilova ichida "yashirin o'lik kod". MVP-1 uchun past prioritet (Taksi 2-bosqich), lekin
  chalkashlik keltirishi mumkin — istasangiz rol-tanlashdan vaqtincha yashirib qo'yish mumkin.
- KYC rad etilganda (`my_shop_screen.dart`) "Admin bilan bog'laning" deyiladi, lekin
  to'g'ridan-to'g'ri aloqa tugmasi (chat/telefon) yo'q — sotuvchi qayerga yozishni bilmaydi.
- Sotuvchi o'z puli/hisob-kitobini tizimda umuman ko'rmaydi (offline to'lov courier POS orqali
  bo'lsa ham, "necha pul kutilyapti/tushdi" degan ko'rinish yo'q) — P1/P2 orasida, keyinroq
  qaraladigan.

### 9. Testlar va CI/CD

0% test qamrovi (mobile ham, backend ham), CI/CD yo'q. Production'da tinch uxlash uchun
kamida checkout/buyurtma oqimi uchun backend integration test kerak.

### 10. Boshqa mayda UX

Buyurtma tasdiqi/tracking — aslida `mobile_user/lib/features/orders/order_detail_screen.dart`da
status-stepper bilan **mavjud ekan** (avvalgi xotira eskirgan edi) — bu band yopilgan, faqat
tekshirib tasdiqlash uchun yozildi.

---

## Xulosa — ishlash tartibi taklifi

1. **#1 (seller↔buyer)** — eng muhim, sizning stsenariyingiz shu bilan ishga tushadi.
2. **#2 (admin bug'lari)** — #1 bilan bir vaqtda, chunki bir xil backend o'zgarishi (customer
   info) ikkalasiga ham kerak.
3. **#3 (HTTPS/webhook)** — infra, alohida, kod yozish kam, sozlash ko'p.
4. Keyin #4-7 navbat bilan, siz belgilagan tartibda.
5. #8 (vizual audit) — istalgan vaqtda, alohida qilsa bo'ladi, boshqalarga bog'liq emas.
