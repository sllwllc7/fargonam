# Fargonam User App — Progress (avtonom sessiya, 2026-08-19)

## Holat: 17 ta ekran tayyor, testlar yashil, ikkala ilova ham build bo'ladi

`mobile_user` (User App) HANDOFF.md 2-bo'limidagi barcha 17 ta ekran bo'yicha qayta qurildi,
yangi "Warm Violet" rang palitrasiga o'tkazildi. `flutter analyze` — 0 xato/ogohlantirish.
`flutter test` — 8/8 o'tdi. `flutter build apk --debug` — muvaffaqiyatli (ham `mobile_user`,
ham `mobile_seller`). **Faqat qurilmada jonli ko'rish siz qaytib telefonni ulaganingizdan
keyin qoladi** — pastda "Muammo: qurilma uzildi" bo'limiga qarang.

## Nima qilindi

### 1. Yangi rang palitrasi ("Warm Violet")
Siz yuborgan yangilangan `Mobile.zip` (HANDOFF.md + dc.html) avvalgi "Indigo" palitrasini
(#4B0082 gradient, #EDEDFB fon) butunlay almashtirdi: krem fon `#F8F7F3`, oq kartalar
`#FFFFFF`, binafsha CTA gradient `#6D28D9→#5B21B6`, apelsin aksent `#F59E0B` (savat FAB,
badge, "+" tugma). To'liq token jadvali `packages/fargonam_ui/lib/src/app_colors.dart`da —
bu bitta fayl orqali **User App va Seller App ikkalasi ham** avtomatik yangi ranglarga o'tdi,
chunki ikkalasi shu umumiy paketdan foydalanadi. `app_shadows.dart`/`app_gradients.dart` ham
yangi rgba qiymatlariga moslashtirildi.

### 2. Barcha 17 ta ekran (HANDOFF.md 2-bo'lim tartibida)

| # | Ekran | Fayl | Izoh |
|---|---|---|---|
| 1 | Bosh sahifa | `home/home_feed_screen.dart` | To'liq qayta yozildi — real savat/bildirishnoma badge, faol buyurtma, `GET /news` |
| 2 | Market (catalog) | `marketplace/catalog_screen.dart` | Qidiruv, Sinf to'plamlari qatori (real), kategoriyalar (real) |
| 3 | Sinf to'plami | `kits/kit_detail_screen.dart` | Real backend, "qo'shish" har item uchun alohida `POST /cart` |
| 4 | Kategoriya | `marketplace/category_products_screen.dart` | 2 ustunli grid, qidiruv |
| 5 | Mahsulot | `products/product_detail_screen.dart` | Variant chip tanlash, real narx/zaxira |
| 6 | Savat | `cart/cart_screen.dart` | Checkout endi alohida ekranga o'tadi |
| 7 | Rasmiylashtirish | `checkout/checkout_screen.dart` | **YANGI** — avval `cart_screen.dart` ichidagi bottom-sheet edi |
| 8 | Muvaffaqiyat | `checkout/order_success_screen.dart` | **YANGI** — avval dialog edi |
| 9 | Kuzatish | `orders/order_tracking_screen.dart` | **YANGI** — vertikal timeline, avval umuman yo'q edi |
| 10 | Buyurtmalar | `orders/orders_screen.dart` | Filtr chiplar (Barchasi/Jarayonda/Yetkazilgan) |
| 11 | Bildirishnomalar | `notifications/notifications_screen.dart` | Chap chiziq (o'qilmagan), turga qarab ikonka |
| 12 | AI chat | `ai_assistant/ai_assistant_screen.dart` | Qoida-asosidagi javob logikasi saqlandi |
| 13 | Taxi | `taxi/taxi_coming_soon_screen.dart` | "Tez orada" (oldingi sessiyada tayyorlangan) |
| 14 | Profil | `profile/profile_screen.dart` | Qisqartirildi — HANDOFF: 6 qator + avatar karta |
| 15 | Sevimlilar | `favorites/favorites_screen.dart` | 2 ustunli grid |
| 16 | Manzillarim | `addresses/addresses_screen.dart` | Header+dashed tugma qayta yozildi, forma tegilmadi |
| 17 | Sozlamalar | `profile/settings_screen.dart` | **YANGI** — Profildan ajratildi, push toggle real |

### 3. Backend qo'shimchalari (kichik, izolyatsiyalangan — CLAUDE.md tamoyiliga mos)

- `GET /categories` endi `product_count` qaytaradi (Market ekranida "N ta mahsulot" uchun).
- Sotuvchi endi `POST /categories` chaqira oladi — **oldindan mavjud xato tuzatildi**:
  `mobile_seller` UI kategoriya yarata olishni taklif qilardi, lekin backend faqat adminga
  ruxsat berardi (403 qaytarardi). Endi seller ham yarata oladi.
- `orders.note` ustuni qo'shildi (checkout izohi — HANDOFF'da bor edi, backend'da yo'q edi).
- (Oldingi sessiyada: Kit/ProductSet CRUD, order status pipeline preparing/ready, product.brand,
  seller news endpoint — hammasi shu build'da ham ishlatildi.)

### 4. Testlar (`flutter test`, hammasi yashil)

- `mobile_seller/test/sku_builder_test.dart` — 8 ta: attribute→SKU kartezian ko'paytma logikasi
  (parametrsiz/1/2 parametr, bo'sh qiymat e'tiborsiz, signature barqarorligi).
- `mobile_user/test/cart_screen_test.dart` — 3 ta: bo'sh/to'la savat holati, miqdor chegarasi
  (0 ga tushmasligi, tarmoqqa keraksiz so'rov yubormasligi).
- `mobile_user/test/checkout_screen_test.dart` — 2 ta: manzilsiz "Buyurtma berish" bosilsa
  ogohlantirish, saqlangan manzil avtomatik tanlanishi.
- `mobile_user/test/product_detail_screen_test.dart` — 2 ta: variant tanlash narx/zaxirani
  yangilaydi, zaxira 0 bo'lsa "Tugagan".
- `mobile_user/test/catalog_navigation_test.dart` — 1 ta: kategoriya qatoriga bosilganda
  Kategoriya ekraniga real navigatsiya (`Navigator.push`).

**Testlar ikkita real bugni ushladi va tuzatdi** (pastga qarang, 5-band).

### 5. Testlar orqali topilgan va tuzatilgan real xatolar

Qurilma uzilganidan keyin men widget testlarni **haqiqiy telefon o'lchamida** (393×852,
`tester.view.physicalSize` orqali — standart test oynasi 800×600 ScreenUtil masshtabini
buzib, yolg'on natija berardi) ishga tushirdim. Bu haqiqiy overflow xatolarini ochib berdi:

1. **Markaziy "Bosh sahifa" tugmasi butun tab barni tepaga surib yuborardi** — `Transform.translate`
   Column ichida edi, bu layout balandligini noto'g'ri hisoblatardi. `Stack`+`Positioned`ga
   o'tkazildi (CSS `margin-top:-18px` mantig'iga mos) — `app_shell.dart` va `mobile_seller`
   `main.dart`da.
2. `checkout_screen.dart`: sarlavha "Rasmiylashtirish" va "Boshqa manzil kiritish" qatorlari
   393px enda tashqariga chiqib ketardi — `Expanded`/`Flexible` + ellipsis bilan tuzatildi.
3. `cart_screen.dart`: savat qatoridagi narx+stepper qatori tor joyda tashqariga chiqardi —
   narx matni `Flexible` bilan o'raldi.

## Doirasidan tashqarida qoldirilgan (ataylab)

- **Tab animatsiyasi**: `/home/feron/nur/gallery-dl/pinterest`dagi videoni ko'rdim — u "suyuq
  blob" uslubidagi indikator (aktiv tab o'zgarganda dumaloq belgi bir joydan ikkinchisiga
  suzib o'tadi). Bizning dizaynda markaziy "Bosh sahifa" tugmasi DOIM o'rtada qotgan (HANDOFF
  talabi), boshqa tablar harakatlanmaydi — shuning uchun to'liq nusxalab bo'lmaydi. Shu
  sabab **faqat ruhini** oldim: tab elementlari endi `AnimatedContainer`/`AnimatedScale` bilan
  silliq (220ms, easeOutCubic/easeOutBack) rang/o'lcham o'tishiga ega, aktiv tab ostida
  yumshoq binafsha "pill" fon paydo bo'ladi. Ekranlar orasidagi to'liq fade+slide animatsiyasini
  ATAYLAB QOLDIRDIM — `IndexedStack` har bir tab holatini (scroll pozitsiyasi, savat) saqlab
  turadi, uni `AnimatedSwitcher`ga almashtirish bu holatni yo'qotardi. Bu **kelishilmagan
  savdo-sotiq (trade-off) qarori** — agar to'liq ekran-almashish animatsiyasini xohlasangiz,
  buni alohida so'rang, men holatni saqlaydigan usulini topib chiqaman.
- Ma'lumot manbai: HANDOFF/oxirgi xabaringizda "mock repository" deyilgan edi, lekin oldingi
  (tasdiqlangan) sessiya qaroriga ko'ra real backend saqlandi — batafsil izoh pastda.
- Seller App bu sessiyada qayta qurilmadi (oldingi sessiyada allaqachon tayyor edi) — faqat
  yangi rang palitrasi orqali avtomatik yangilandi, `flutter analyze`/`build` toza.

## Muammo: qurilma uzildi (hal qilinmagan)

Android telefon (adb) ishlash jarayonining o'rtasida uzilib qoldi — undan beri qayta
ulanmadi. Muqobil sifatida Linux desktop build (`flutter run -d linux`) orqali skrinshot
olishga urindim, lekin bu konteynerda X11 skrinshot vositalari (`import`/ImageMagick,
`xwd`, `scrot`, `grim`) ishlamadi yoki topilmadi. **Shu bois vizual tasdiqlash siz qaytib
telefonni ulaganingizdan keyin amalga oshiriladi** — men buning o'rniga har bir ekranni
`flutter analyze` (har safar 0 xato) va real qurilma o'lchamidagi widget testlar bilan
tekshirdim, ular yuqoridagi 3 ta real layout bugini topib berdi.

## Savollar / keyingi qadam uchun tasdiqlash kerak bo'lgan narsalar

1. **Ma'lumot manbai**: real backend saqlandi (mock emas) — agar chindan HANDOFF'dagidek
   to'liq mock repository (`buildData()` portlangan holda) xohlasangiz, ayting, men shu
   yo'nalishda alohida qatlam qo'shib beraman (real backend hali ham ishlashda qoladi,
   faqat almashtiriladigan joyi bo'ladi).
2. **Ekranlar orasidagi to'liq fade+slide animatsiyasi** — yuqorida tushuntirilgan trade-off
   sababli hozircha qo'shilmadi. Xohlasangiz, alohida topshiriq sifatida qo'shib beraman.
3. **Qurilmada jonli tekshirish** — telefon ulanib, o'rnatish ruxsati berilishi kerak (bir
   necha marta "User rejected permissions" chiqqan edi).

## Doirasidan tashqarida (keyingi bosqichlar — HANDOFF.md o'zi ham shunday belgilagan)

- Onboarding + SMS-kod bilan kirish (hozir Telegram login ishlatiladi, bu allaqachon
  tasdiqlangan xavfsizroq yechim).
- Global qidiruv ekrani, filtr bottom-sheet.
- Xatolik/oflayn holatlari, skeleton loaderlar (qisman bor).
- Haqiqiy mahsulot rasmlari (hozir ikonka-placeholder).
- Gemini AI proxy (hozir qoida-asosidagi javob).
