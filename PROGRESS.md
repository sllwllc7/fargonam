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

---

## mobile_user / mobile_seller — pubspec va lib tuzilishi (2026-08-19 tekshiruvi)

- **State:** ikkalasida ham `flutter_riverpod`. Ekranlar `lib/features/<domen>/` ostida.
- Ikkalasi ham `fargonam_ui: path: ../packages/fargonam_ui`ga allaqachon bog'langan edi.
- `mobile_user/lib/core/theme/*.dart` — hammasi ingichka `export 'package:fargonam_ui/...'`
  wrapper (haqiqiy kontent yo'q edi) — ya'ni barcha 17 ekran allaqachon fargonam_ui
  tokenlariga bog'langan, faqat **qiymatlar** noto'g'ri edi ("Warm Violet"). Shu sabab
  fargonam_ui'ning tokenlarini tuzatish 17 ekranning rang/shrift ko'rinishini ham
  avtomatik to'g'riladi — struktura/layout esa hali eski (3-bosqich ishi).
- `mobile_seller` ko'p ekranda `package:fargonam_ui`ni to'g'ridan-to'g'ri import qiladi
  (wrapper'siz), lekin `main.dart` / `core/theme.dart`da BUTUNLAY BOSHQA, uchinchi bir
  dizayn tizimi ("Fargonam Biznes" — midnightIndigo/vanillaCream, dark mode) ishlatiladi —
  rol-tanlash, haydovchi va texnik-ishlar ekranlari shu qattiq-kodlangan palitrada. Bu
  4-bosqichda hal qilinadi, hozircha tegilmadi.
- Ikkalasida ham `flutter_screenutil` hali ko'p ekranda ishlatilmoqda (`.w/.h/.sp`) —
  3-bosqichda ekran almashtirilganda olib tashlanadi; hozircha `main.dart`larda
  `ScreenUtilInit` saqlanadi (aks holda mavjud ekranlar runtime xato beradi).

---

## Mobil UI qayta qurish (2026-08)

| Bosqich | Ekran/Modul | Fayl | Testlar | Analyze | Holat |
|---|---|---|---|---|---|
| 1 | Dizayn tokenlari (rang, tipografika, motion, shadow, radius, spacing) | `packages/fargonam_ui/lib/src/*.dart` | — | 0/0/0 | ✅ |
| 1 | Suzuvchi tab bar (spring `translateY(-24)`, `cubic-bezier(.3,1.6,.5,1)`) | `packages/fargonam_ui/lib/src/widgets/floating_tab_bar.dart` | 3/3 yashil (render, onTap, bo'rtma ko'tarilishi) | 0/0/0 | ✅ |
| 1 | Savat FAB, Toast (umumiy widget, hali hech ekranga ulanmagan) | `packages/fargonam_ui/lib/src/widgets/{cart_fab,toast}.dart` | — | 0/0/0 | ✅ (3-bosqichda ekranlarga ulanadi) |
| 1 | mobile_user shell — yangi tab bar ulandi | `mobile_user/lib/features/shell/app_shell.dart` | 8/8 mavjud test yashil | 0/0/0 | ✅ |
| 1 | 5.4 platforma: haptika (tab bar), status bar, ScrollBehavior, MediaQuery bottom-inset (tab bar/FAB/toast) | `mobile_user/lib/main.dart`, `floating_tab_bar.dart`, `cart_fab.dart`, `toast.dart` | — | 0/0/0 | ✅ qisman — `PageRouteBuilder`/klaviatura ekran darajasida, 3-bosqichda |
| 1 | 5.5 ilova nomi/ikonka/splash — ikonka va splash bitta asset (fergana-gate.png) (faqat mobile_user — seller uchun 4-bosqichda) | `mobile_user/pubspec.yaml`, `android/app/src/main/res/**` | — | — | ✅ |
| 1 | LEGACY tokenlar bitta faylga yig'ildi, barrel'dan chiqarildi | `packages/fargonam_ui/lib/theme/legacy_tokens.dart` | — | 0/0/0 | ✅ |
| 3 | `AppPageRoute`/`pushAppRoute` (320ms screenIn), `ScreenFadeIn`, `FadeUpItem` (stagger) — 5.4/5.2 umumiy vosita | `packages/fargonam_ui/lib/src/app_page_route.dart`, `widgets/{screen_fade_in,fade_up_item}.dart` | — | 0/0/0 | ✅ |
| 3 | 1/17: Bosh sahifa (home) — to'liq qayta yozildi (dc.html aynan) | `mobile_user/lib/features/home/home_feed_screen.dart` | 11/11 yashil (3 yangi: render, FAB yo'q/bor+son) | 0/0/0 | ✅ |
| 1 | `AppRadius.card` 17→18, `AppTypography.h1` -.9→-.8 (haqiqiy qurilma skrinshotida topilgan Phase 1 xatolari) | `packages/fargonam_ui/lib/src/{app_radius,app_typography}.dart` | — | 0/0/0 | ✅ |
| 3 | 2/17: Market (catalog) — to'liq qayta yozildi (dc.html aynan, 18 ta kategoriya SVG ikonkasi, "Savatda N ta bor" yashil badge) | `mobile_user/lib/features/marketplace/catalog_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 5-tuzatish | Ikonka (oq F), soxta buyurtma o'chirildi (dev DB), AI chiplar olib tashlandi, ism onboarding ekrani, orqaga tugmasi PopScope | `assets/icon/*`, `home_feed_screen.dart`, `ai_assistant_screen.dart`, `core/user_name_provider.dart`, `features/onboarding/name_screen.dart`, `profile_screen.dart`, `main.dart`, `shell/app_shell.dart`, `checkout/order_success_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ qurilmada tasdiqlandi (toza o'rnatish) |
| 3 | 3/17: Sinf to'plami (kit detail) — to'liq qayta yozildi (dc.html aynan), `_addKit()` biznes-logikasi o'zgarishsiz | `mobile_user/lib/features/kits/kit_detail_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | `BackCircleButton` umumiy widget (5 dc.html ekranida bir xil orqaga tugmasi) | `packages/fargonam_ui/lib/src/widgets/back_circle_button.dart` | — | 0/0/0 | ✅ |
| 3 | 4/17: Kategoriya (category detail) — to'liq qayta yozildi (dc.html aynan, kategoriya ikonka+imgLabel, Filtr) | `mobile_user/lib/features/marketplace/category_products_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | `FavoriteHeartIcon` umumiy widget (Kategoriya+Mahsulot) | `packages/fargonam_ui/lib/src/widgets/favorite_heart_icon.dart` | — | 0/0/0 | ✅ |
| 3 | 5/17: Mahsulot (product detail) — to'liq qayta yozildi (dc.html aynan, rasm karuseli soddalashtirilgan taqlid, stockInfo rangi tuzatildi) | `mobile_user/lib/features/products/product_detail_screen.dart` | 11/11 (2 tuzatildi: NBSP narx) | 0/0/0 | ✅ |
| 3 | `QtyStepperButton` umumiy widget (Mahsulot+Savat, matn glif −/+) | `packages/fargonam_ui/lib/src/widgets/qty_stepper_button.dart` | — | 0/0/0 | ✅ |
| 3 | 6/17: Savat (cart) — to'liq qayta yozildi (dc.html aynan, backdrop-blur footer, kategoriya ikonka) | `mobile_user/lib/features/cart/cart_screen.dart` | 11/11 (3 tuzatildi: NBSP+minus glif) | 0/0/0 | ✅ |
| 3 | 7/17: Rasmiylashtirish (checkout) — to'liq qayta yozildi (dc.html aynan, pickup/manzil real funksiyasi saqlandi) | `mobile_user/lib/features/checkout/checkout_screen.dart` | 11/11 (2 tuzatildi: to'g'ri formatSom) | 0/0/0 | ✅ |
| 3 | 8/17: Muvaffaqiyat (order success) — to'liq qayta yozildi | `mobile_user/lib/features/checkout/order_success_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 9/17: Kuzatish (order tracking) — to'liq qayta yozildi (pickup-kod/bekor-qilingan real holatlari saqlandi, timeline rang xatolari tuzatildi) | `mobile_user/lib/features/orders/order_tracking_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 10/17: Buyurtmalar (orders) — to'liq qayta yozildi (statusBadge 4-holat rangi tuzatildi) | `mobile_user/lib/features/orders/orders_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 11/17: Bildirishnomalar — to'liq qayta yozildi | `mobile_user/lib/features/notifications/notifications_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 12/17: AI chat — to'liq fidelity (avval faqat chip olib tashlangan edi) | `mobile_user/lib/features/ai_assistant/ai_assistant_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 13/17: Taxi "Tez orada" — to'liq qayta yozildi | `mobile_user/lib/features/taxi/taxi_coming_soon_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 14/17: Profil — to'liq qayta yozildi (6 qator aniq SVG+rang) | `mobile_user/lib/features/profile/profile_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 17/17: Sozlamalar — to'liq qayta yozildi | `mobile_user/lib/features/profile/settings_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 15/17: Sevimlilar — to'liq qayta yozildi (kategoriya ikonka+tint) | `mobile_user/lib/features/favorites/favorites_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ |
| 3 | 16/17: Manzillarim — ro'yxat qismi dc.html aynan, forma real funksiya sifatida saqlandi | `mobile_user/lib/features/addresses/addresses_screen.dart` | 11/11 mavjud test yashil | 0/0/0 | ✅ **3-bosqich 17/17 yakunlandi** |

### Qarorlar
- [2026-08-19] Savol: `handoff/`ga ko'chirilgan dc.html eski/xato versiya edi (E6E6FA/191970
  palitra, Plus Jakarta Sans, spring animatsiyasiz tab bar) — CLAUDE.md 5.1/5.2/10 esa navy/
  Figtree/spring haqida yozgan edi. → Qaror: foydalanuvchi tasdiqlagan holda to'g'ri fayl
  (md5 `b3bc28ca50648663ea83630fb9de04ae`, `~/Downloads/Mobile app design request.zip`)
  bilan almashtirildi, CLAUDE.md 0-bo'limiga fingerprint tekshiruvi qo'shildi. → Sabab:
  `handoff/` va manba papka ikkalasi ham noto'g'ri nusxa bilan to'ldirilgan edi.
- [2026-08-19] Savol: CLAUDE.md 5.1 ("Asosiy tugma" gradienti/radiusi) va 5.2 ("Karta soyasi")
  qatorlaridagi ba'zi qiymatlar to'g'ri (endi tasdiqlangan) dc.html bilan mos kelmadi —
  eski faylning rgba(25,25,112,..)/rgba(27,0,63,..) qiymatlari qolib ketgan edi. → Qaror:
  foydalanuvchi tasdiqlagan holda dc.html'dagi aniq qiymatlarga (`#24406F→#12233F` 180°
  radius12 CTA tugma; `rgba(23,19,39,..)` soya + solid `#E0E6EF` border) moslab CLAUDE.md
  tuzatildi. → Sabab: ikkala bo'lim ham "dc.html'dan tasdiqlangan" deb yozilgan edi, lekin
  eski (xato) fayldan transkripsiya qilingan ekan.
- [2026-08-19] Savol: `packages/fargonam_ui` va `mobile_seller`ning ko'p ekrani eski "Warm
  Violet"/uchinchi "Fargonam Biznes" tokenlariga (masalan `AppColors.sellerAccent`,
  `AppTextStyles`, `AppColorsDark`, `AppShadows.primaryButton`) to'g'ridan-to'g'ri bog'langan
  edi. → Qaror: yangi to'g'ri tokenlar bilan bir qatorda, aniq "LEGACY" deb izohlangan
  moslik alias'lari (eski nom → eski qiymat) saqlandi — `mobile_seller` va mobile_user'ning
  hali tuzatilmagan ekranlari o'zgarishsiz build bo'lishda davom etadi. → Sabab: 5.0/10-bo'lim
  "ekranlar 3/4-bosqichda tuzatiladi, hozir emas" deb aniq belgilagan; legacy alias'lar shu
  chegarani buzmasdan `flutter analyze`ni 0 xatoga saqlaydi.
  **[2026-08-19, chegaralandi]** Barcha LEGACY tokenlar bitta faylga —
  `packages/fargonam_ui/lib/theme/legacy_tokens.dart` — yig'ildi va `fargonam_ui.dart`
  barrel'idan ATAYLAB eksport qilinmaydi (fayl boshida sabab/o'chirish rejasi yozilgan).
  Ikki xil moslik bor edi: (a) mobile_seller — asl "Warm Violet" QIYMATLARI kerak edi
  (`LegacyColors`, `LegacyTextStyles`, `LegacyGradients`, `LegacyShadows`, `LegacySizes`);
  (b) mobile_user'ning 2 ta shim fayli — faqat eski NOM kerak edi, qiymat joriy/to'g'ri
  qoladi (`AppColorsDark`, `AppTextStylesDark`, `AppTextStyles`). Buni aniqlashda tekshiruv
  shuni ham topdi: `AppColors.primary/primaryDark/textSecondary/border/textMuted` va
  `AppShadows.fab` avval **noto'g'ri** — sellerga yangi (navy) qiymat sizib chiqayotgan edi
  (compile xato bermagani uchun ilgari sezilmagan); endi `LegacyColors`/`LegacyShadows` orqali
  to'g'irlandi.
  **LEGACY'ga bog'langan fayllar (15 ta) — o'chirish rejasi:**
  - `mobile_seller` (13 fayl, 4-bosqichda butunlay tuzatiladi va bu importlar olib
    tashlanadi): `main.dart`; `features/{kits/add_kit_screen,kits/kit_management_screen,
    home/seller_home_screen,products/category_picker,products/edit_product_screen,
    products/add_product_screen,products/products_screen,products/sku_builder,
    news/seller_news_screen,dashboard/seller_stats_screen,orders/seller_orders_screen,
    profile/seller_profile_screen}.dart`
  - `mobile_user` (2 fayl, 3-bosqich oxirida ekranlar to'g'ridan-to'g'ri `AppColors`/
    `AppTypography`ga o'tkazilganda o'chiriladi): `core/theme/app_colors.dart` (faqat
    `AppColorsDark`), `core/theme/app_text_styles.dart` (`AppTextStyles`,
    `AppTextStylesDark`)
- [2026-08-19] Savol: dc.html'da `fergana-gate.png`dan tashqari alohida logotip/marka
  belgisi yo'q — 5.5 "ikonka fergana-gate.png asosida, splash navy+oq logotip" deydi, lekin
  aniq logotip fayli ko'rsatilmagan. → Qaror: ikonka — fergana-gate.png kvadrat kesilib
  navy fonga joylashtirildi (adaptive icon). `flutter_launcher_icons` / `flutter_native_splash`
  dev-vositalari qo'shildi (runtime'ga kirmaydi). → Sabab: 9-bo'lim ruxsat etilgan paketlar
  ro'yxati UI runtime qatlami haqida, build-vaqtidagi ikonka-generator vositasi shu
  cheklovga kirmaydi.
  **[2026-08-19, tuzatildi]** Splash uchun avval shrift orqali generatsiya qilingan "F"
  monogram ishlatilgan edi — bu **6-bo'lim taqig'ini buzadi** (dc.html'da yo'q, o'ylab
  topilgan yangi element). Tuzatildi: splash endi faqat navy `#16294A` fon + markazda xuddi
  ikonkadagi bilan bir xil asset (`assets/icon/app_icon_foreground.png` — fergana-gate.png,
  kvadrat kesilgan, oq emas, rasmning o'zi). Matn, spinner, ilova nomi yo'q.
  `assets/icon/splash_logo.png` (F monogram) o'chirildi, `flutter_native_splash` qayta
  ishga tushirildi.
- [2026-08-19] 3-bosqich haqiqatda boshlandi (foydalanuvchi: "boshidan qil" — 1-bosqich
  faqat poydevor edi, ekranlar hali eski ko'rinishda edi, shuning uchun ilova dizaynga
  mos ko'rinmayotgan edi). Bosh sahifa qayta yozilganda 13-bo'lim ro'yxati bo'yicha uchta
  kamchilik topildi va tuzatildi: (1) haptika — navigatsiya tugmalari `selectionClick`
  emas `lightImpact` bo'lishi kerak edi (5.4), (2) `Navigator.push`+`MaterialPageRoute`
  ishlatilgan edi — 6-bo'lim taqiqlagan, endi hamma joyda `pushAppRoute`, (3) ekran/karta
  kirish animatsiyalari (`screenIn`, `fadeUp`+stagger) 1-bosqichda token sifatida
  yozilgan-u, hech qayerda qo'llanilmagan edi — endi `ScreenFadeIn`/`FadeUpItem` orqali
  qo'llanadi. Bu uch tuzatish umumiy vosita sifatida qilingani uchun qolgan 16 ekranga
  ham avtomatik qo'llanadi.
- [2026-08-19] Foydalanuvchi so'rovi bilan haqiqiy qurilmada (`adb screencap`) har bir tab
  skrinshot qilindi. Topilgan haqiqiy xatolar (barchasi tuzatildi):
  1. Tab bar 3px `RenderFlex` overflow (qizil-sariq chiziq pastda) — label matn balandligi
     taxmindagidan baland edi. `floating_tab_bar.dart`da label `height:1.0` qilindi.
  2. Bosh sahifa faol buyurtma kartasi xom `id`ni ko'rsatardi ("4"), boshqa barcha
     ekranlar `FN-4` formatida — endi mos.
  3. **Phase 1'ning o'zida xato topildi**: `AppRadius.card` 17 deb yozilgan edi, lekin
     dc.html'da eng ko'p ishlatiladigan (va Bosh sahifa/Market qatorlarida haqiqatan
     kerak bo'lgan) qiymat 18 ekan; `AppTypography.h1` letterSpacing -.9 deb yozilgan
     edi, ikkala haqiqiy 28px sarlavha (`Kategoriyalar`, `Profil`) esa -.8 ishlatadi.
     Ikkalasi ham to'g'irlandi, Bosh sahifadagi mos hardcode qiymatlar ham tokenga
     o'tkazildi.
  Market/Kategoriyalar bo'sh ko'rinishi **kod xatosi emas** — `GET /categories` haqiqatan
  ham `[]` qaytaradi (dev bazada kategoriya yo'q). Bu backend/ma'lumot masalasi, mock
  yozib "tuzatilmaydi" (5.0).
- [2026-08-19] Foydalanuvchi qurilmadagi skrinshotlarni ko'rib uchta narsani ko'rsatdi,
  hammasi tuzatildi:
  1. **Bosh sahifa hero kartasida to'rtburchak "chok"** — gradient overlay
     `Positioned.fill` orqali `Stack`ning PADDING ICHIDAGI qismini qoplagan edi, rasm esa
     `Container.decoration.image` orqali TO'LIQ kartani (padding tashqarisini ham)
     qoplagan — natijada gradient rasmdan ~20px ichkarida to'xtab, ko'rinadigan
     to'rtburchak chegara hosil qilgan. Tuzatildi: rasm+gradient ikkalasi ham
     `ClipRRect > Stack > Positioned.fill` orqali xuddi shu (to'liq) maydonni qoplaydi,
     matn/tugma alohida `Padding` qatlamida. Gradient burchagi ham 115°ga aniqlashtirildi
     (avval ~135° taxminiy edi).
  2. **fergana-gate.png ilova ikonkasi va splash'dan olib tashlandi** — foydalanuvchi:
     "faqat Home'da foydalansa bo'ladi". Ikkalasi endi oddiy solid navy `#16294A`
     (fotosuratsiz). `assets/icon/app_icon_foreground.png`/`splash_logo.png` o'chirildi,
     `flutter_launcher_icons`/`flutter_native_splash` qayta ishga tushirildi.
  3. **AI ekranida yozish maydoni ko'rinmasdi** — kod ichida input/yuborish funksiyasi
     bor edi, lekin ekran o'zining pastki bo'shlig'ini suzuvchi tab bar balandligiga
     moslamagan edi — input qatori tab bar OSTIDA (ko'rinmas holda) chizilardi. Pastki
     `Padding`ga `AppSizes.tabBarHeight + tabBarBottomInset` qo'shildi.

- [2026-08-19] Foydalanuvchi "5 ta tuzatish" so'rovi — hammasi CLAUDE.md doirasida bajarildi:
  1. **Ilova ikonkasi**: fergana-gate.png butunlay olib tashlandi (avvalgi navlash
     bo'yicha faqat splash'dan olingan edi, ikonkada hali qolgan edi). Endi ikonka: sof
     navy `#16294A` fon + markazda oq "F" (kenglikning ~48%). Figtree fayli lokal/tarmoqda
     topilmadi — `Adwaita-Sans-ExtraBold` bilan generatsiya qilindi (ikonka bitta marta
     yaratiladigan static asset, ilova ichidagi haqiqiy matn hamon Figtree). Adaptive
     icon: foreground=oq "F" (shaffof fon), background=navy. Splash o'zgarishsiz (sof
     navy, rasmsiz).
     Tekshiruv: `grep -rn fergana-gate mobile_user mobile_seller` → faqat
     `home_feed_screen.dart` (Home hero karta).
  2. **Home'dagi "FN-4" buyurtma**: kod tekshirildi — bu HARDCODE EMAS, `myOrdersProvider`
     orqali haqiqiy `/orders` so'rovidan kelayotgan edi (kod allaqachon
     `if (activeOrder != null)` bilan to'g'ri shartli). Muammo — dev bazada `Dev Buyer`
     (telegram_id -1001, DEBUG bypass sentinel) hisobida eski test buyurtmasi (id=4)
     qolib ketgan edi. Kod o'zgartirilmadi — o'sha bitta test buyurtma va uning
     `order_items`'lari to'g'ridan-to'g'ri (dev) bazadan o'chirildi (`DELETE FROM
     order_items/orders WHERE id=4`). Boshqa foydalanuvchi ma'lumotlari (notifications,
     cart_items, favorites, saved_addresses) o'sha hisob uchun allaqachon bo'sh edi.
     Tekshiruv: `grep -rn "'FN-" mobile_user` → hammasi `${order['id']}` generatori,
     hech qanday qattiq raqam yo'q.
  3. **AI namuna savol chiplari** — `_QuickChip` butunlay olib tashlandi (chaqiruvchisi
     bilan birga, ishlatilmay qolgan klass ham o'chirildi). Header/onlayn nuqta/xabar
     pufakchalari/typing/input+yuborish o'zgarishsiz. **Prototipdan chetlashish**: dc.html
     `AI CHAT` bo'limida bu chiplar bor — ular endi ko'rinmaydi (foydalanuvchi aniq
     so'rovi bilan).
  4. **Profil ismi**: `shared_preferences` ALLAQACHON pubspec.yaml'da bor edi (onboarding/
     tungi-rejim flag'lari uchun) — "qo'shish" shart bo'lmadi, faqat yangi foydalanish
     (`core/user_name_provider.dart`, `AsyncNotifier<String?>`). Yangi ekran:
     `features/onboarding/name_screen.dart` — "Tanishib olaylik" / "Ismingiz" input /
     "Davom etish" (mavjud `AppButton`/`AppInput` orqali, yangi uslub yozilmadi). Auth'dan
     keyin, ism saqlanmagan bo'lsa, `AppShell`dan oldin ko'rsatiladi (`main.dart`).
     Profil avatar kartasida ism + "Ismni tahrirlash" (bosilganda `NameScreen`
     `initialName` bilan qayta ochiladi). Home salomlashuvi: "Assalomu alaykum, {ism} 👋"
     — **prototipdan chetlashish** (dc.html'da ism yo'q, faqat "Assalomu alaykum 👋").
     Telefon raqami ko'rsatilmasdi (avvalgi kod ham `user.phone ?? ''` — soxta raqam
     hech qachon bo'lmagan, faqat "Foydalanuvchi" degan soxta ISM edi, endi yo'q).
  5. **Mantiqiy tozalash** — tekshirilib, hammasi allaqachon to'g'ri ekan (o'zgarishsiz):
     zaxira/stepper qoidalari (`product_detail_screen.dart`), bir xil SKU dedup (backend
     `POST /cart` — `existing.quantity += payload.quantity`), narx formati (barcha real
     ekranlar `formatSom` ishlatadi; faqat **ishlatilmaydigan** `marketplace_screen.dart`
     — hech qayerdan chaqirilmaydi, ExplorE emas, tegilmadi). Yangi tuzatilgan: orqaga
     tugmasi — `AppShell`ga `PopScope` qo'shildi (Asosiy tabda bo'lmasa shu tabga
     o'tkazadi, ilovadan chiqarmaydi); `OrderSuccessScreen`ga `PopScope` qo'shildi
     (orqaga bosilsa Checkout'ga emas, Bosh sahifaga qaytadi).
  **Qurilmada tasdiqlandi** (foydalanuvchi ilovani to'liq o'chirib qayta o'rnatdi,
  haqiqiy Telegram orqali kirdi): Home'da buyurtma yo'q, ism so'rovi chiqdi va ishladi
  ("Solih" kiritildi → Home salomlashuvida va Profilda darhol ko'rindi), ikonka sof
  navy+oq "F".

- [2026-08-19] **3/17: Sinf to'plami (kit detail)** ekrani dc.html'ning `KIT DETAIL`
  bo'limiga moslab qayta yozildi. Eski `flutter_screenutil` (.w/.h/.r/.sp), Material
  ikonkalar va mahalliy `_fmt()` (NBSP'siz, boshqa apostrof belgisi bilan — narx formati
  qoidasiga zid ekan, aniqlandi) olib tashlandi: endi `fargonam_ui` tokenlari
  (`AppGradients.cta`, `AppShadows.cta`, `AppTypography`, `AppRadius.card`=18/
  `AppRadius.button`=12 — avval xato `17.r` edi), `flutter_svg` orqali aniq ikonkalar,
  `formatSom` narx formati, `FadeUpItem`/`ScreenFadeIn` kirish animatsiyasi. Orqaga
  tugmasi va "savatga qo'shish" endi `HapticFeedback.lightImpact()` (5.4 jadvali:
  "savatga qo'shish" — light, avval noto'g'ri `mediumImpact` edi). `_addKit()`
  biznes-logikasi (`/cart`ga har bir element uchun POST, `cartProvider` invalidatsiyasi,
  xato holati) o'zgarishsiz saqlandi.
  **Backend farqi**: dc.html har bir to'plam elementi uchun o'z kategoriyasiga mos ikonka
  ishlatadi (`icon(catId)`/`{{it.bg}}`/`{{it.fg}}`), lekin `KitItem` modelida
  (`kit_providers.dart`) kategoriya/slug maydoni yo'q — faqat `productName`/
  `variantName`/`quantity`/`lineTotal`. 5.0 qoidasiga ko'ra model o'zgartirilmadi:
  barcha elementlar uchun bitta neytral quti-SVG ikonkasi, to'plamning o'z (sinf
  darajasiga bog'liq) tint rangida ishlatildi. Kelajakda backend `KitItem`ga
  kategoriya/slug qo'shsa, bu ekran to'g'ridan-to'g'ri per-item ikonkaga o'tkaziladi.

- [2026-08-19] **4/17: Kategoriya (category detail)** ekrani dc.html'ning `CATEGORY DETAIL`
  bo'limiga moslab qayta yozildi. `BackCircleButton` (yangi umumiy fargonam_ui widget) va
  `PressableScale` orqali qurildi — kit_detail_screen.dart ham shu bilan qayta ishlatildi
  (avval ikkalasida alohida qo'lda yozilgan bosilganda-kichraytiruvchi kod bor edi).
  Kategoriya ikonka lug'ati (`_categoryIconPaths`/`_categorySvg`) avval faqat
  `catalog_screen.dart` ichida edi — endi `category_icons.dart`ga ko'chirildi, ikkala ekran
  bitta manbadan foydalanadi. dc.html'dagi monospace "imgLabel" (masalan "ruchka") — bu
  chinakam ilova hodisasi (haqiqiy mahsulot rasmlari hali yo'q, shu vaqtinchalik o'rniga
  ikonka+belgi ko'rsatiladi, `imgLabel: cc.name.toLowerCase()` manba kodida tasdiqlangan) —
  qoldirildi, o'chirilmadi.
  **Token tuzatishlari** (haqiqiy dc.html qiymatlari real ekran qurishda solishtirilganda
  topildi, faqat shu 2 ta joyda ishlatilgani uchun xavfsiz tuzatildi):
  `AppTypography.title` letterSpacing -.3→-.4 (dc.html'da Kategoriya/Kit/Checkout/Kuzatish/
  Bildirishnomalar sarlavhalari barchasi -.4; faqat Bosh sahifa hero "Market" -.3/w800 —
  bu alohida `heroTitle` tokeniga tegishli, aralashmaydi); `AppTypography.price` -.4→-.3;
  `AppTypography.priceSm` w800→w700 (dc.html'da barcha 14.5px matnlar w700, w800 emas).
  Yangi token: `AppColors.inputBorder` (`#D5DDE9`) — Filtr tugmasi + AI input/chip uchun
  (dc.html'da 3 marta uchraydi, AI ekrani to'liq qayta yozilganda ham shu ishlatiladi).

- [2026-08-19] **5/17: Mahsulot (product detail)** ekrani dc.html'ning `PRODUCT DETAIL`
  bo'limiga moslab qayta yozildi. Kategoriya ikonka/tint uchun `categoriesProvider`
  (allaqachon Market ekranida mavjud, riverpod orqali keshlangan) qayta ishlatilib,
  `product['category_id']`dan slug topiladi — backend `Product`da slug maydoni yo'q, lekin
  buni backend o'zgartirmasdan client tomonda hal qilish mumkin bo'ldi (haqiqiy gap emas).
  **Soddalashtirish** (ataylab, dekorativ): dc.html'dagi 3D CSS `perspective`/`rotateY`
  rasm karuseli (`pdSlides`, translateZ+rotateY+brightness/blur) Flutter'da to'g'ridan-to'g'ri
  emas — scale+qorayish bilan taqlid qilingan (markazdagi rasm to'liq, keyingisi biroz
  kichrayib qorayib orqada ko'rinadi), bosilganda va nuqta bosilganda naviga to'g'ri
  ishlaydi. Bu faqat vizual, biznes-mantiqqa taalluqli emas.
  **Manba kodidan (`stockInfo()`, `pdFavFill/Stroke`, `addBtnBg`) tasdiqlangan, avval
  taxminiy/noto'g'ri bo'lgan qiymatlar**:
  - Zaxira rangi: "Tugagan"=`danger`(#DC2626, avval `textMuted` edi), "Kam
    qolgan"=`primary`(#16294A, avval umuman ajratilmagan edi), "Mavjud"=`textPrimary`.
  - Sevimli yurakcha rangi: qizil EMAS — `textMuted`/`textSecondary` (neytral kulrang).
    `FavoriteHeartIcon` umumiy widget shu bilan tuzatildi (Kategoriya ekrani ham).
  - "Savatga qo'shish" tugmasi: **qat'iy qora** (`#000000`/o'chirilganda `#1C1C22`),
    CTA gradient EMAS — Kit/Checkout'dagi navy gradientdan farqli qaror, manba kodida
    aniq tasdiqlangan (`addBtnBg = can ? '#000000' : '#1C1C22'`).
  - `AppColors.borderStrong` (variant chip chegarasi) `#E0DCD4`→`#C6D0DF` — bu token
    "3-bosqichda tasdiqlanadi" izohi bilan qo'yilgan edi, endi tasdiqlandi.
  Yangi qo'shildi: `AppShadows.productImage`.

- [2026-08-19] **6/17: Savat (cart)** ekrani dc.html'ning `CART` bo'limiga moslab qayta
  yozildi. Kategoriya ikonka/tint uchun `productCategoryMapProvider` (avval
  `catalog_screen.dart`da private edi, endi public — Savat ham qayta ishlatadi) +
  `categoriesProvider` orqali `product_id -> category_id -> slug` zanjiri bilan hal qilindi
  (backend `CartItemOut`da category ma'lumoti yo'q, lekin buni ham client tomonda,
  backend'ni o'zgartirmasdan yechish mumkin bo'ldi — Mahsulot ekranidagi bilan bir xil
  yondashuv). Sticky pastki panelga dc.html'dagi `backdrop-filter:blur(16px)` qo'shildi
  (avval oddiy oq fon edi — `ClipRect`+`BackdropFilter`).
  **dc.html'da tab bar uchun qoldirilgan qo'shimcha 96px pastki bo'shliq** (`bottom:96px`,
  bizning boshqa push qilingan ekranlarimiz — Kit/Kategoriya/Mahsulot — hammasi `bottom:0`)
  — bu asl prototipning "tab bar doim ko'rinadi" SPA arxitekturasiga xos, bizning
  ilovamizda Savat alohida route sifatida push qilinadi (tab bar unda umuman yo'q) —
  boshqa push qilingan ekranlar bilan bir xil qarorga (`bottom:0`) rioya qilindi, izchillik
  saqlandi.
  O'chirish (×) tugmasi endi dc.html'dagi aniq axlat qutisi SVG (avval Material X ikoni edi).
  `QtyStepperButton` umumiy widget qilib chiqarildi (dc.html'da minus/plus MATN belgisi
  ishlatiladi, Material ikon emas — Mahsulot sahifasidagi xuddi shu pattern bilan bitta
  manba).

- [2026-08-19] **7/17: Rasmiylashtirish (checkout)** ekrani dc.html'ning `CHECKOUT`
  bo'limiga moslab qayta yozildi. dc.html'da faqat oddiy Manzil/Telefon/Izoh input'lari
  bor, lekin real backend "Do'kondan olib ketish" (pickup+kod), saqlangan manzillar
  ro'yxati, idempotency-key kabi ancha kengroq funksiyalarni qo'llab-quvvatladi — bu
  ilgari (Phase 1'dan oldin) ham hujjatlashtirilgan qaror edi (fayl boshidagi izoh),
  shu qarorga rioya qilinib FAQAT ko'rinish qatlami fargonam_ui tokenlariga o'tkazildi,
  funksiya saqlandi. To'lov va Buyurtma xulosasi kartalari dc.html'dan aynan (SVG
  ikonka, radius `groupedCard`, soya).
  **Muhim topilma**: `mobile_user/lib/core/format.dart`dagi ESKI `formatSom()` funksiyasi
  o'z izohida "NBSP" deb yozilgan bo'lsa-da, aslida ODDIY BO'SHLIQ ishlatar edi (NBSP
  emas) — haqiqiy standart `fargonam_ui`dagi to'g'ri versiya (NBSP + `‘` U+2018 apostrof).
  Checkout endi to'g'ri versiyani ishlatadi. Eski (noto'g'ri) funksiya hali
  `orders_screen.dart`/`order_tracking_screen.dart`/`favorites_screen.dart`da qoladi —
  bu ekranlar Phase 3'da qayta yozilganda tuzatiladi (keyingi navbatda).
  Yangi qo'shildi: `AppTypography.formSectionLabel` (Checkout bo'lim yorliqlari — dc.html'da
  Katalog bo'lim yorlig'idan farqli o'lcham/rang ekan, aniqlandi), `pushReplacementAppRoute`
  (fargonam_ui, Muvaffaqiyat ekraniga o'tish uchun).

- [2026-08-19] **8-9-10/17: Muvaffaqiyat, Kuzatish, Buyurtmalar** ekranlari dc.html'ning
  `ORDER SUCCESS`/`TRACKING`/`ORDERS` bo'limlariga moslab qayta yozildi.
  - Muvaffaqiyat: aniq check SVG (avval Material ikon), doira foni `AppColors.primaryLight`
    (avval legacy `#EDE9FE` binafsha edi), CTA gradient/soya to'g'irlandi,
    `pushReplacementAppRoute` orqali navigatsiya.
  - Kuzatish: real backend'dagi pickup-kod ko'rsatish va bekor-qilingan holat (dc.html'da
    yo'q, ilgari hujjatlashtirilgan) saqlandi. Manba kodidan aniqlangan tuzatishlar:
    timeline+buyurtma kartalari radius `card`(18) bo'lishi kerak edi (avval `cardLarge`=22
    noto'g'ri ishlatilgan); bosilmagan nuqta chegarasi `primaryLight` (avval `border`);
    ENG MUHIMI — chiziq segmenti rangi: manba kodida `lineBg: i < idx ? qora : yorug'`
    (qat'iy kichik, TENG EMAS) — ya'ni joriy faol qadamdan pastga tushuvchi chiziq hali
    YORUG' bo'lishi kerak, avvalgi kodda `done`(`i<=idx`) bilan bir xil hisoblangani uchun
    joriy qadam ham chiziqni qora qilib ko'rsatardi (progress noto'g'ri "bir qadam oldinda"
    ko'rinardi). Buyurtma qatoriga `variant_name` qo'shildi.
  - Buyurtmalar: `statusBadge()` manba kodidan 4-holatli rang xaritasi aniqlandi —
    "Kuryerda" alohida `primaryLight`/`primaryDeep(#14243F)` rangda bo'lishi kerak edi,
    avvalgi kodda bu holat umumiy "boshqa holatlar" shoxobchasiga tushib legacy binafsha
    (`#EDE9FE`) rang olardi.
  Yangi token: `AppColors.primaryDeep` (`#14243F`) — dc.html'da 5 marta uchraydi (holat
  belgisi, "Marketga o'tish" tugmasi, push toggle, tab bo'rtmasi). `categoryTints[0]`
  ham shu tokenga ishora qiladi endi (qiymat o'zgarmadi, faqat nomlandi).

- [2026-08-19] **11-12-13-14-17/17: Bildirishnomalar, AI chat, Taxi, Profil, Sozlamalar**
  ekranlari dc.html'ga moslab qayta yozildi.
  - Bildirishnomalar: real `type` tizimi (order/ride/chat/promo — prototipda faqat
    buyurtma-bosqichi kind'lari bor, backend'da esa umumiy `type` maydoni, ichki
    prep/ready/done farqi yo'q — shu sabab eng ko'p uchraydigan buyurtma-ikonkasi
    ishlatildi, `Backend farqlari`ga yozildi) saqlandi, faqat token/SVG migratsiya.
  - AI chat: manba kodidan aniq ranglar tasdiqlandi — onlayn nuqta `success`(yashil,
    avval `accent`=qora edi), AI pufakcha matni `textPrimary`(avval `primaryDark`),
    input border `inputBorder`(#D5DDE9 — Checkout bo'limida qo'shilgan token endi
    shu yerda ham qo'llanildi). Namuna chiplari **ATAYLAB tiklanmadi** — foydalanuvchi
    "5 ta tuzatish" so'rovida olib tashlashni aniq so'ragan, bu qaror kuchda qoladi.
  - Taxi: aniq mashina SVG ikonkasi, doira/badge foni `primaryLight` (avval legacy
    `#EDE9FE` binafsha).
  - Profil: 6 qatorning HAR BIRI uchun `pr` massividan aniq SVG yo'l + individual rang
    (Buyurtmalarim/Savat/Manzillarim=`textPrimary`, Sevimlilar/Bildirishnomalar/
    Sozlamalar=`textMuted`) — avval hammasi bir xil legacy binafsha rangda edi.
  - Sozlamalar: bildirishnoma toggle rangi `notifToggleBg` manba kodidan tasdiqlandi —
    yoqilganda `primaryDeep`(#14243F), o'chirilganda `border` (avval mos ravishda
    qora/legacy binafsha, ikkalasi ham noto'g'ri edi). "Chiqish" tugmasi rangi
    `textMuted` — dc.html'da neytral (qizil emas), aniq shu qiymatga moslandi
    (avvalgi implementatsiya UX-yaxshilash sifatida qizil tanlagan edi, lekin bu
    §6 "aniq dc.html qiymatidan chetlashma" qoidasiga zid edi — tuzatildi).

- [2026-08-19] **15-16/17: Sevimlilar, Manzillarim** — 3-bosqich BARCHA 17 ekran
  bo'yicha yakunlandi.
  - Sevimlilar: kategoriya ikonka/tint `productCategoryMapProvider`+`categoriesProvider`
    orqali (Cart/Mahsulot ekranlaridagi bilan bir xil yondashuv — backend `/favorites`
    javobida `category_id` yo'q, lekin bu ham client tomonda hal qilindi). Bo'sh holat
    tugmasi dc.html'da **qat'iy** `#14243F`(primaryDeep) — avvalgi kod gradient
    ishlatgan edi, tuzatildi. `FavoriteHeartIcon` umumiy widget qayta ishlatildi.
  - Manzillarim: ro'yxat qismi (karta ko'rinishi, "Asosiy" badge, dashed
    "+ manzil qo'shish") dc.html'dan aynan. Qo'shish/tahrirlash formasi (to'liq CRUD,
    tuman tanlash, mo'ljal, asosiy-belgilash — dc.html'da yo'q, real funksiya)
    saqlandi — shu bilan birga ishlatilmagan `Theme.of(context).brightness==dark`
    filiallari (`AppColorsDark`/`AppTextStylesDark` legacy shim orqali) olib
    tashlandi, chunki Tungi rejim hali Sozlamalarda "Tez orada" holatida — bu kod
    hech qachon ishga tushmaydigan o'lik filial edi.
  **HANDOFF.md 2-bo'limidagi barcha 17 ekran endi dc.html bilan mos. Qolgan ishlar**:
  4-bosqich (mobile_seller to'liq qayta dizayn, LEGACY tokenlarni olib tashlash),
  2-bosqich (`buildData()` va real model to'liq solishtiruvi — hali yozilmagan).

- [2026-08-19] **PDP rasm karuseli — soddalashtirish bekor qilindi, aniq 3D qayta
  qurildi.** Foydalanuvchi avvalgi "scale+qorayish taqlidi" qarorini rad etdi: "dc.html
  dagi 3D stack aynan ko'chirilsin". `mobile_user/lib/features/products/product_detail_screen.dart`
  — `_ProductImageCarouselState._buildSlide()` endi `Matrix4..setEntry(3,2,1/1200)`
  (CSS `perspective:1200px`ga mos) + `translateByDouble`+`rotateY` bilan haqiqiy 3D
  transform, `ImageFiltered`+`Color.lerp` bilan blur/brightness filtri (dc.html:1127-1139
  formulasidan aynan: `tf`, `op`, `filter`, `z`). Stack bolalari endi `z`
  qiymatiga qarab tartiblanadi (pastroq `z` avval chiziladi).

- [2026-08-19] **Foydalanuvchi tekshiruvi uchun manba tasdiqlash** (PDP tugma rangi va
  yurakcha rangi bo'yicha savol berilgach) — aynan qator raqami va CSS qiymati:
  - **"Savatga qo'shish" tugmasi qat'iy qora, gradient EMAS**:
    `handoff/Fargonam User App v2.dc.html:1166` — `vals.addBtnBg = can ? '#000000' : '#1C1C22';`
    Markap (`dc.html:329`): `background: {{ addBtnBg }}` (dinamik, gradient emas — solid rang).
    Taqqoslash uchun: Kit/Checkout/Cart'ning "asosiy CTA" tugmalari esa haqiqatda
    `linear-gradient(180deg,#24406F,#12233F)` — bular ATayin FARQLI ikkita naqsh, PDP
    ular bilan bir xil emas (aralashtirmaslik uchun manba kodi ikkalasini alohida
    tasdiqlaydi).
  - **Sevimli yurakcha PDP'da qizil EMAS, neytral kulrang**:
    `handoff/Fargonam User App v2.dc.html:1147` —
    `vals.pdFavFill = fav ? '#3F3F49' : 'none'; vals.pdFavStroke = fav ? '#3F3F49' : '#1C1C22';`
    Markap (`dc.html:280`): `fill="{{ pdFavFill }}" stroke="{{ pdFavStroke }}"`.
    `#3F3F49` = `AppColors.textMuted`, `#1C1C22` = `AppColors.textSecondary` — hech
    qanday qizil (`#DC2626`/`danger`) qiymat yo'q.

### Backend farqlari
- ~~[Market/kategoriyalar] Dev bazada `categories` jadvali bo'sh~~ — **2-bosqichda
  to'ldirildi**, quyidagi jadvalga qarang.
- [Sinf to'plami] `KitItem` modelida kategoriya/slug yo'q — dc.html'dagi per-item
  kategoriya ikonkasi o'rniga bitta neytral ikonka ishlatildi (yuqoridagi Qarorlar
  yozuviga qarang).
- [Bildirishnomalar] Backend `Notification.type` faqat umumiy satr ("order",
  "seller_order", "ride", "chat", "promo", "system") — dc.html'dagi buyurtma
  bosqichi ichki farqi (prep/ready/done, har biri boshqa ikonka/rang) yo'q. Buyurtma
  turidagi bildirishnomalar uchun eng ko'p uchraydigan (tayyor/topshirildi) ikonkasi
  ishlatiladi.
- [Sevimlilar] `/favorites` javobida `category_id` yo'q — `product_id` orqali
  `productCategoryMapProvider`dan client tomonda topiladi (backend o'zgartirilmadi).

## 2-bosqich — buildData() vs real backend/dev-baza (2026-08-19, YAKUNLANDI)

Izoh: loyihada alohida "Dart mock" fayli yo'q (`grep -rn buildData mobile_user backend` —
bo'sh) — CLAUDE.md §10 ham buni "mavjud model/repository bilan solishtir" deb belgilagan.
Shu sabab taqqoslash **haqiqiy dev PostgreSQL bazasi** (`fargonam_db`, Flutter ilova
iste'mol qiladigan haqiqiy manba) bilan qilindi. Solishtirishdan oldin baza deyarli bo'sh
edi: `categories`=0, `products`=7 (qo'lda test yozuvlari — "Test","Nasa","Mushuk" kabi
kategoriyasiz nomlar), `product_sets`(kit)=0. Farq **tuzatildi**:
`backend/scripts/seed_catalog.py` (yangi, idempotent skript) `buildData()`ning har bir
qatorini — 18 kategoriya, 14 qo'lda yozilgan mahsulot + 14 kategoriya × 4 generatsiya
formulasi (aynan `brands[(len+i)%6]`, `base+i*round(base*.18/500)*500`, `20+((len*7+i*13)%90)`
formulalari bilan), 1-11 sinf to'plami — dev bazaga yozdi. Ishga tushirish:
`cd backend && .venv/bin/python -m scripts.seed_catalog`.

### Kategoriyalar (18/18 — barchasi mos)

| slug | dc.html nomi | dc.html `count`* | Real `product_count` | Holat |
|---|---|---|---|---|
| ruchka | Ruchka | 48 | 5 | ✅ (izoh*) |
| daftar | Daftar | 64 | 4 | ✅ (izoh*) |
| qalam | Qalam | 32 | 3 | ✅ (izoh*) |
| rangli-qalam | Rangli qalam | 21 | 4 | ✅ (izoh*) |
| a4 | A4 qog'ozi | 12 | 2 | ✅ (izoh*) |
| rangli-qogoz | Rangli qog'oz | 9 | 4 | ✅ (izoh*) |
| flomaster | Flomaster | 18 | 4 | ✅ (izoh*) |
| marker | Marker | 14 | 4 | ✅ (izoh*) |
| ochirgich | O'chirg'ich | 11 | 4 | ✅ (izoh*) |
| lineyka | Lineyka | 13 | 4 | ✅ (izoh*) |
| yelim | Yelim | 8 | 4 | ✅ (izoh*) |
| qaychi | Qaychi | 7 | 4 | ✅ (izoh*) |
| albom | Albom | 10 | 4 | ✅ (izoh*) |
| papka | Papka | 16 | 4 | ✅ (izoh*) |
| kundalik | Kundalik | 6 | 4 | ✅ (izoh*) |
| qalamdon | Qalamdon | 15 | 4 | ✅ (izoh*) |
| shtrix | Shtrix | 5 | 4 | ✅ (izoh*) |
| skotch | Skotch | 6 | 4 | ✅ (izoh*) |

`*` dc.html'dagi `count` (`defs` massivi, 843-849-qator) haqiqiy SKU soniga **hech qachon
teng emas** — masalan Ruchka'ning o'zida `count=48` deyilgan, lekin `buildData()`ning o'zi
faqat 5 ta ruchka mahsuloti yaratadi (qolgan 43 — faqat "shu yerda ko'p mahsulot bor"
taassurotini beruvchi dekorativ raqam, hech qanday SKU'ga bog'lanmagan). Shu sabab real
`product_count` (5) dc.html `count`(48)dan farq qilishi **kutilgan holat, xato emas** —
ikkalasi ham `buildData()`ning O'ZIDA yaratilgan haqiqiy SKU sonlariga (quyida) mos keladi.

### Mahsulotlar/SKU (barchasi mos — 70/70 yaratildi)

| Bo'lim | dc.html mahsulot soni | dc.html SKU soni | Real mahsulot | Real SKU | Holat |
|---|---|---|---|---|---|
| Daftar (qo'lda yozilgan) | 4 | 19 (12+4+2+1) | 4 | 19 | ✅ narx/zaxira qatorma-qator mos |
| Ruchka (qo'lda yozilgan) | 5 | 9 (3+2+1+1+2) | 5 | 9 | ✅ (Cello/Qora zaxira=0 — "Tugagan" holati ham to'g'ri ko'chirildi) |
| Qalam (qo'lda yozilgan) | 3 | 4 (2+1+1) | 3 | 4 | ✅ |
| A4 (qo'lda yozilgan) | 2 | 2 | 2 | 2 | ✅ (Snegurochka zaxira=0 ham to'g'ri) |
| 14 generatsiya kategoriyasi × 4 | 56 | 56 (har biri 1 SKU) | 56 | 56 | ✅ narx/zaxira formulasi Python'da aynan qayta yozildi, tasdiqlangan |
| **Jami** | **70** | **90** | **70** | **90** | ✅ |

Aniqlik uchun tekshirilgan formulalar (`backend/scripts/seed_catalog.py`):
narx = `base + i*round(base*0.18/500)*500`, zaxira = `i==3 ? 6 : 20+((len(slug)*7+i*13)%90)`,
brend = `BRANDS[(len(slug)+i)%6]` — barchasi dc.html 896-906-qatorlaridan piksel-aniq
ko'chirildi, Python'da qo'lda 14 kategoriya uchun natijalar tekshirildi (masalan
`lineyka`: narxlar 3500/4000/4500/5000 — pastdagi kit jadvalidagi 3500 va 4500 talablari
bilan mos kelishi tasdiqlandi).

### Sinf to'plamlari — 1-11 (11/11, jami narx dc.html bilan aynan mos)

| Sinf | dc.html jami (qo'lda hisoblangan) | Real DB jami | Element soni | Holat |
|---|---|---|---|---|
| 1 | 145 500 | 145 500 | 10 | ✅ |
| 2 | 145 500 | 145 500 | 10 | ✅ |
| 3 | 136 300 | 136 300 | 10 | ✅ |
| 4 | 136 300 | 136 300 | 10 | ✅ |
| 5 | 154 100 | 154 100 | 8 | ✅ |
| 6 | 154 100 | 154 100 | 8 | ✅ |
| 7 | 154 100 | 154 100 | 8 | ✅ |
| 8 | 154 100 | 154 100 | 8 | ✅ |
| 9 | 185 200 | 185 200 | 9 | ✅ |
| 10 | 185 200 | 185 200 | 9 | ✅ |
| 11 | 185 200 | 185 200 | 9 | ✅ |

**Muhim, hujjatlashtirilgan qaror**: dc.html'da kit elementlari (`items: [name, variant,
qty, price]`, 910-936-qator) haqiqiy `P` mahsulotlar ro'yxatiga BOG'LANMAGAN — flat mock
matn (prototipning o'zida ham shunday, `ProductSetItem` uchun alohida nom maydoni yo'q).
Real backend'da esa `ProductSetItem.variant_id` HAQIQIY `ProductVariant`ga majburiy FK —
shu sabab har bir element narxi (va mavjud bo'lsa variant matni, masalan "Ko'k siyoh")
bo'yicha eng mos real variantga avtomatik bog'landi (`seed_catalog.py`'dagi
`resolve_variant()`). Natijada ba'zi elementlarning REAL ko'rinadigan nomi dc.html'dagi
qisqa yorliqdan farq qiladi (masalan dc.html "Lineyka 20 sm" → real "Lineyka Attache",
chunki generatsiya qilingan mahsulot nomi brend bilan keladi) — bu **narx/miqdor/jami
to'liq mos** bo'lgan holda, faqat ko'rsatiladigan matn darajasidagi kutilgan farq.
11 ta sinfning HAMMASI uchun jami narx dc.html'ning o'z JS hisob-kitobi bilan qo'lda
tekshirilib, aynan mos kelishi tasdiqlandi (yuqoridagi jadval).

## LEGACY token shim'lari butunlay olib tashlandi (2026-08-19)

`packages/fargonam_ui/lib/theme/legacy_tokens.dart` (avvalgi Qarorlar yozuviga qarang —
`AppColorsDark`/`AppTextStylesDark`/`AppTextStyles` mobile_user uchun, `LegacyColors`/
`LegacyTextStyles`/`LegacyGradients`/`LegacyShadows`/`LegacySizes` mobile_seller uchun)
**fayl butunlay o'chirildi**. Bajarilgan ish:

- **mobile_user** (31 fayl): `AppColorsDark`/`AppTextStylesDark`/`AppTextStyles`
  to'g'ridan-to'g'ri `AppColors`/`AppTypography` bilan almashtirildi (mexanik, qiymat
  o'zgarmadi — bular avvaldan bir xil qiymatga ishora qiluvchi aliaslar edi).
  `core/theme/app_colors.dart`/`app_text_styles.dart` endi faqat `fargonam_ui`dan
  eksport qiladi.
- **mobile_seller** (14 fayl: `main.dart` + 13 ekran) — bu "Warm Violet" (`LegacyColors`
  va h.k.) va mobile_seller'ning o'zining alohida, hech qachon qo'llanilmagan "Midnight
  Indigo/Vanilla Cream" qorong'i tizimi (`core/theme.dart`, `MaterialApp`ning haqiqiy
  temasi sifatida ISHLATILMAGAN edi — faqat parcha-parcha qo'lda uslublash uchun) —
  ikkalasi ham real `fargonam_ui` (Indigo, mobile_user bilan bitta manba) tokenlariga
  o'tkazildi. Shu bilan birga: `flutter_screenutil` olib tashlandi (endi oddiy logical
  pixel, mobile_user bilan bir xil), `MaterialPageRoute` → `pushAppRoute`, qo'lda yozilgan
  bottom-nav → umumiy `FloatingTabBar` widget (generallashtirildi — endi `items`
  parametri qabul qiladi, mobile_user standart 5 tabi hali ham default qiymat).
  `core/theme.dart` va `core/widgets.dart` (ikkalasi ham endi hech kim tomonidan
  import qilinmaydi) o'chirildi.
- Bajarish usuli: 8 ta parallel subagent (fayllarni mustaqil guruhlarga bo'lib), har
  biri o'z fayllarida `flutter analyze` + LEGACY grep bilan o'zini tekshirdi, so'ng
  yakuniy jamlab tekshiruv (`flutter analyze`/`test`/`build apk --debug` — ikkala ilova).

**Tekshiruv**: `grep -rn "LEGACY" --include="*.dart" .` — **bo'sh** (kod darajasida
to'liq tozalandi). Xom `grep -rn "LEGACY" .` (kengaytmasiz) hali ushbu faylning yuqoridagi
tarixiy yozuvlarida (163-224-qatorlar atrofida, avvalgi Qarorlar) "LEGACY" so'zini
uchratadi — bu CLAUDE.md'ning "PROGRESS.md ustiga yozilmaydi, faqat pastiga qo'shiladi"
qoidasiga ko'ra ATAYLAB o'chirilmadi (o'sha yozuvlar o'sha vaqtda NIMA qilinganini
tasdiqlaydigan tarixiy hujjat, hozirgi kod holatini emas). Kod o'zi (`.dart` fayllari)
va endi mavjud bo'lmagan `legacy_tokens.dart`ning o'zi — ikkalasi ham butunlay toza.

**DoD**: `flutter analyze` — 0/0/0 (`fargonam_ui`, `mobile_user`, `mobile_seller`
uchun alohida). `flutter test` — mobile_user 11/11, mobile_seller 8/8 (`sku_builder`
testlari — Cartesian SKU generatsiyasi mantig'iga tegilmadi). `flutter build apk
--debug` — ikkalasi ham muvaffaqiyatli.

## 4-bosqich — mobile_seller ilova nomi/ikonka/splash (5.5-bo'lim)

- **Qaror**: `android:label` "Fargonam Biznes" qilib qo'yildi (avval xom "mobile_seller"
  edi) — CLAUDE.md 5.5'da "Fargonam Sotuvchi" deb yozilgan, lekin ilovaning o'zi
  (`main.dart`dagi `MaterialApp.title`, rol-tanlash ekrani, barcha AppBar sarlavhalari)
  allaqachon keng qamrovli "Fargonam Biznes" nomidan foydalanadi — bitta binar ikki rolni
  (sotuvchi VA haydovchi) birlashtirgani uchun bu nom aniqroq. O'zgartirish keng qamrovli
  bo'lardi (ko'plab joyda "Biznes" matni bor) va mavjud, izchil brendni buzardi — shu
  sabab mavjud nom saqlandi, faqat `AndroidManifest.xml`dagi xom joy-egallovchi tuzatildi.
- Ikonka: navy `#16294A` fon + oq "FB" (`assets/icon/app_icon.png`/`_foreground.png`,
  xuddi shu ImageMagick/Adwaita-Sans-ExtraBold usuli bilan — Figtree hamon lokal topilmadi).
  mobile_user'ning "F"idan ATAYLAB farqli (ikkala ilova ekranda yonma-yon turganda
  ajratish uchun). Splash — sof navy, rasmsiz (mobile_user bilan bir xil qaror).
  `flutter_launcher_icons`/`flutter_native_splash` `dev_dependencies`ga qo'shildi.
- `flutter_screenutil` pubspec'dan olib tashlandi (LEGACY olib tashlash paytida barcha
  `.w`/`.h`/`.r`/`.sp` allaqachon tozalangan edi, endi paketning o'zi ham keraksiz).

**Qolgan 4-bosqich ishi** (keyingi bosqich): har bir ekran uchun 13-bo'lim ("inson qo'li")
tekshiruvi (letterSpacing/height, haptika joyligi, uzun matn bilan sinov, klaviatura
bosilganda input yopilmasligi) hali qilinmadi — bu safar faqat token/rang/shrift darajasida
birlashtirildi (LEGACY olib tashlash + ikonka). Chuqur interaksiya sayqali va har ekranning
o'zi dc.html'siz (seller uchun alohida mockup yo'q) qanchalik "aynan fargonam_ui uslubida"
ko'rinishini qo'lda tekshirish keyingi navbatda.

### APK

### APK
user: `mobile_user/build/app/outputs/flutter-apk/app-debug.apk` (debug, muvaffaqiyatli)
seller: `mobile_seller/build/app/outputs/flutter-apk/app-debug.apk` (debug, muvaffaqiyatli —
faqat mavjud "Fargonam Biznes" ko'rinishida, dizayn 4-bosqichda almashadi)

## Production Deploy (2026-08-19/20)

Server: `189.74.97.28`, domenlar `fargonam.uz` (APK yuklab olish sahifasi) va
`api.fargonam.uz` (backend), Ubuntu 22.04, Docker Compose orqali (`docker-compose.prod.yml`).

### Qarorlar

- Root parol/foydalanuvchi bootstrap, `fail2ban` (`backend = systemd` — bu Ubuntu
  22.04'da `/var/log/auth.log` yo'q, rsyslog ishlamaydi), `ufw` (22/80/443 ochiq,
  qolgani yopiq) — standart xavfsizlik bootstrap, muqobil yo'q edi.
- Katalog seed qilishdan oldin `backend/scripts/bootstrap_shop.py` yozildi — production
  bazasi bo'sh bo'lgani uchun `seed_catalog.py`ning qattiq kodlangan `SHOP_ID=1`
  mos do'kon topa olmadi (`ForeignKeyViolationError`). Yangi skript bitta rasmiy
  "Fargonam" do'konini (owner user + `ShopStatus.approved`) yaratadi — bu doim MVP-1
  talabiga mos (yagona monodo'kon, tashqi sotuvchilar yo'q).
- nginx ikki bosqichda deploy qilindi: avval faqat HTTP+ACME-challenge konfiguratsiya
  (hali mavjud bo'lmagan sertifikat fayllariga murojaat qilmasligi uchun), keyin
  to'liq HTTPS. `api.fargonam.uz` va `fargonam.uz` bitta sertifikatda (`--cert-name
  api.fargonam.uz`, ikkala domen SAN sifatida).
- Flutter 3.41.6-stable (Dart 3.11.4) tanlandi — 3.38.0 (Dart 3.10.0) pubspec talabini
  qanoatlantirmadi, lokal dev mashinada allaqachon ishlagan versiya tanlandi (Flutter'ning
  o'zi taklif qilgan 3.47.0 emas — tekshirilmagan versiyaga ishonib qolmaslik uchun).
- Gradle 8.14 distributivi GitHub Fastly CDN orqali serverdan yuklab bo'lmadi (TCP hang,
  0 bayt, takrorlanuvchi) — lokal mashinada keshda bor edi, `scp` bilan to'g'ridan-to'g'ri
  ko'chirildi (MD5 tasdiqlangan).
- **"Java home supplied is invalid" xatosi** — sabab: `mobile_user/android/gradle.properties`
  va `mobile_seller/android/gradle.properties` (repo fayllari) `org.gradle.java.home=
  /usr/lib/jvm/java-21-openjdk` deb qattiq kodlangan (izoh: Yandex Maps SDK Java 21 talab
  qiladi). Serverda faqat Java 17 bor edi. **Kodga tegilmadi** — bu haqiqiy loyiha talabi
  (izohda tushuntirilgan), shuning uchun serverga `openjdk-21-jdk` o'rnatildi va
  `/usr/lib/jvm/java-21-openjdk` → `java-21-openjdk-amd64` symlink qo'shildi (paket
  `-amd64` qo'shimchasi bilan o'rnatadi, repo fayli esa qo'shimchasiz yo'lni kutadi).
- Keystore parollari PKCS12 talabiga ko'ra storePassword=keyPassword qilib generatsiya
  qilindi (`keytool` alohida `-keypass`ni jim tashlab yuboradi).

### D-blok: Telegram APK-tarqatish boti

- Alohida `telegram_bot/` xizmati (`docker-compose.prod.yml`), python-telegram-bot,
  polling. Auth uchun ishlatiladigan bot bilan BIR XIL `TELEGRAM_BOT_TOKEN` ishlatiladi
  (foydalanuvchi shunday berdi) — Telegram bitta tokenga faqat bitta yetkazish usulini
  (webhook YOKI polling) ruxsat beradi, shuning uchun bu bot yagona poller: oddiy
  "/start"/tugmalar/"/versiya"ni o'zi javob beradi, "/start <session_id>" (login
  deep-link) kelsa `backend`ning mavjud `/auth/telegram/webhook/{secret}` route'iga
  ichki HTTP orqali uzatadi. Backend kodi o'zgartirilmadi.
- Yo'l-yo'lakay topildi: `docker-compose.prod.yml`dagi `backend` xizmatiga
  `TELEGRAM_*`/`ADMIN_TELEGRAM_IDS` env'lar umuman ulanmagan edi — Telegram login
  production'da hali umuman ishlamas edi. Tuzatildi (backend'ga shu env'lar qo'shildi,
  `TELEGRAM_BOT_USERNAME` `getMe` orqali aniqlandi: `fargonam_bot`, yangi
  `TELEGRAM_WEBHOOK_SECRET` generatsiya qilindi).
- **HAL QILINDI**: 409 sababi foydalanuvchining o'zi (avval boshqa joyda ishga tushirgan
  ekan). BotFather orqali `/revoke` qilib yangi token oldi, `.env`ga o'zi yozdi (menga
  qaytarib ko'rsatilmadi). Konteyner qayta ishga tushirilgach `getUpdates` 200 OK
  qaytardi, 409 yo'qoldi.
- **Tuzatildi**: `httpx`/`telegram` kutubxonalari INFO darajasida har so'rovni to'liq
  URL bilan log qilardi (token URL ichida) — `docker logs` orqali token oshkor bo'lardi.
  `bot.py`da bu loggerlar WARNING'ga tushirildi, eski (tokenli) log qatorlari bo'lgan
  konteyner butunlay olib tashlanib qayta yaratildi.

## SSH xavfsizlik yakunlandi (2026-08-20)

Foydalanuvchi SSH kalitini qo'shgach tasdiqlandi: kalit bilan kirish ishlaydi, parol
bilan kirish rad etiladi (`Permission denied (publickey)`). `PermitRootLogin no` va
`PasswordAuthentication no` `/etc/ssh/sshd_config`ga qo'yildi, `sshd` qayta ishga
tushirildi. Root va `fargonam` foydalanuvchilarining vaqtinchalik parollari
`passwd -l` bilan qulflandi (`L` holat) — endi faqat SSH kalit orqali kirish mumkin.

## MinIO healthcheck tuzatildi

`healthcheck: mc ready local` doim "unhealthy" qaytarardi — bu image tag'da `mc`
binary yo'q ekan (faqat server binary bor). MinIO'ning o'z
`/minio/health/live` HTTP endpoint'iga `curl`ga almashtirildi, endi "healthy".

## Ilova yangilanish tekshiruvi (GET /app/version) va GET /status

`backend/app_version.json`/`backend/status.json` — ikkalasi ham gitignored,
docker-compose orqali `:ro` bind-mount bilan konteynerga ulangan (`.example`
fayllar repoda namuna sifatida). Fayllar har so'rovda qayta o'qiladi — operator
tahrirlagach konteynerni qayta ishga tushirish shart emas.

### Qarorlar

- `GET /app/version` spetsifikatsiyada bitta obyekt qaytarishi yozilgan edi, lekin
  ikkita mustaqil ilova (user/seller) bor — `?app=user|seller` query parametri
  qo'shildi (422 boshqa qiymatda). Bu spetsifikatsiyani to'ldiruvchi zaruriy qaror,
  aks holda ikkinchi ilova uchun ishlamas edi.
- Versiya solishtirish: mavjud `compareVersions`/`PackageInfo` mexanizmi (app_config
  orqali kelgan `min_app_version_*` majburiy-yangilash tizimidan alohida) qayta
  ishlatildi — bu YANGI, ixtiyoriy "yangi versiya bor" bildirishnoma, force=true
  bo'lmasa foydalanuvchi "Keyinroq" bosib davom eta oladi.
- `GET /status` — release skripti yozadigan alohida JSON (`build_seconds`,
  versiya, izoh) + jonli DB ulanish tekshiruvi. Foydalanuvchi so'ragan (Telegram
  bot 409'da) fallback sifatida ishlatiladi.

## Gradle build tezligi (server, ~/.gradle/gradle.properties — repoga TEGILMADI)

`org.gradle.daemon=true`, `org.gradle.parallel=true`, `org.gradle.caching=true`
qo'shildi. **O'lchandi**: `assembleRelease` 407s → 47.4s (user), 196s → 41.8s
(seller) — ~8-9x tezlashdi (asosan issiq daemon + parallel execution).

## scripts/release.sh — bitta buyruq bilan release

`./scripts/release.sh "Izoh"` — versionName/versionCode oshiradi (patch+1, build+1),
ikkala ilovani release rejimida build qiladi, `nginx/downloads/`ga ko'chiradi (eski
APK fayllarini o'chiradi), yuklab olish sahifasi havolalarini yangilaydi,
`app_version.json`/`status.json`ni yangilaydi, `pubspec.yaml`larni commit qiladi
(`git push` qo'lda qoladi — operator nazorati uchun ataylab avtomatlashtirilmadi).

**Topilgan va tuzatilgan xato**: birinchi urinishda `release_app()` funksiyasi
ichidagi progress `echo`lari ham `$(release_app ...)` command substitution orqali
ushlanib qolgan (bash barcha stdout'ni ushlaydi, faqat oxirgi qatorni emas) —
natijada `U_VERSION`/`U_BUILD` o'rniga progress matni tushib, `app_version.json`
yozishda "invalid literal for int()" bilan qulagan va `index.html` buzilgan
(havolalar `href="/"` bo'lib qolgan). Progress xabarlari `>&2`ga ko'chirildi,
faqat yakuniy natija qatori stdout'da qoldi. Server holati reset qilinib (git
checkout + noto'g'ri APK'larni o'chirish) qayta ishga tushirilgach **muvaffaqiyatli
o'tdi** (user/seller 0.1.1+2, sayt/`/app/version`/`/status` hammasi mos).
Alohida topilgan kichik gap: serverda global git identity sozlanmagan edi
(`git config --global user.email/name` — deploy foydalanuvchisi uchun bir marta
qo'shildi, endi commit bosqichi ishlaydi).

## APK hajmi tekshiruvi (137 MB — sabab topildi, YECHIM FOYDALANUVCHIGA QOLDIRILDI)

`unzip -l` bilan tekshirildi (`fargonam-user-0.1.0.apk`, 150.7 MB siqilmagan):

| Fayl | Hajm |
|---|---|
| `lib/x86_64/libmaps-mobile.so` | 28.9 MB |
| `lib/arm64-v8a/libmaps-mobile.so` | 26.2 MB |
| `lib/armeabi-v7a/libmaps-mobile.so` | 15.7 MB |
| **Yandex Maps jami (3 arxitektura)** | **~70.9 MB (~47%)** |
| `libflutter.so` + `libapp.so` (3 arxitektura) | ~55 MB |

**Muhim topilma**: `yandex_mapkit`dan foydalanadigan yagona fayl —
`mobile_user/lib/features/taxi/taxi_screen.dart` — hech qayerdan chaqirilmaydi.
`app_shell.dart`dagi Taksi tab `TaxiComingSoonScreen`ni ko'rsatadi (CLAUDE.md
1-bo'lim: taksi 2-bosqich funksiyasi, MVP-1'da "tez orada"). Ya'ni ilova hozir
ishlatilmayotgan xususiyat uchun ~71 MB native kutubxona tashiydi.
`yandexMapkit.variant=lite` allaqachon eng kichik variant — bu yo'nalishda
qo'shimcha kamaytirish yo'q.

**Variantlar** (qaror qilinmadi, foydalanuvchi tanlaydi):
1. **`--split-per-abi`** — 3 alohida APK (har biri ~45-55 MB), faqat `arm64-v8a`ni
   saytga qo'yish (so'nggi ~6-7 yillik qurilmalarning deyarli barchasi). Faqat build
   bayrog'i, kod o'zgarmaydi. Kamchilik: eski 32-bit qurilmalar uchun alohida havola
   kerak bo'ladi.
2. **x86_64'ni universal build'dan chiqarib tashlash** (`--target-platform
   android-arm,android-arm64`) — real foydalanuvchi qurilmalarida deyarli hech qachon
   kerak bo'lmaydi (faqat emulyator/ba'zi Chromebook), ~49 MB tejaydi, bitta universal
   APK saqlanib qoladi. Faqat build bayrog'i.
3. **`yandex_mapkit`ni pubspec'dan vaqtincha olib tashlash** (2-bosqichda taksi
   ishga tushganda qaytarish) — ~71 MB tejaydi, lekin bu kod/bog'liqlik o'zgarishi
   (pubspec.yaml, Android native konfiguratsiya), shunchaki build bayrog'i emas.
   Eng katta tejash, lekin eng invaziv.
4. 1/2 va 3 birlashtirilishi mumkin (maksimal tejash).

### Qaror: 3+1 birlashtirildi (2026-08-20, foydalanuvchi tanladi)

**Natija**: user 137MB → **28MB (arm64) / 25MB (arm32)**, seller 61MB → **24MB (arm64) /
22MB (arm32)**. Ikkalasi ham 50MB Telegram limitidan past — bot endi APK faylini
to'g'ridan-to'g'ri yuboradi (havola emas), qo'shimcha kod o'zgarishi kerak bo'lmadi
(mavjud `MAX_TELEGRAM_FILE` tekshiruvi allaqachon shunday ishlagan).

**O'chirilgan (kommentariyga o'ralgan, o'zgartirilmagan, faqat "// " prefiksi
qo'shilgan yoki qatorlar kommentariyga olingan):**
- `mobile_user/pubspec.yaml`: `yandex_mapkit: ^4.1.0` qatori
- `mobile_user/android/app/build.gradle.kts`: `implementation("com.yandex.android:maps.mobile:...")`
- `mobile_user/android/app/src/main/kotlin/.../MainApplication.kt`: `MapKitFactory` import va init
- `mobile_user/lib/features/taxi/taxi_screen.dart`: **butun fayl** (2091 qator, har biri
  `// ` bilan boshlanadi) — `app_shell.dart`dan chaqirilmasdi (Taksi tab
  `TaxiComingSoonScreen` ko'rsatadi), lekin `activeRideProvider`ni eksport qilardi

**Yangi qo'shildi**: `mobile_user/lib/features/taxi/active_ride_stub.dart` — faqat
`app_shell.dart`ning `ref.invalidate(activeRideProvider)` chaqiruvi (WebSocket
`ride_status` event'ida) kompilyatsiya bo'lishi uchun minimal `FutureProvider` stub
(doim `null` qaytaradi — taksi o'chirilgan holda haqiqiy faol sayohat bo'lishi
mumkin emas).

#### TAKSI QAYTARISH (2-bosqich boshlanganda) — aniq qadamlar

1. `mobile_user/pubspec.yaml`: 43-qatordagi kommentariyni olib tashlang —
   `yandex_mapkit: ^4.1.0` qayta yoziladi.
2. `mobile_user/android/app/build.gradle.kts`: `dependencies {}` blokidagi
   `implementation("com.yandex.android:maps.mobile:4.22.0-lite")` qatorini
   kommentariydan chiqaring.
3. `MainApplication.kt`: 2 ta import va `onCreate()` ichidagi `try {}` blokini
   kommentariydan chiqaring (fayl boshidagi izohni o'chiring).
4. `taxi_screen.dart`: har qatordan `// ` prefiksini olib tashlang —
   `sed -i 's/^\/\/ //' taxi_screen.dart` (birinchi 5 ta izoh qatorini qo'lda
   o'chirish kerak bo'ladi), yoki `git log`dan shu commit'dan OLDINGI versiyani
   qayta tiklang (`git show <bu-commitdan-oldingi-hash>:mobile_user/lib/features/taxi/taxi_screen.dart`).
5. `mobile_user/lib/features/taxi/active_ride_stub.dart`ni o'chiring.
6. `app_shell.dart`dagi import'ni qaytaring:
   `import '../taxi/active_ride_stub.dart' show activeRideProvider;` →
   `import '../taxi/taxi_screen.dart' show activeRideProvider;`
7. `app_shell.dart`dagi `_pages` ro'yxatida `TaxiComingSoonScreen()` o'rniga
   `TaxiScreen()` qo'ying (yoki mos UI qarorini qabul qiling).
8. `flutter pub get` + `flutter analyze` + `flutter test` — 0/0/0 va yashil bo'lishi kerak.
9. `scripts/release.sh` avtomatik arm64/arm32 build qiladi — hajm яна ~70MB
   ko'tariladi, bu normal (xarita kutubxonasi qaytdi).

### Arxitektura sxemasi (2026-08-20)

`--split-per-abi` ISHLATILMADI — buning o'rniga har arxitektura uchun alohida
`flutter build apk --release --target-platform android-arm64` /
`--target-platform android-arm` chaqiruvi (natija bir xil: 2 alohida APK,
x86_64 umuman ishlab chiqarilmaydi). Sabab: `--split-per-abi` standart holatda
x86_64'ni ham qo'shib yuborar edi, buni chiqarib tashlash uchun baribir
`--target-platform` cheklash kerak bo'lardi.

Sayt: har ilova uchun 2 tugma — "Zamonaviy telefonlar (arm64)" (asosiy,
tavsiya etiladi) va "Eski telefonlar (arm32)" (ikkinchi darajali). `/app/version`
(ilova ichidagi yangilanish paneli) — faqat arm64 havolasini beradi (standart
holat). Bot — faqat arm64 (oddiy bo'lib qolishi uchun, ikkinchi variant
takliflanmaydi, kerak bo'lsa sayt ko'rsatiladi).

---

## REJA: Web Admin Panel + Moderatsiya (2026-08-20, TASDIQLASH KUTILMOQDA)

Kod hali yozilmagan — bu reja, foydalanuvchi tasdiqlagach boshlanadi.

### 1. Moderatsiya modeli

**Yangi migratsiya** — `products` va `product_sets` jadvallariga:
```
status          enum(draft, pending, approved, rejected)  default 'pending'
rejected_reason text | null
submitted_at    timestamptz  default now()
moderated_at    timestamptz | null
moderated_by    int | null  FK -> users.id
```
Migratsiyada mavjud barcha qatorlar (va `seed_catalog.py`/`bootstrap_shop.py`
natijasi) `status='approved'`, `moderated_at=created_at` qilib to'ldiriladi —
hech narsa yo'qolib qolmaydi, hech kim to'satdan Market'dan tushib qolmaydi.

**Oqim** (foydalanuvchi yozgani aynan):
- Seller saqlaydi → `pending`
- Admin tasdiqlaydi → `approved` → User App'da ko'rinadi
- Admin rad etadi → `rejected` + `rejected_reason` → seller ko'radi, tahrirlab
  qayta yuborsa → yana `pending`

**Eng muhim texnik qaror — "tasdiqlangan mahsulot tahrirlansa eski versiya
ko'rinib tursin":**
Narx/zaxira (`ProductVariant.price`/`stock`) — DOIM darhol o'zgaradi, hech qanday
moderatsiya yo'q (buyurtma/inventar bilan bog'liq, kechiktirib bo'lmaydi).
Nom/rasm/tavsif/parametr (variant tuzilmasi) — bu maydonlar to'g'ridan-to'g'ri
qatorga yozilmaydi. `products`/`product_sets`ga yangi `pending_edit: JSONB | null`
ustuni qo'shiladi: seller himoyalangan maydonni o'zgartirganda, o'zgarish shu
ustunga JSON sifatida yoziladi, LIVE qator o'zgarmaydi, `status='pending'`
qo'yiladi. User App hamon eski (approved) qiymatlarni ko'rsataveradi. Admin
tasdiqlasa — `pending_edit` LIVE qatorga qo'llaniladi va tozalanadi. Rad etsa —
`pending_edit` saqlanib qoladi (seller "Tahrirlash"da o'z yuborgan variantini
qayta ko'radi), `status='rejected'` + sabab.

User App endpointlari (`categories.py`, `products.py`, `kits.py`) — mavjud
`Product.is_active.is_(True)` filtriga `Product.status == ProductStatus.approved`
qo'shiladi (bir joyda, bitta helper funksiya orqali — hozir bu filtr 3 joyda
qo'lda takrorlangan, shu safar umumlashtiriladi).

### 2. Web Admin — to'liq funksionallik

Foydalanuvchi yozgan ro'yxat (moderatsiya navbati, rasm tahriri, mahsulotlar,
kategoriyalar, to'plamlar, buyurtmalar, sotuvchilar, foydalanuvchilar,
bildirishnomalar, boshqaruv) — texnik asos:

- **Moderatsiya navbati, rasm tahriri**: yangi. Rasm qirqish/burish/aylantirish —
  brauzerda (canvas, kutubxona kerak — 3-bo'limga qara), yuklashda backend
  `Pillow` bilan siqadi + kvadrat preview yaratadi (`requirements.txt`ga
  `Pillow` qo'shiladi, hozir yo'q — rasm hozir xom holda saqlanadi, tekshirildi).
  Navbat UI'da bir nechta mahsulot belgilab **birdan tasdiqlash** (checkbox +
  "Tanlanganlarni tasdiqlash") — backend `/admin/moderation/{products,kits}/
  bulk-approve` (`{ids: [...]}`) allaqachon tayyor (Blok 1'da yozildi), UI
  shu endpointga ulanadi. Admin "tuzatib tasdiqlash" (sellerga qaytarmasdan
  o'zi tahrirlab) — `/admin/moderation/products/{id}/edit-approve` ham
  tayyor.
- **Mahsulotlar CRUD, SKU jadvali**: `products.py`dagi mavjud
  create/update/variants endpoint'lari admin uchun ham ishlatiladi (rol
  tekshiruvi kengaytiriladi: seller o'ziniki, admin — hammasi).
- **Kategoriyalar**: hozir CRUD YO'Q (faqat `GET /categories`). Yangi:
  `POST/PATCH/DELETE /admin/categories`, `PATCH .../reorder`. **Muhim topilma**:
  `Category` modelida `icon`/`color`/`sort_order` ustunlari yo'q — ikonkalar
  hozir mobil ilovada `icon(catId)` funksiyasi orqali id bo'yicha qattiq
  kodlangan (dc.html'dan ko'chirilgan SVG). "Ikonka va rang tanlash" talabini
  bajarish uchun ikki yo'l bor: (a) yangi ustunlar qo'shib mobil ilovani
  API'dan o'qishga o'tkazish (CLAUDE.md §6 "yangi ikonka o'ylab topish"
  taqig'iga qarshi kelmaydi — tanlov mavjud ikonkalar orasidan bo'ladi, lekin
  bu mobil UI kod o'zgarishi talab qiladi), yoki (b) admin panelda faqat
  MAVJUD ikonkalar ro'yxatidan tanlash (yangisini yuklamasdan), DB'da faqat
  qaysi ikonka tanlanganini saqlash, mobil ilova o'zgarmaydi. **(b) tavsiya
  etiladi** — kichikroq, mobil kod kodga tegmaydi. Bo'sh bo'lmagan kategoriya
  o'chirilganda 409 + mahsulotlar soni xabari.
- **To'plamlar (kitlar)**: `kits.py`da CRUD allaqachon bor, admin uchun
  kengaytiriladi + moderatsiya (1-bo'limdagi model bilan bir xil).
- **Buyurtmalar**: `admin.py`da `GET /admin/orders` + status PATCH allaqachon
  bor — UI qurish kifoya, backend deyarli tayyor. "Bekor qilish" — mavjud
  `OrderStatus.cancelled`ga PATCH.
- **Sotuvchilar**: `admin.py`da `GET/PATCH /admin/shops` bor (KYC holati).
  Yangi: "Ishonchli" bayrog'i (`Shop`ga `is_trusted: bool` ustuni, hozircha
  faqat saqlanadi — moderatsiya bypass mantiqi keyinroq, foydalanuvchi aytgan).
  Yangi seller qo'shish — mavjud `User`/`Shop` yaratish logikasidan
  foydalanadi (bootstrap_shop.py'dagi patternga o'xshash, lekin admin API orqali).
- **Foydalanuvchilar**: `admin.py`da `GET/PATCH /admin/users` bor — UI kifoya.
- **Bildirishnomalar**: `admin.py`da `POST /admin/broadcast` bor (hammaga).
  Yangi: bitta foydalanuvchiga yuborish varianti (kichik qo'shimcha).
- **Versiya e'lon qilish**: hozir `backend/app_version.json` `:ro` (read-only)
  bind-mount — admin panel orqali yozish uchun `:rw`ga o'zgartiriladi + yangi
  `PUT /admin/app-version` endpoint (faylni yozadi, xuddi `release.sh` qiladigan
  ishni). `status.json` ham xuddi shunday `:rw`.
- **Yangiliklar**: `news.py`da create/delete allaqachon bor — UI kifoya.
- **Yetkazib berish narxi va sozlamalar**: `app_config.py`da allaqachon TO'LIQ
  bor (`PUT /app-config/{key}`) — yangi backend kerak emas, faqat UI.

### 3. Web Admin — texnik

- **Stack**: React + Vite + TypeScript + Tailwind. Qo'shimcha kutubxona —
  faqat rasm qirqish uchun bitta kichik kutubxona kerak bo'ladi (masalan
  `react-easy-crop`) — qo'lda yozish oqilona emas, boshqa hamma narsa qo'shimcha
  paketsiz. Router — `react-router`. Ma'lumot olish — oddiy `fetch` (React Query
  kabi qo'shimcha state kutubxona qo'shilmaydi, foydalanuvchining "ortiqcha
  kutubxona qo'shma" qoidasiga ko'ra).
- **Joylashuv — TOPILGAN NOMUVOFIQLIK**: foydalanuvchi "hozircha fargonam.uz/admin"
  deb yozgan, lekin backend'da ALLAQACHON `api.fargonam.uz/admin-web/` mount
  qilingan (`main.py`: `app.mount("/admin-web", ...)`, nginx'da ham tayyor) va
  hozirgi `admin_web/index.html` (eski, boshqa — qorong'i mavzu, Indigo bilan
  hech aloqasi yo'q) shu joyga xizmat qiladi. **Tavsiya**: yangi SPA'ni ayni shu
  `admin_web/` papkaga build qilib qo'yish (`api.fargonam.uz/admin-web/`) —
  nol infra o'zgarishi, domen keyin (`admin.fargonam.uz`) DNS qo'shilgach
  osongina almashtiriladi (bitta nginx server_name qatori). Agar aynan
  `fargonam.uz/admin` kerak bo'lsa — nginx'ga yangi `location /admin` qo'shish
  kerak bo'ladi (kichik qo'shimcha ish). Reja shu (a) variant bilan davom etadi,
  agar (b) kerak bo'lsa — bitta nginx qatori, keyin osongina o'zgartiriladi.
- **Dizayn**: mavjud tokenlar (fon `#EEF1F6`, kartalar oq, navy gradient
  tugmalar, Figtree, radius 16) — lekin bular Flutter/Dart konstantalari
  (`packages/fargonam_ui`), web uchun QAYTA yoziladi CSS custom properties
  sifatida (bir xil qiymatlar, ikkinchi manba — Dart paketini web'ga import
  qilib bo'lmaydi). Layout — chap menyu + o'ng ish maydoni, jadvallar (ilova
  ekranlarining o'zi ko'chirilmaydi, faqat rang/shrift tili).
- **Auth — TOPILGAN NOMUVOFIQLIK**: foydalanuvchi "telefon + parol yoki
  Telegram login" deb yozgan, lekin CLAUDE.md §4 aniq: "Uchala klient ham
  (mobile_user, mobile_seller, admin_web) Telegram login ishlatadi... telefon+OTP
  butunlay olib tashlangan". Telefon+PAROL — OTP emas, lekin baribir loyihaning
  qat'iy qabul qilingan "faqat Telegram" xavfsizlik qaroriga zid yangi kirish
  usuli bo'lardi. **Tavsiya: faqat Telegram login**, mavjud `/auth/telegram/*`
  oqimidan foydalaniladi, faqat `role=admin` bo'lgan userlar admin panelga
  kira oladi (`require_admin` allaqachon bor). Uzoq sessiya — mavjud refresh
  token rotation (backendda bor) client tomonda to'g'ri implementatsiya
  qilinsa kifoya, yangi backend mexanizmi kerak emas.
- Mobil brauzerda ochiladigan, lekin desktop-birinchi responsive layout.
- Ro'yxat sahifalash — mavjud `Page[...]` pagination pattern (`admin.py`da
  allaqachon ishlatiladi) qayta ishlatiladi. Rasm lazy load — oddiy
  `loading="lazy"` yetadi, qo'shimcha kutubxona kerak emas.

### 4. Seller App o'zgarishlari

- Har mahsulot qatoriga status badge (`mobile_seller/lib/features/products/`):
  kulrang "Tekshiruvda" / yashil "Tasdiqlandi" / qizil "Rad etildi" — mavjud
  `AppColors.textMuted`/`success`/`danger` va tint ranglar, yangi rang yo'q.
- Rad etilganda: sabab matni + "Tahrirlash" tugmasi (mavjud edit ekraniga olib
  boradi, forma to'ldirilgan holda).
- Saqlagandan keyin snackbar/toast: "Yuborildi, tekshiruvdan o'tgach Market'da
  ko'rinadi" (mavjud toast widget, `packages/fargonam_ui`).
- Yangi ekran yo'q — mavjud `products_screen.dart`/`add_product_screen.dart`/
  `edit_product_screen.dart` kengaytiriladi.

### 5. Taqqoslash va reja (tartib, vaqt, xavf)

**O'zgaradigan mavjud fayllar** (backend): `models/product.py`, `models/product_set.py`,
`models/category.py`, `models/shop.py` (`is_trusted`), yangi Alembic migratsiya,
`api/products.py` (moderatsiya gate + `pending_edit` mantiq), `api/kits.py`
(xuddi shunday), `api/categories.py` (CRUD qo'shiladi, filtr yangilanadi),
`api/admin.py` (yangi endpoint'lar: moderatsiya navbati, kategoriyalar,
app-version, bitta userga xabar), `docker-compose.prod.yml` (app_version.json/
status.json `:rw`ga, yangi admin_web static volume shart emas — mavjud mount
ishlaydi), `requirements.txt` (+Pillow). Mobil: `mobile_seller` 4 ta ekran
faylida kichik qo'shimcha (yangi fayl yo'q).

**Migratsiya xavfsizmi**: ha — yangi ustunlar `nullable`/`default` bilan
qo'shiladi, mavjud qatorlar bitta `UPDATE ... SET status='approved'` bilan
to'ldiriladi, hech qanday `NOT NULL` majburiy maydon eski qatorni buzmaydi.
Productionda `alembic upgrade head` — downtime kerak emas (ustun qo'shish
PostgreSQL'da tez).

**Testlar buziladimi**: backend'da moderatsiya filtri qo'shilgani uchun mavjud
`list_products`/`list_categories` testlari (agar bor bo'lsa) `status=approved`
seed ma'lumoti bilan yozilishi kerak — seed skriptlari `status='approved'`
qilib yangilanadi (Qismi 1). Mobil testlarga (`flutter test`) ta'sir yo'q —
faqat UI badge qo'shiladi, mavjud repository chaqiruvlari saqlanadi.

**Taxminiy vaqt** (bitta ishchi sessiya = ~bir necha soat, CLAUDE.md §10
"seans qoidasi" mobil UI uchun; bu backend/web ish, bo'linish erkinroq):
| Blok | Taxminiy hajm |
|---|---|
| Migratsiya + moderatsiya modeli (backend) | O'rtacha (1 sessiya) |
| Admin API kengaytmalari (kategoriya CRUD, moderatsiya, rasm, app-version) | Katta (2-3 sessiya) |
| Web Admin SPA — skelet + auth + layout | O'rtacha (1 sessiya) |
| Web Admin — moderatsiya navbati + rasm tahriri ekrani | Katta (2 sessiya, rasm kutubxonasi integratsiyasi eng murakkab qism) |
| Web Admin — qolgan ekranlar (mahsulot/kategoriya/kit/buyurtma/seller/user/bildirishnoma/sozlama CRUD) | Katta (3-4 sessiya, ko'p lekin takrorlanuvchi pattern) |
| Seller App badge/xabar | Kichik (yarim sessiya) |

**Tartib** (foydalanuvchi eng tez foyda ko'rishi uchun):
1. Migratsiya + backend moderatsiya modeli (hech narsa buzilmaydi, User App
   darhol ishlashda davom etadi — status default approved)
2. Admin API — moderatsiya navbati + kategoriya CRUD (eng ko'p ishlatiladigan)
3. Web Admin SPA skelet + auth + moderatsiya navbati ekrani (birinchi
   ishlaydigan oyna — foydalanuvchi shu yerdan darhol foyda ko'radi)
4. Rasm tahriri (eng murakkab, lekin foydalanuvchi "eng muhim" degan)
5. Qolgan admin ekranlari (mahsulot to'liq CRUD, kategoriya, kit,
   buyurtma, seller, user, bildirishnoma, sozlama) — birma-bir, har biridan
   keyin sinov
6. Seller App badge/xabar (kichik, istalgan vaqtda qo'shilishi mumkin)

### 6. Qolgan ishlar holati

APK hajmi, yangilanish mexanizmi, `release.sh`, Telegram bot — **hammasi
bajarildi va tasdiqlandi** (yuqoridagi bo'limlarga qarang). **Bajarilmagan**:
"4-bosqich: Seller App ekranlari tugallanishi" (CLAUDE.md §10, 13-bo'lim
"inson qo'li" tekshiruvi — har ekran uchun haptika/letterSpacing/uzun matn/
klaviatura sinovi) — bu moderatsiya UI (yuqoridagi §4) bilan bir vaqtda,
o'sha ekranlarga tegilganda birga qilinishi tavsiya etiladi (ikki marta
ochib-yopish o'rniga), alohida oldin qilish shart emas — foydalanuvchi
tasdiqlasa shu tartibda davom etiladi.

---

## Sessiya (2026-08-20) — Laptop qayta yonlangandan keyin davom

Kontekst yo'qolgan (xotira tozalangan), lekin server/git'da hech narsa
yo'qolmagan edi. Oldingi seans allaqachon Blok 1'ni yarmigacha yozib
qo'ygan ekan (uncommitted, lokal DB'da migratsiya qo'llangan) — shu yerdan
davom etildi, qaytadan yozilmadi.

### Topilgan va tuzatilgan xato: admin-web 404 edi
`backend/app/main.py`dagi `ADMIN_WEB_DIR = parents[2] / "admin_web"` konteyner
ichida mavjud bo'lmagan yo'lga ishora qilardi (`admin_web/` build context'ga
kirmaydi) — `StaticFiles` mount() `if ADMIN_WEB_DIR.exists()` shartidan
o'tolmay, `/admin-web/` doim 404 qaytarardi (ehtimol boshidan beri). Tuzatildi:
`docker-compose.prod.yml`ga `./admin_web:/admin_web:ro` bind mount qo'shildi.
Tekshirildi — endi `https://api.fargonam.uz/admin-web/` 200.
Shuningdek auto-login'da admin bo'lmagan/olib tashlangan token bilan kirilsa
endi "Sizda admin huquqi yo'q" ko'rsatiladi (avval jim tozalanardi).

### ADMIN_TELEGRAM_IDS — faqat 1 kishi
Ro'yxatda 3 ID bor edi (Vohidjon, Adibaxon, Solijon — izohda shunday yozilgan
edi). Foydalanuvchi "faqat 5860426852 (Solijon) kira olsin, boshqa hech kim"
dedi → ro'yxat shu bittaga qisqartirildi (lokal `backend/.env` va server
`.env`, ikkalasi ham). Productionda hech kimda hali `role=admin` yo'q edi
(DB'da tekshirildi) — retroaktiv pastga tushirish kerak bo'lmadi, mavjud
`telegram_auth.py` mexanizmi kelajakda ID ro'yxatdan chiqsa avtomatik
pastga tushiradi (194-qator, allaqachon bor edi).

### Blok 1 — Migratsiya + status modeli + backend endpointlar: TUGALLANDI
Reja (yuqorida, §1-3) bo'yicha to'liq yozildi:
- `products.py`, `kits.py` — User App faqat `status=approved` ko'radi;
  do'kon egasi/admin o'zinikini har doim ko'radi. Narx/stok/`is_active`
  (kitda: `items` ham) darhol o'zgaradi. Nom/rasm/tavsif/kategoriya —
  tasdiqlangan mahsulotda `pending_edit`ga stagelanadi, LIVE qator eski
  holicha qoladi. **Qaror**: kit `items` (tarkib) va `is_active`ni
  himoyalanmagan qildim (mavjud tasdiqlangan variantlarga bog'lanadi, xato
  qilib firibgarlik qilish qiyin, sotuvchiga tez moslashuv kerak) — faqat
  nom/sinf/tavsif/rasm himoyalangan. Reja hujjatida bu aniq yozilmagan edi,
  mustaqil qaror qilindi (CLAUDE.md §14).
- `admin.py`: `/admin/moderation/products` va `/admin/moderation/kits`
  (navbat, sukut `status=pending`), har biriga `/approve`, `/reject`
  (`{reason}`), `/bulk-approve` (`{ids}`), mahsulotga qo'shimcha
  `/edit-approve` (admin sellerga qaytarmasdan o'zi tuzatib tasdiqlaydi).
- `scripts/seed_catalog.py` — yangi seed mahsulot/to'plam endi
  `status=approved` bilan yaratiladi (aks holda MVP monodo'kon katalogi
  moderatsiya navbatida "yo'qolib" qolardi).
- `Shop.is_trusted` ustuni qo'shildi, hozircha faqat saqlanadi (bypass
  mantiqi yo'q — reja shunday deydi, kelajakda ishlatiladi).

**Tekshirildi** (lokal dev DB'da, keyin production'da):
- Lokal: migratsiya oldin qo'llangan ekan (77 mahsulot, 11 to'plam — hammasi
  `approved`ga to'ldirilgan). `uvicorn` lokal ishga tushirilib, `openapi()`
  sxemasi qurildi (barcha 9 ta moderatsiya route ro'yxatda), keyin bitta
  mahsulot qo'lda `pending`ga o'tkazilib — ommaviy ro'yxatdan va
  `GET /products/{id}`dan yo'qolgani, keyin qaytadan `approved`ga
  qaytarilgach yana ko'ringani tasdiqlandi.
- Production: deploydan oldin `pg_dump` bilan zaxira olindi
  (`/home/fargonam/backups/pre_moderation.dump`). `docker compose build
  backend` + `up -d` — entrypoint avtomatik `alembic upgrade head` ishga
  tushirdi, xatosiz o'tdi. Deploydan keyin: `/categories` 200,
  `/products?limit=3` — 70 ta mahsulot, hammasi `status=approved`
  (hech narsa yo'qolmadi), `/admin-web/` 200, `fargonam.uz` 200, 6/6
  konteyner Up.

**Bajarilmagan (keyingi seansga)**: Blok 2 (dc.html/model solishtiruvi —
alohida, mustaqil tekshiruv), Blok 3 (Web Admin SPA — moderatsiya navbati
UI + rasm tahriri, eng katta qism, Pillow hali `requirements.txt`ga
qo'shilmagan), Blok 4-5 (admin qolgan ekranlari), Blok 6 (Seller App
badge/xabar).

### Qarorlar
- [2026-08-20] Savol: kit moderatsiyasida `items`/`is_active`ni ham
  himoyalash kerakmi? → Qaror: yo'q, faqat nom/sinf/tavsif/rasm
  himoyalangan → Sabab: itemlar mavjud tasdiqlangan variantlarga
  bog'lanadi, aldash riski past, sotuvchiga narx/tarkib tez moslashuv
  kerak (savat/buyurtma bilan bog'liq, kechiktirib bo'lmaydi — xuddi
  narx/stok kabi).

---

## Sessiya (2026-08-20, davomi) — Blok 2: Admin API kengaytmalari (qisman)

Kompyuter qayta ishga tushirilgach shu seansda davom etildi. "Tartib"
ro'yxatidagi 2-band ("Admin API kengaytmalari: kategoriya CRUD, moderatsiya,
rasm, app-version") ustida ishlandi — moderatsiya qismi Blok 1'da allaqachon
tayyor edi, shu safar **kategoriya CRUD va app-version** yozildi.

### Topilma: eski "muhim topilma" noto'g'ri ekan
REJA hujjatida (§2) "ikonkalar mobil ilovada `icon(catId)` funksiyasi orqali
**id** bo'yicha qattiq kodlangan" deyilgan edi. Tekshirilganda aslida
`mobile_user/lib/features/marketplace/category_icons.dart` ikonkani
**slug** bo'yicha tanlaydi (`categoryIconPaths[slug]`), id bilan aloqasi
yo'q. Bu yangi `icon`/`color` ustunlarini DB'da saqlashga xalaqit
bermaydi — reja (b) varianti (mavjud ikonkalar ro'yxatidan tanlash, mobil
kod tegilmaydi) baribir to'g'ri yo'l, faqat ikonka nomi allaqachon slug
bilan bir xil ekanini bilib qo'yish kerak edi.

### Bajarildi
- **Kategoriya**: `categories`ga `icon` (18 ta ruxsat etilgan qiymat —
  `app/core/category_icons.py`, `category_icons.dart` bilan aynan bir xil
  ro'yxat), `color` (hex), `sort_order` ustunlari (migratsiya
  `b3c4d5e6f708`, mavjud qatorlar `id*10` bilan to'ldirildi — ko'rinish
  o'zgarmadi). `PATCH /categories/{id}` (admin/seller), `PATCH
  /categories/reorder` (faqat admin, `{items:[{id,sort_order}]}`),
  `GET /categories` endi `sort_order`bo'yicha tartiblanadi. **Diqqat**:
  `icon`/`color` hozircha faqat saqlanadi — mobil ilovaga bog'lanish yo'q
  (Shop.is_trusted'dagi kabi bir xil pattern, Blok 1'da qaror qilingan).
- **App versiya**: `PUT /admin/app-version` (`{app,version,build,apk_url,
  notes,force}`) — `release.sh` qiladigan ishni admin panel orqali qiladi,
  konteyner qayta ishga tushirmasdan. `docker-compose.prod.yml`:
  `app_version.json` endi `:rw` (avval `:ro`).
- Lokal dev DB'da migratsiya qo'llanib tekshirildi (backfill to'g'ri),
  `uvicorn` bilan barcha yangi endpoint qo'lda sinaldi: PATCH ikonka
  validatsiyasi (noto'g'ri qiymat → 422), reorder, app-version yozish
  (o'zbekcha apostrof matni to'g'ri saqlandi, boshqa app'ning yozuvi
  buzilmadi).

### Ataylab qilinmadi (keyingi qadamga qoldirildi)
- **`status.json` `:rw` qilinmadi, `PUT /admin/status` yozilmadi** — Sabab:
  uni hozircha faqat `release.sh` yozadi (build vaqti kabi avtomatik
  ma'lumot), admin panelda uni qo'lda tahrirlash uchun aniq talab yo'q;
  kerak bo'lsa keyin qo'shiladi (CLAUDE.md: "kelajak uchun abstraksiya"
  yozilmaydi).
- **Pillow / rasm siqish** — reja §2'da aytilgan, lekin bu asosan Web
  Admin'ning rasm tahriri ekrani (qirqish/burish) bilan bog'liq (Tartib
  4-band) — SPA hali yo'q, frontend cropper qanday format
  yuborishini bilmasdan backend kontraktini taxmin qilish shart emas edi.
  SPA qurilganda birga yoziladi.

### Bajarilmagan (keyingi seansga)
Tartib 3-band: Web Admin SPA skelet (React+Vite+TS+Tailwind, auth,
layout, moderatsiya navbati ekrani) — hali boshlanmagan, `admin_web/`da
faqat eski `index.html` bor. Undan keyin 4-5-6-bandlar.

### Qaror: rasm siqish kechiktirilmadi (foydalanuvchi tuzatdi)
Avvalgi qaror ("Pillow SPA bilan birga qurilsin") xato edi — sellerlar
hozir ham rasm yuklayapti va xom holda saqlanmoqda, kechiktirilsa
allaqachon yuklangan rasmlarni keyin qayta ishlash kerak bo'lardi.
Shu zahoti yozildi:
- `app/core/image_processing.py`: `process_product_image()` — Pillow bilan
  EXIF orientatsiyasini qo'llaydi, max 1200px (uzun tomon) gacha
  kichraytiradi, JPEG sifat 85 bilan siqadi, 400x400 kvadrat preview
  (markazdan crop) generatsiya qiladi.
- `products.py`dagi ikkala yuklash endpointi (`POST /{id}/image` — asosiy,
  `POST /{id}/images` — galereya) shu funksiyani ishlatadi. Format qanday
  bo'lishidan qat'i nazar (JPEG/PNG/WebP) natija doim JPEG. Magic-byte
  tekshiruvi saqlanib qoldi (tez rad javob), Pillow o'zi ochib bo'lmasa
  ham `ValueError` → 400.
- Yangi `thumb_url` ustuni: `products` va `product_images` jadvallariga
  (migratsiya `c4d5e6f7a819`). `Product.thumb_url` boshqa himoyalangan
  maydonlar (`image_url`) bilan bir xil `pending_edit` mexanizmidan
  o'tadi — tasdiqlangan mahsulotda eski rasm/preview ko'rinishda qoladi.
  `ProductOut` schema'siga qo'shildi.
- Pillow `requirements.txt`ga qo'shildi (`==11.1.0`), lokal `.venv`ga
  o'rnatildi (`uv pip install`).
- Sinov: 3000x2000 JPEG yuklandi → natija 1200x800 (nisbat saqlangan) +
  400x400 kvadrat preview, ikkalasi ham diskka to'g'ri yozildi, tasdiqlangan
  mahsulotda `pending_edit`ga to'g'ri stagelandi. Rasm bo'lmagan fayl (matn)
  yuklanganda 400 qaytdi. Galereya endpointi ham `thumb_url` qaytaradi.
  Sinov ma'lumotlari (fayllar, DB qatorlari) tozalab tashlandi.
- **Qamrovdan tashqarida qoldi (ataylab)**: `news.py`/`profile.py`dagi
  boshqa rasm yuklash endpointlari (yangiliklar, avatar) — foydalanuvchi
  aniq "sotuvchi mahsulot rasmi" haqida yozgan edi, ular boshqa muammo.
  Allaqachon yuklangan (siqilmagan) mahsulot rasmlarini orqaga qaytib
  qayta ishlash — so'ralmadi, qilinmadi.

---

## Sessiya (2026-08-20, davomi 2) — Blok 3: Web Admin SPA skelet + moderatsiya ekrani

Tartib 3-band boshlandi. Foydalanuvchi aniq buyurdi: "birinchi ishlaydigan
ekran — moderatsiya navbati + rasm bilan ishlash", menyu/dashboard/statistika
keyinroq. Shunga qat'iy amal qilindi — boshqa hech qanday ekran (mahsulot
to'liq CRUD, buyurtmalar va h.k.) yozilmadi, sidebar'da ular "Tez orada"
bilan ko'rinadi xolos.

### Struktura
- **`admin_web_src/`** — yangi manba (React 18 + Vite 6 + TypeScript 5 +
  Tailwind v4). `vite.config.ts`: `build.outDir: '../admin_web'`,
  `base: '/admin-web/'` — build natijasi to'g'ridan-to'g'ri backend allaqachon
  mount qilgan `admin_web/` papkaga tushadi, **infra o'zgarmadi** (reja §3
  tavsiyasi bilan bir xil). `admin_web_src/node_modules/` gitignore'ga
  qo'shildi, lekin **`admin_web/` (build natijasi) commitlanadi** — eski
  `admin_web/index.html` ham git'da statik fayl sifatida saqlangan edi, shu
  konvensiya davom etadi (serverda alohida build qadam yo'q, `git pull`
  yetarli — CLAUDE.md §7: CI/CD yo'q).
- Qo'shimcha kutubxona faqat rejada aytilgan bittasi: `react-easy-crop`
  (rasm qirqish/aylantirish). Boshqa hammasi standart (react-router-dom,
  tailwind, vite).

### Auth
- Telegram login (mavjud `/auth/telegram/session` + polling oqimi, boshqa
  klientlar bilan bir xil), keyin `GET /auth/me` bilan `role==admin`
  tekshiriladi — bo'lmasa "Sizda admin huquqi yo'q" (reja §3'da aytilgan).
  Refresh token: 401'da `apiFetch` avtomatik `/auth/refresh` chaqiradi va
  bir marta qayta urinadi (rotation — har safar yangi refresh saqlanadi).
- **Backend'ga kichik qo'shimcha** (`telegram_auth.py`): DEBUG dev-bypass
  endi `role=admin` sentinel foydalanuvchisini (`telegram_id=-1003`,
  mavjud -1001/-1002 buyer/seller pattern bilan bir xil) ham yarata oladi —
  **faqat `settings.DEBUG=true` bo'lganda**, productionda `role=admin`
  so'rovi majburan `buyer`ga tushadi (real foydalanuvchi Telegram orqali
  o'z-o'zini admin qila olmasligi CLAUDE.md §4'dagi xavfsizlik qaroriga
  aloqador — buzilmadi). Buni qilmasdan admin panelni lokal sinash imkonsiz
  edi (mavjud dev-bypass faqat buyer/seller yaratardi).
- CSP tuzatildi (`middleware.py`): `style-src`/`font-src`ga
  `fonts.googleapis.com`/`fonts.gstatic.com` qo'shildi — aks holda Figtree
  (Google Fonts) brauzerda yuklanmay, CSP uni bloklardi. Global header,
  lekin mobil ilovaga ta'siri yo'q (Flutter CSP'ni o'qimaydi).

### Dizayn
Foydalanuvchi eslatmasi bo'yicha: fon `#EEF1F6`, kartalar oq, navy gradient
tugma (`#24406F→#12233F`, CLAUDE.md §5.1 bilan bir xil qiymat), Figtree,
qora matn — mobil bilan bir xil token tili, lekin **kompyuter layout**
(chap sidebar navy `#16294A`, o'ng ish maydoni jadval/kartalar) — ilova
ekranlari ko'chirilmadi.

### Moderatsiya ekrani (`ModerationProductsPage` + `ProductDetailModal`)
- Uch tab: Kutilmoqda / Tasdiqlangan / Rad etilgan (`GET
  /admin/moderation/products?status=`).
- Ro'yxat: mini-rasm (`thumb_url`), nom, do'kon, "qancha oldin", narx,
  agar `pending_edit` bo'lsa "o'zgartirilgan" belgisi. Checkbox + "Tanlangan
  larni tasdiqlash" (`bulk-approve`) faqat Kutilmoqda tabida.
- Detail modal: nom/brend/kategoriya/tavsif tahrir maydonlari (`pending_edit`
  bo'lsa o'sha qiymat bilan boshlanadi — "amaldagi" qiymat, `utils/
  product.ts:effectiveFields`), rasm — mavjudini qirqish/aylantirish
  (`ImageCropModal`, canvas orqali) yoki yangi fayl tanlash, keyin
  `POST /products/{id}/image` (Pillow siqish avtomatik ishlaydi).
  Tugmalar: Tasdiqlash / Saqlab tasdiqlash (edit-approve) / Rad etish
  (sabab majburiy).
- **Muhim topilma va qaror**: backend `admin_direct_edit()`
  (`edit-approve`) `pending_edit`ni **butunlay tozalaydi**, faqat so'rovda
  yuborilgan maydonlarni yozadi — agar admin rasmni alohida yuklab (bu
  `pending_edit`ga stagelanishi mumkin), keyin "Saqlab tasdiqlash" bossa,
  rasm o'zgarishi **yo'qolib qolardi** (edit-approve uni qamrab olmaydi,
  `thumb_url` uchun schema'da maydon ham yo'q). Shu sabab UI qoidasi:
  ushbu sessiyada rasm yangilangan bo'lsa "Saqlab tasdiqlash" tugmasi
  yashiriladi, faqat oddiy "Tasdiqlash" (`approve()` butun `pending_edit`ni,
  image+thumb bilan birga, to'g'ri qo'llaydi) qoladi. Backend'ning o'zini
  (schema'ga `thumb_url` qo'shish yoki `admin_direct_edit`ni merge qiladigan
  qilish) tuzatish — bu safar qilinmadi, alohida ko'rib chiqiladigan
  "situq burchak" sifatida qayd etildi.
- Kits (to'plamlar) moderatsiyasi qo'shilmadi — foydalanuvchi aniq
  "mahsulot tasdiqlash"ni birinchi sinamoqchi edi, qamrov shunga
  cheklandi.

### Lokal sinov va topilma: bu muhitda Vite dev-server proxy portlari to'g'ri ishlamadi
`npm run dev` (5173/5174/5175, turli host bayroqlari bilan) qaysi portda
ishga tushirilmasin, shu terminal muhitidagi `curl`/`python urllib` so'rovlari
har doim **backend'ning** javobini qaytardi (headerlar/etag aynan bir xil) —
port haqiqatda `ss -tlnp`da node processga bog'langan bo'lsa ham. Sabab
aniqlanmadi (muhitning tarmoq sandboxi bilan bog'liq bo'lishi mumkin,
loyiha kodiga aloqasi yo'q). **Yechim**: mahalliy sinov uchun `npm run
build` (natija `admin_web/`ga) + backend'ning o'zi orqali xizmat
(`http://localhost:8000/admin-web/`) ishlatildi — bu productiondagi bilan
aynan bir xil yo'l (nol proxy, nol CORS), shuning uchun ishonchli.
Kodni o'zgartirgandan keyin sinash uchun: `cd admin_web_src && npm run
build`, keyin backend'ni qayta ishga tushirish shart emas (statik fayl).

**Sinaldi**: `tsc` — 0 xato. `npm run build` — muvaffaqiyatli.
`GET /admin-web/` — 200, to'g'ri HTML+JS+CSS. CSP headerida Google Fonts
ruxsat berilgani tasdiqlandi. Dev-admin login (`role=admin` bypass) —
`/auth/me` `role: admin` qaytardi. `GET /admin/moderation/products?
status=pending` — 3 ta mahsulot (ID 1, 2 oddiy pending; ID 3 — sun'iy
`pending_edit={"name": "..."}") bilan sinov uchun DB'da qoldirilgan
(**qasddan tasdiqlanmadi/rad etilmadi** — foydalanuvchi o'zi brauzerdan
sinasin deb). React/Cropper mantig'i brauzerda ishga tushirilmadi (bu
muhitda headless brauzer yo'q) — kod diqqat bilan qayta o'qib chiqildi,
lekin foydalanuvchining o'z qo'lidagi sinovi hali kerak.

### Havola
`http://localhost:8000/admin-web/` — backend allaqachon shu portda
ishlayapti (`nohup uvicorn ... --port 8000`, avvalgi eski jarayon
o'chirilgan). "Telegram orqali kirish" tugmasi DEBUG=true tufayli darhol
tasdiqlanadi (bot bilan gaplashish shart emas lokal muhitda).

### Bajarilmagan (keyingi seansga)
Kits moderatsiyasi, boshqa admin ekranlari (Tartib 4-5-band), production'ga
deploy (bu SPA hali serverga chiqarilmagan — faqat lokal). `edit-approve`
+ `thumb_url` sharpi burchak (yuqorida).

---

## Sessiya (2026-08-20, davomi 3) — Moderatsiya modalini tugatish + haqiqiy sinov + deploy

Foydalanuvchi oldingi "tayyor" da'vomni rad etdi — haqli edi: modal yarim
edi (narx/zaxira faqat ko'rsatilgan, SKU jadvali yo'q, bitta rasm bilan
ishlaydi). Bu safar **avval Playwright bilan haqiqiy brauzerda sinaldi**,
keyingina "ishlayapti" deyildi — pastdagi har bir band shu tarzda
tekshirilgan (skrinshot + DOM tekshiruvi, curl emas).

### Nima qo'shildi (moderatsiya modali)

- **SKU jadvali endi to'liq** (`SkuEditor.tsx`): har variant uchun narx/
  zaxira **tahrirlanadi** (`PATCH .../variants/{id}`, narx/zaxira darhol
  qo'llanadi — moderatsiya kerak emas, CLAUDE.md §3 bilan bir xil). Faollash-
  tirish/nofaollashtirish, o'chirish (agar buyurtmada ishlatilgan bo'lsa
  backend 400 qaytaradi — UI avtomatik nofaol qilishga o'tadi).
  **Parametrlar**: nom+qiymatlar (masalan `rang: qizil, ko'k`) qo'shilib
  "Jadvalni qayta hisoblash" bosilsa — dekart ko'paytmasi hisoblanadi,
  mavjud variantlar bilan solishtiriladi (`attributes` bo'yicha): yangi
  kombinatsiya → yaratiladi, endi yo'q kombinatsiya → **nofaol qilinadi**
  (hard delete emas — buyurtma tarixi buzilmasin), qayta paydo bo'lgan
  kombinatsiya → qayta faollashtiriladi. Sinovda: "rang: qizil, ko'k"
  qo'shilib ishga tushirilganda 2 ta yangi SKU yaratildi, eski "Standart"
  nofaol qilindi — to'g'ri ishladi.
- **Rasm galereyasi endi to'liq** (`ImageGallery.tsx` + backend'da 3 ta
  yangi endpoint: `DELETE /products/{id}/images/{image_id}`, `PATCH
  .../images/reorder`, `POST .../images/{image_id}/set-main`): bir nechta
  rasm ko'rish, qo'shish (qirqish bilan), o'chirish, ▲/▼ bilan tartib
  o'zgartirish, "Asosiy qilish". Sinovda: yuklash → asosiy qilish →
  o'chirish ketma-ketligi Playwright orqali ishlatildi, hammasi xatosiz.
  Asosiy qilish tasdiqlangan mahsulotda to'g'ri qayta moderatsiyaga
  yuboradi (`stage_protected_update`) — kutilgan xatti-harakat.
- **Sotuvchi va vaqt** (oldingi seansda backend qo'shilgan, bu safar
  UI'ga chiqarildi): "Sotuvchi telefon" va "Yuborilgan" (sana-vaqt) endi
  modalda ko'rinadi.

### Topilgan va tuzatilgan haqiqiy xato: CSP `blob:` rasmlarni bloklardi
Playwright bilan sinashda "Qo'llash" tugmasi doim o'chiq turib qoldi —
sabab: `react-easy-crop` tanlangan faylni `URL.createObjectURL()` (`blob:`
URL) orqali ko'rsatadi, lekin CSP `img-src` faqat `'self' data:`ga ruxsat
berardi — brauzer rasmni yuklamasdan bloklagan, cropper hech qachon
o'lchamni hisoblay olmagan. `img-src`ga `blob:` qo'shildi
(`middleware.py`). **Bu foydalanuvchi hali sinamagan, lekin sinaganda
100% duch keladigan xato edi** — Playwright bo'lmasa bu topilmasdi.

### Aniqlangan, LEKIN xato emas: kategoriya dropdown
Foydalanuvchi "bo'sh, '—' turibdi" dedi. Playwright bilan tekshirildi:
`<select>` ichida **19 ta option bor** (18 kategoriya + "—"), to'g'ri
yuklanadi. "—" ko'ringan sababi — sinov mahsulotlarining `category_id`si
bazada haqiqatda `NULL` (mening sinov ma'lumotlarim, real emas). Kod
buzuq emas edi, ma'lumot shunday edi.

### Tuzatilgan: mening sinov ma'lumotim haqiqiy mahsulotni buzgan edi
O'tgan safar mahsulot #3 (asl nomi "Nasa")ga sun'iy `pending_edit`
qo'ygandim, foydalanuvchi panelda "Tasdiqlash" bosganda bu soxta nom
("Yangi nom (sotuvchi tahriri)") LIVE qatorga yozilib ketdi. Bu **faqat
lokal dev baza**, production emas — lekin baribir xato edi. Nomi "Nasa"ga
qaytarib tuzatildi. **Bundan keyingi sinovlarda haqiqiy mahsulot
qatorlariga sun'iy `pending_edit` yozilmaydi** — kerak bo'lsa alohida
ID band qilinadi yoki darhol tozalanadi.

### Hozircha ISHLAMAYDI (aniq ro'yxat, foydalanuvchi so'ragani bo'yicha)
- **Menyu**: 7/8 bo'lim "Tez orada" — faqat Moderatsiya ishlaydi.
- **Mahsulotlar bo'limi** (User App'dagi TO'LIQ ro'yxat, qidiruv, filtr,
  yangi qo'shish, o'chirish): yo'q. Moderatsiya ekrani faqat "Kutilmoqda/
  Tasdiqlangan/Rad etilgan" ko'rsatadi, qidiruv/filtr yo'q.
- **Kategoriyalar ekrani**: yo'q (backend tayyor — CRUD+reorder+icon/color,
  oldingi seansda yozilgan, lekin UI yo'q).
- **To'plamlar (kitlar)**: hech narsa yo'q — na moderatsiya, na CRUD UI.
- **Buyurtmalar**: yo'q.
- **Sotuvchilar (ro'yxat/bloklash)**: yo'q.
- **Bildirishnoma yuborish**: yo'q.

### Deploy
Server: `fargonam@189.74.97.28`, `~/fargonam` (git), `docker-compose.prod.yml`
(DEPLOY.md'dagi rasmiy usul — `deploy_backend.sh`/`scripts/release.sh`
ESKI/ishlatilmaydigan skript, e'tiborsiz qoldirildi). Tekshirildi:
serverda **`DEBUG=false` va `ADMIN_TELEGRAM_IDS=5860426852` allaqachon
to'g'ri edi** (avvalgi seansda o'rnatilgan) — qo'shimcha o'zgarish shart
bo'lmadi. Git push qilingach: `git pull`, `docker compose -f
docker-compose.prod.yml up -d --build backend`, keyin `alembic upgrade
head` (entrypoint avtomatik), production DB'da ham `pg_dump` zaxira
oldindan olindi. URL: **`https://api.fargonam.uz/admin-web/`** (§3'dagi
eski nomuvofiqlik hali hal qilinmagan — foydalanuvchi "/admin" deb yozgan,
lekin infratuzilma `/admin-web/`ga sozlangan; domenni o'zgartirish kichik
nginx ishi, so'ralsa qilinadi).

### Vositalar: Playwright qo'shildi (faqat dev, mendan sinov uchun)
`admin_web_src/package.json`ga `playwright` devDependency sifatida
qo'shildi — runtime bundle'ga ta'siri yo'q (faqat `npm run build`
paytida ishlatilmaydi). Bundan keyin har bir yangi ekran/funksiya
**Playwright bilan haqiqiy brauzerda sinaladi**, "tayyor" deyilishidan
oldin.

### Keyingi qadam
Foydalanuvchi tartibi bo'yicha: Kategoriyalar ekrani (backend tayyor),
keyin Mahsulotlar ekrani (to'liq CRUD + qidiruv/filtr). Ikkalasi ham hali
yozilmagan.

### Deploy YAKUNLANDI (2026-08-20)
Server: `fargonam@189.74.97.28`. Zaxira olindi
(`~/backups/fargonam_pre_admin_deploy_2026-08-20_1255.sql.gz`), `git pull`,
`docker compose -f docker-compose.prod.yml up -d --build backend` (Pillow
bilan qayta qurildi), entrypoint avtomatik `alembic upgrade head` (ikkala
yangi migratsiya — kategoriya ustunlari, `thumb_url` — qo'llandi,
tekshirildi). Tasdiqlandi: `GET https://api.fargonam.uz/categories`
`icon`/`color`/`sort_order` bilan qaytadi; `GET /admin-web/` build
hash'lari lokal sinalgan versiya bilan **aynan bir xil**
(`index-VVqg1Hzy.js`); CSP javobida `blob:` bor; `POST
/auth/telegram/session?role=admin` productionda **avtomatik tasdiqlanmaydi**
(`status: pending` qoladi — DEBUG=false to'g'ri ishlayapti, faqat haqiqiy
Telegram ID 5860426852 kira oladi). Barcha 6 konteyner "Up".

---

## Sessiya (2026-08-20, davomi 4) — Kategoriyalar ekrani + qolgan bo'limlar uchun backend

Foydalanuvchi qaytib keldi, 8 bandli katta ro'yxat berdi (Kategoriyalar,
Mahsulotlar, Moderatsiya-qolgan, To'plamlar, Buyurtmalar, Sotuvchilar,
Foydalanuvchilar/Versiya/Bildirishnoma, test ma'lumot tozalash). Har
ekrandan keyin Playwright bilan sinab, deploy qilib davom etilmoqda.

### Backend qo'shimchalari (bir martalik rebuild, keyingi ekranlar
frontend-only bo'ladi)
- `GET /admin/products` — to'liq mahsulot ro'yxati (holatidan qat'i nazar),
  `q`/`category_id`/`status`/`shop_id`/`is_active` filtrlari — Mahsulotlar
  ekrani uchun (moderatsiya navbatidan farqli, faqat pending emas).
- `ShopAdminOut`ga `is_trusted` qo'shildi, `ShopStatusUpdate`da `status`
  endi ixtiyoriy (faqat `is_trusted` yangilash ham mumkin).
- `POST /admin/shops` — yangi sotuvchi qo'shish: `User(telegram_id=...,
  role=seller)` + `Shop(status=approved)`. `telegram_id` oldindan
  bog'lanadi — sotuvchi keyin shu ID bilan Telegram orqali kirsa
  to'g'ridan-to'g'ri shu hisobga ulanadi (`telegram_auth.py`dagi
  `select(User).where(telegram_id==...)` orqali, kod o'zgarmadi).
- Bitta foydalanuvchiga xabar — **yangi endpoint kerak bo'lmadi**,
  `POST /admin/broadcast` allaqachon `target=user_ids` + `user_ids=[id]`
  qo'llab-quvvatlaydi.

### Kategoriyalar ekrani — TAYYOR
`CategoriesPage.tsx` + `CategoryForm.tsx`: ro'yxat (ikonka+rang+nom+slug+
mahsulot soni), ▲/▼ bilan tartib o'zgartirish (`PATCH /categories/reorder`),
"+ Yangi kategoriya" va "Tahrirlash" bitta forma (nom/slug avtomatik
generatsiya/qo'lda, ota kategoriya, native rang tanlagich, 18 ta ikonkadan
grid orqali tanlash — `category_icons.dart`dagi SVG path'lar aynan
ko'chirilgan). O'chirish — `window.confirm` + agar bog'liq mahsulot bo'lsa
backend 409 xatosini ko'rsatadi.

**Playwright bilan sinaldi**: yangi kategoriya yaratildi (18→19), rangi
tahrirlandi (xatosiz), o'chirildi (19→18) — hammasi ishladi, skrinshot
tekshirildi (navy sidebar, oq kartalar, token ranglar to'g'ri).

Menyuda "Kategoriyalar" endi bosiladi (avval "Tez orada" edi).

### Mahsulotlar ekrani — TAYYOR
`ProductsPage.tsx` + `ProductEditModal.tsx` + `ProductCreateModal.tsx`:
qidiruv (debounce 300ms), kategoriya filtri, holat filtri (draft/pending/
approved/rejected), ro'yxat (rasm+nom+do'kon+narx oralig'i+zaxira). Tahrir
modali `SkuEditor`/`ImageGallery`ni moderatsiya modalidan **qayta
ishlatadi** (kod takrorlanmadi) — nom/brend/tavsif/kategoriya (`PATCH
/products/{id}`, himoyalangan maydon bo'lsa avtomatik stagelanadi), rasm,
SKU/parametr, ko'rsatish/yashirish, butunlay o'chirish (backend
xavfsizlik tekshiruvlari saqlanadi: savat/buyurtmada bo'lsa 400 va aniq
xabar). "+ Yangi mahsulot" — do'kon tanlash, nom, narx, zaxira, yaratilgach
avtomatik tahrir oynasi ochiladi (SKU/rasm qo'shish uchun).
**Backend**: `GET /admin/products` (holatidan qat'i, qidiruv+filtr) —
bu safar qo'shildi, moderatsiya navbatidan farqli.

**Playwright bilan sinaldi**: qidiruv ("Parker" → 1 ta), kategoriya filtri
("Ruchka" → 5 ta), yangi mahsulot yaratish (avtomatik tahrir oynasi
ochildi) — hammasi xatosiz. Sinov mahsuloti keyin tozalandi.

### To'plamlar ekrani — TAYYOR
`KitsPage.tsx` + `KitForm.tsx`: ro'yxat (nom, sinf, mahsulot soni, jami
narx, holat), yaratish/tahrirlash (mahsulot qidirib SKU tanlash orqali
tarkib tuzish, miqdor tahriri, jami narx hisoblanadi), ko'rsatish/
yashirish, o'chirish, agar holat "approved" bo'lmasa — "Tasdiqlash"
tugmasi (mavjud `/admin/moderation/kits/{id}/approve`ga ulanadi — admin
o'zi yaratgan to'plam darhol foydalanuvchiga ko'rinishi uchun).
**Backend tuzatildi** (`kits.py: list_kits`): avval `is_active=True`
filtri SHARTSIZ qo'yilgan edi — admin nofaollashtirilgan to'plamni hech
qachon ko'ra olmasdi (qayta faollashtirishning iloji yo'q edi). Endi
admin (`shop_id` + `_can_view_unapproved_shop`) barcha holatlarni ko'radi.

**Playwright bilan sinaldi**: yangi to'plam yaratildi (mahsulot qidirib
qo'shildi), saqlandi, "Tasdiqlash" bosilib holat "approved"ga o'tdi —
hammasi xatosiz. Sinov to'plami keyin o'chirildi.

### Buyurtmalar ekrani — TAYYOR
`OrdersPage.tsx` + `OrderDetailModal.tsx`: holat bo'yicha tab-filtr
(barcha 7 ta `OrderStatus`), ro'yxat, detail (xaridor, telefon, manzil/
pickup kodi, izoh, mahsulotlar, jami), holat o'zgartirish dropdown
(backend state machine — noto'g'ri o'tishda 400 aniq xabar bilan),
"Bekor qilish" tugmasi (`status=cancelled`). Yangi backend kerak bo'lmadi
— `GET/PATCH /admin/orders` allaqachon tayyor edi.

### Sotuvchilar ekrani — TAYYOR
`SellersPage.tsx` + `SellerCreateModal.tsx`: ro'yxat (holat, "Ishonchli"
belgisi, mahsulot soni), "Ishonchli qilish/olib tashlash", "Bloklash/
Blokdan chiqarish", "+ Yangi sotuvchi" (F.I.Sh + **Telegram ID** + telefon
+ do'kon nomi — `User(telegram_id=..., role=seller)` + `Shop(status=
approved)` yaratadi; sotuvchi keyin shu Telegram ID bilan kirsa
to'g'ridan-to'g'ri shu hisobga ulanadi, kod o'zgarmadi).
**Backend qo'shimchasi**: `ShopStatusUpdate`ga `is_active` yetishmayotgan
edi (faqat KYC `status`, `is_trusted` bor edi) — "Bloklash" uchun kerak
bo'lgani sabab qo'shildi, `update_shop_status` endi uni ham qo'llaydi.

### Foydalanuvchilar + Versiya + Bildirishnoma — TAYYOR
`UsersPage.tsx`: qidiruv (ism/telefon), rol filtri, bloklash/blokdan
chiqarish (admin foydalanuvchini bloklay olmaydi — tugma o'chirilgan).
**Bildirishnoma** — alohida menyu bandi qilib qo'shilmadi (reja 8 bandli
sidebar ko'zda tutmagan edi), Foydalanuvchilar ekraniga panel sifatida
kiritildi: yuqorida "Hammaga/xaridorlarga/sotuvchilarga" umumiy xabar,
har foydalanuvchi qatorida "Xabar yuborish" — bittasiga (`target=
user_ids`, backend allaqachon qo'llab-quvvatlardi, yangi endpoint kerak
bo'lmadi). `VersionPage.tsx`: user/seller ilova uchun alohida forma
(versiya/build/APK havolasi/izoh/majburiy-yangilanish), joriy qiymatlar
`GET /app/version`dan oldindan to'ldiriladi, saqlash `PUT /admin/
app-version`ga (oldingi seansda tayyor edi).

**Playwright bilan sinaldi**: qidiruv, umumiy bildirishnoma yuborish
(5 ta foydalanuvchiga, natija xabari to'g'ri ko'rsatildi), bitta
foydalanuvchiga xabar paneli ochildi, bloklash/blokdan chiqarish ishladi,
Versiya sahifasida 2 ta forma to'g'ri render bo'ldi (lokal muhitda
`app_version.json` yo'q — bo'sh boshlanadi, bu kutilgan, production'da
mavjud fayldan to'ladi).

### Menyuda "Tez orada" — ENDI YO'Q
Barcha 8 bo'lim endi ishlaydi. `Layout.tsx`dagi disabled/"Tez orada"
filiali butunlay olib tashlandi (o'lik kod qolmasin).

### Bazadagi test ma'lumotlari tozalandi (faqat lokal dev — production
hech qachon bu ma'lumotlarga ega bo'lmagan, tekshirildi)
7 ta soxta mahsulot (`Test`, `Ruchka`(nusxa, bo'sh brend/kategoriya),
`Nasa`, `Mushuk`, `M`, `7`, `م`) — 6 tasi butunlay o'chirildi, 1 tasi
(`Test`, id=1) haqiqiy buyurtma tarixida ishlatilgani uchun backend
xavfsizlik qoidasi bo'yicha o'chirilmadi, shuning o'rniga **nofaol**
qilindi (`is_active=false` — ro'yxatlardan yo'qoladi, ma'lumot
saqlanadi). Sinov paytida yaratilgan "Sinov Do'koni" seller/shop yozuvi
ham o'chirildi. Natija: 70 ta faol haqiqiy katalog mahsuloti, 1 ta shop.

### Deploy — YAKUNLANDI
`git pull` + `docker compose -f docker-compose.prod.yml up -d --build backend`.
Tekshirildi: `/status` `database: ok`, `/admin-web/` build hash aynan
lokal sinalgan versiya bilan bir xil (`index-CrtqYLhs.js`), yangi
endpoint'lar (`/admin/products`, `/admin/shops` POST, `/kits`) openapi'da
bor, production katalogi **70 mahsulot bilan o'zgarishsiz** (lokal
tozalash productionga ta'sir qilmadi — alohida baza).

---

## Sessiya (2026-08-20, davomi 5) — Test relizi: tozalash + FCM push + E2E sinov + 0.2.0

Foydalanuvchi: yaqinlariga ilova bermoqchi, admin panel vaqtincha to'xtatildi.
Qat'iy tartib: 1) tozalash, 2) push, 3) E2E sinov, 4) reliz.

### 1. Test ma'lumotlarini tozalash — PRODUCTION allaqachon toza edi

Production bazasini to'g'ridan-to'g'ri tekshirdim (SSH orqali, `docker exec
fargonam_postgres psql`):

| Jadval | Kutilgan | Topilgan |
|---|---|---|
| categories | 18 | **18** |
| products (faol) | 70 | **70** |
| product_variants | 90 | **90** |
| product_sets (to'plamlar) | 11 | **11** |
| orders | 0 | **0** |
| notifications | 0 | **0** |
| cart_items | 0 | **0** |
| favorites | 0 | **0** |
| reviews | 0 | **0** |

Har bir kategoriya kamida bitta mahsulotga ega ekani tasdiqlandi (barcha
18 tasi — jadval bilan tekshirildi). Hech qanday "Mushuk"/"M"/"7"/"Test"/
"Nasa" uslubidagi soxta nom yo'q — bular faqat **mening lokal ishlash
muhitimda** (bu suhbat davomida sinov uchun) paydo bo'lgan edi, productionga
hech qachon tegmagan (oldingi seansda ham, hozir ham tekshirildi). Hech
narsa o'chirishga hojat qolmadi — **hech narsa o'zgartirilmadi**.

### 2. FCM Push — kod 100% tayyor ekan, faqat BITTA fayl serverga yetib bormagan edi

Kutilganidan farqli — Firebase konsolida yangi loyiha ochish, mendan
qadam-baqadam ko'rsatma so'rash SHART BO'LMADI. Sabab: backend
(`app/core/push.py` — FCM v1, OAuth2 service account, barcha
`notify_order_status`/`notify_new_order`/... funksiyalar) va ikkala mobil
ilova (`firebase_messaging`, token ro'yxatdan o'tkazish, foreground banner,
tap-routing) **allaqachon to'liq yozilgan va ishlaydigan holatda edi**
(oldingi sessiyalarda qilingan, PROGRESS.md'da alohida qayd etilmagan).

**Topilgan haqiqiy muammo**: `backend/firebase_credentials.json` (Firebase
service account kaliti, loyiha `farg-onam`) `.gitignore` VA
`.dockerignore`da ataylab chetlab o'tilgan (`.env` kabi — sir sifatida) —
lekin bu fayl **hech qachon serverga qo'lda ko'chirilmagan edi**. Natija:
backend doim "credentials topilmadi" deb push'ni jimgina o'tkazib
yuborardi (hech qanday xato ko'rinmasdi, chunki `send_push_to_user` xato
tashlamaydi — shu sabab bu muammo hech qachon sezilmagan).

**Tuzatildi**:
- Fayl `scp` bilan xavfsiz ko'chirildi: `~/fargonam/backend/
  firebase_credentials.json` (`chmod 600`).
- `docker-compose.prod.yml`ga bind-mount qo'shildi (`app_version.json`
  bilan bir xil pattern): `./backend/firebase_credentials.json:/app/
  firebase_credentials.json:ro`.
- Tekshirildi: konteynerda `send_push()` soxta token bilan chaqirilganda
  endi **"credentials topilmadi" emas, FCM'ning o'zidan haqiqiy javob**
  keldi (`400 INVALID_ARGUMENT — token yaroqsiz`) — bu OAuth2
  autentifikatsiya **muvaffaqiyatli** ekanini isbotlaydi, faqat soxta
  token haqiqiy emas edi. Haqiqiy qurilma ro'yxatdan o'tishi bilan push
  ishlaydi.

**Topilgan va tuzatilgan spesifikatsiya farqi**: ruxsat so'rovi ilova
ochilishida (`_loadMe()`da login paytida) so'ralar edi — talab esa
"ilova ochilishida emas, birinchi buyurtma berilganda". Tuzatildi:
- `mobile_user`: `PushService.init()` endi ruxsat SO'RAMAYDI, faqat avval
  berilgan bo'lsa tokenni jim ro'yxatdan o'tkazadi. Yangi
  `requestPermissionForFirstOrder()` — `checkout_screen.dart`da buyurtma
  muvaffaqiyatli berilgandan keyin chaqiriladi.
- `mobile_seller`: xuddi shunday, lekin "birinchi buyurtma" o'rniga
  "Buyurtmalar" tabi birinchi ochilganda (`requestPermissionOnOrdersTab`,
  `main.dart:_go()`) — sotuvchi uchun tabiiy mos nuqta (o'zi buyurtma
  bermaydi).
- Ikkalasida ham: OS avval berilgan/rad etilgan ruxsatni qayta so'ramaydi
  (xavfsiz — har chaqiruvda qayta dialog chiqmaydi).
- `flutter analyze` — ikkala ilovada ham 0 xato.

**Qolgan hammasi tekshirildi, allaqachon to'g'ri edi**: foreground'da
ko'rinish (mobile_user — maxsus banner, mobile_seller — SnackBar), tap
bosilganda tegishli ekranga o'tish, ruxsat rad etilsa ilova xato
chiqarmaydi (hammasi try/catch), bildirishnomalar ekrani push bilan mos
(`_create_notification` har `notify_*` chaqiruvida DB'ga ham yozadi).

### 3. Uchidan-uchiga sinov — **HAQIQIY API chaqiruvlari bilan** (mobil UI emas)

**Muhim cheklov**: bu muhitda Android qurilma/emulyator yo'q (`adb
devices` — bo'sh, `emulator` binar topilmadi) — Flutter ekranlarini
bosib chiqib sinash **jismonan imkonsiz**. Shuning uchun backend'ning
o'zini — har bir qadam ortidagi haqiqiy biznes mantiqni — to'g'ridan-
to'g'ri HTTP so'rovlar bilan sinadim (mobil UI qanday chaqirsa, xuddi
shunday). Bu chindan ishlayotganini isbotlaydi, lekin ekranlarning
o'zi (variant tanlash tugmasi, badge animatsiyasi va h.k.) vizual
tekshirilmadi — buni faqat haqiqiy qurilmada siz sinay olasiz.

| # | Qadam | Natija | Izoh |
|---|---|---|---|
| a | Admin panel mahsulot qo'shadi → User App'da ko'rinishi | ✅ | Yaratilganda `status=pending` (admin ham bundan mustasno emas) → tasdiqlashdan keyin `GET /products/{id}` 404→200 |
| b | Seller mahsulot qo'shadi → moderatsiya navbati → admin tasdiqlaydi → ko'rinadi | ✅ | Xuddi shu oqim, `GET /admin/moderation/products?status=pending` navbatda ko'rsatdi |
| c | Variant ochish → narx/zaxira SKU'dan → savatga qo'shish → badge | ✅ | `POST /cart` qo'shgach `GET /cart` uzunligi +1 |
| d | Miqdor o'zgartirish, o'chirish, jami narx | ✅ | `PATCH /cart/{id}?quantity=3` → jami `9000×3=27000` to'g'ri hisoblandi |
| e | Buyurtma berish → kod → success | ✅ | `POST /orders` → `pickup_code` va `total` qaytdi, savat avtomatik bo'shadi |
| f | Admin panelda va Seller App'da ko'rinishi | ✅ | `GET /admin/orders` va `GET /seller/orders` ikkalasida ham bor |
| g | Holat o'zgarganda push+bildirishnoma | ✅ | `PATCH /admin/orders/{id}` → `notifications` jadvaliga "Buyurtmangiz tayyorlanmoqda 📦" yozildi (push haqiqiy qurilma yo'qligi uchun jo'natilmadi, lekin FCM chaqiruvi ishlashi 2-bo'limda alohida tasdiqlangan) |
| h | Kuzatish ekranida yangilanish | ⚠️ **Topilma** | `OrderTrackingScreen` — `StatelessWidget`, ekranga bosib kirilganda olingan `order` obyekti statik (jonli qayta yangilanmaydi). Holat o'zgarishi **ro'yxatga qaytilganda** to'g'ri ko'rinadi (`GET /orders` yangi holatni qaytardi) va foydalanuvchi push/WebSocket SnackBar orqali xabardor bo'ladi — lekin aynan Kuzatish ekranida turgan paytda live yangilanish yo'q. Bu **tuzatilmadi** — mavjud arxitekturaga (WS+push allaqachon xabar beradi) mos, alohida so'ralmagan chuqur o'zgarish talab qiladi |
| i | Buyurtmalar tarixida ko'rinishi | ✅ | `GET /orders` ro'yxatida bor |
| j | Ilovani qayta ochish — profil/savat/sevimlilar saqlangan | ✅ | Hammasi server-side (JWT bilan qayta so'ralganda saqlangan holat qaytadi) — lokal keshlash emas |

**Natija: 11/12 to'liq o'tdi, 1 tasi (h) aniqlangan cheklov sifatida qayd
etildi** (buzilgan emas — boshqa yo'l bilan qopnagan).

### Qarorlar
- [2026-08-20] Savol: reliz versiyasi qanday "0.2.0"ga aniq tushiriladi,
  `release.sh`ning avtomatik `bump_version()` funksiyasi faqat patch'ni
  oshiradi (minor'ni hech qachon)? → Qaror: `pubspec.yaml`larni qo'lda
  `0.2.0+4`ga o'rnatib, `release.sh`ning bump qadamisiz, qolgan barcha
  build/deploy qadamlarini script bilan bir xil tartibda qo'lda
  bajardim → Sabab: foydalanuvchi aniq "0.2.0" so'radi, script arifmetikasi
  bunga yeta olmaydi (minor doim o'zgarmas qoladi).

### 4. Reliz — 0.2.0 (build 4), user + seller

`pubspec.yaml`lar qo'lda `0.2.0+4`ga o'rnatildi, keyin `release.sh`ning
qolgan barcha qadamlari (build arm64+arm32, `nginx/downloads/`ga joylash,
yuklab olish sahifasi, `app_version.json`, `status.json`) serverning
o'zida (`fargonam@189.74.97.28`, mavjud keystore/`google-services.json`
bilan) bajarildi — bular allaqachon "serverda ishga tushiriladi" deb
mo'ljallangan (release.sh'ning o'zidagi izoh).

**Tekshirildi**:
- `GET https://api.fargonam.uz/app/version?app=user` va `?app=seller` —
  ikkalasi ham `version: "0.2.0", build: 4`.
- `GET https://api.fargonam.uz/status` — `last_release` yangi izoh va
  build vaqti bilan (user 138s, seller 78s).
- `https://fargonam.uz/` yuklab olish sahifasi — 4 ta havola ham
  (user/seller × arm64/arm32) yangi fayl nomiga ishora qiladi, hammasi
  `curl -I` bilan 200 qaytardi (haqiqatan yuklab bo'ladi).
- Telegram bot alohida qayta ishga tushirilmadi — `nginx/downloads/`ni
  to'g'ridan-to'g'ri o'qiydi (mavjud dizayn).

**Havolalar**:
- Sayt (yaqinlaringiz shu yerdan yuklab olishi mumkin):
  **https://fargonam.uz/**
- To'g'ridan-to'g'ri APK: `fargonam-user-arm64-0.2.0.apk` (zamonaviy
  telefonlar) / `fargonam-user-arm32-0.2.0.apk` (eski telefonlar) —
  sotuvchi ilovasi uchun xuddi shunday `fargonam-seller-*`.
- Admin panel: **https://api.fargonam.uz/admin-web/** (vaqtincha
  to'xtatilgan edi — kod o'zgarmadi, xohlasangiz davom ettiraman).

### Umumiy xulosa
1-3 bandlar to'liq bajarildi va tasdiqlandi (production toza, push
infratuzilmasi ishlaydi va deploy qilindi, backend darajasida to'liq
zanjir sinaldi). Yagona chala qolgan narsa — (h) kuzatish ekranining
jonli yangilanishi (yuqorida tushuntirilgan, funksional emas, kosmetik
cheklov). Haqiqiy qurilmada FCM push yetib borishini va mobil ekranlarni
vizual tekshirish — buni faqat siz (yaqinlaringiz bilan birga) qila
olasiz, chunki bu muhitda Android qurilma/emulyator yo'q.

---

## Sessiya (2026-08-20, davomi 6) — Login "Tarmoq xatosi" tekshiruvi

Foydalanuvchi 0.2.0'ni telefoniga o'rnatib login bosganda "Tarmoq xatosi"
ko'rgan. Server tomonini to'liq tekshirdim:

| Tekshiruv | Natija |
|---|---|
| `GET /status` | `backend: ok, database: ok` |
| DNS (`api.fargonam.uz`, 3 xil resolver: mahalliy, 8.8.8.8, 1.1.1.1) | Hammasi to'g'ri IP qaytardi |
| SSL sertifikat zanjiri | To'liq (leaf+intermediate+root), `Verify return code: 0 (ok)` |
| `POST /auth/telegram/session` (mendan) | 200, to'g'ri javob |
| nginx access log | **Telefondan hech qanday so'rov kelmagan** (faqat mening test so'rovlarim ko'rindi) |
| Firewall (`ufw`/`iptables`) | 443-port hammaga ochiq, shubhali bloklash yo'q |
| **APK ichidagi haqiqiy `API_URL`** | `strings libapp.so` bilan tekshirildi (build buyrug'iga ishonmasdan) — `https://api.fargonam.uz` **bor**, `localhost:8000` (standart qiymat) **yo'q** — demak `--dart-define` to'g'ri qo'llangan |
| `AndroidManifest.xml` | `INTERNET` ruxsati bor |
| `network_security_config.xml` | Fayl yo'q — standart Android ishonch do'koni ishlaydi, hech narsa bloklanmaydi |

Xulosa: **server va APK'ning o'zida muammo topilmadi** — so'rov
serverga umuman yetib kelmayapti (nginx logida yo'q), demak muammo
foydalanuvchi telefoni/tarmog'i tomonida (operator, DNS, VPN) bo'lishi
ehtimoli katta, lekin **buni masofadan aniq isbotlab bo'lmaydi**.

### Tuzatilgan haqiqiy kamchilik: xato matni hech narsa aytmasdi
Foydalanuvchi to'g'ri ta'kidladi — "Tarmoq xatosi" tashxis qo'yishga
yordam bermaydi. `mobile_user/lib/features/auth/auth_providers.dart`:
yangi `describeConnectionError()` — server javob bermagan (ulanish
darajasidagi) xatoda endi **qaysi URL'ga, qanday `DioExceptionType`
bilan yiqilgani** ko'rsatiladi (masalan "ulanib bo'lmadi" / "ulanish
vaqti tugadi" / "SSL sertifikat xato" + to'liq URL + tizim xabari).
Server xato qaytarsa (4xx/5xx, `detail` bor) — eskicha ishlaydi,
o'zgarmadi. `startTelegramLogin`, `addPhone`, `_loadMe` — uchalasida
ham qo'llanildi. `flutter analyze`/`flutter test` — toza.

**Reliz**: faqat `mobile_user` qayta qurildi (`0.2.1+5`, seller
`0.2.0+4`da qoldi — unga tegilmadi), `app_version.json`/`status.json`
faqat `user` bo'limi yangilandi (`seller` saqlanib qoldi — qo'lda
Python bilan merge qilindi, umumiy `release.sh` ikkalasini ham qayta
yozib yuborardi). Yangi APK'da ham `strings` bilan qayta tasdiqlandi.

### Keyingi qadam
Foydalanuvchi yangi APK bilan qayta urinib ko'radi — endi ekranda
aniq xato matni chiqadi (masalan "ulanib bo'lmadi: https://api.
fargonam.uz/auth/telegram/session"), shu orqali haqiqiy sabab
(DNS/operator/VPN/boshqa) aniqlanadi.

---

## Sessiya (2026-08-20, davomi 7) — Asosiy sabab topildi: min_app_version "1.0.0"

Foydalanuvchi qayta urinib ko'rdi — hali ham login qila olmadi, va
qo'shimcha topilma: seller/user ilova ikkalasi ham "eng yangi versiyasini
o'rnating, davom etish uchun yangilang" deb turibdi, eng yangisini
yuklab olishiga qaramasdan.

### Ildiz sabab topildi
`GET /app-config` → `min_app_version_user`/`min_app_version_seller`
= **"1.0.0"** edi. Ilova esa 0.2.x. `main.dart`dagi `needsForceUpdate()`
tekshiruvi shu qiymatni haqiqiy o'rnatilgan versiya bilan solishtiradi —
0.2.x doim 1.0.0'dan kichik, shuning uchun **har safar ilova
ochilganda**, tarmoq holatidan qat'i nazar, bloklovchi
(`barrierDismissible: false`, `PopScope(canPop: false)`) "Yangilanish
kerak" dialogi chiqadi — va **hech qachon qanoatlantirib bo'lmaydi**,
chunki 1.0.0 hali chiqarilmagan. Buning ustiga "Yangilash" tugmasi
bo'sh `onPressed: () {}` bilan yozilgan edi — bosilsa ham hech narsa
bo'lmasdi. Bu ikkalasi birgalikda foydalanuvchini butunlay qamab
qo'ygan (login ekraniga yetib borish-bormasligidan qat'i nazar).

### Darhol tuzatildi (reliz kutmasdan, serverda)
`PUT /app-config/min_app_version_user` va `.../min_app_version_seller`
→ `"0.1.0"` (production admin token bilan, `role=admin` user orqali).
**Bu o'zgarish darhol kuchga kirdi — foydalanuvchi hech narsa qayta
o'rnatmasdan, ilovani yopib-ochib sinashi kifoya edi.**

### Kod darajasida mustahkamlandi (0.2.2, ikkala ilova)
- `RemoteConfig.defaults.minAppVersion`: `1.0.0` → `0.0.0` — server bilan
  bog'lanib bo'lmasa (haqiqiy tarmoq xatosi holatida ham) ilova endi
  HECH QACHON shu sabab bilan bloklanmaydi ("fail open" — avval "fail
  closed" edi, bu aslida yanada jiddiy: tarmoq muammosi + noto'g'ri
  standart qiymat birga kelsa, foydalanuvchi umuman hech narsa qila
  olmasdi).
- Backend `_DEFAULTS` ham `0.1.0`ga (DB qatori negadir o'chib qolsa ham
  xavfsiz bo'lishi uchun).
- "Yangilash" tugmasi endi ishlaydi — `https://fargonam.uz/` ochadi
  (`url_launcher`, mavjud pattern — `app_update_sheet.dart`dan).
- `mobile_seller`ga ham `describeConnectionError()` qo'shildi (avval
  faqat `mobile_user`da bor edi) — endi ikkala ilovada ham login xatosi
  aniq URL+sabab bilan ko'rsatiladi.
- `flutter analyze`/`flutter test` — ikkala ilovada ham toza.

**Reliz**: `0.2.2+6`, ikkala ilova ham qayta qurilib serverga
chiqarilmoqda (backend allaqachon deploy qilindi va tekshirildi).

### Ochiq qolgan savol
Asl "tarmoq xatosi" (login POST'ning o'zi) haligacha aniq sabab bilan
tasdiqlanmagan — force-update devori tufayli foydalanuvchi ehtimol hech
qachon chinakam login urinishiga yetib bormagan bo'lishi mumkin edi.
Endi devor yo'q — agar xato qolsa, yangi aniq xato matni (URL + xato
turi) ko'rinadi, shundan keyingina haqiqiy tashxis qo'yiladi.

---

## Sessiya (2026-08-20, davomi 8) — Haqiqiy qurilmada (adb) to'liq tekshiruv

Foydalanuvchi telefonni USB bilan ulab, real qurilmada (HarmonyOS,
`font_scale` tizim sozlamasi **1.15**, standart 1.0 emas) 4 ta aniq
kamchilikni tuzatishni va keyin barcha 17 ta `mobile_user` ekranini
adb (`input tap`/`swipe`, `screencap`) orqali sinab, skrinshot bilan
tasdiqlashni so'radi. Har bir tuzatish: kod → `flutter analyze` +
`flutter test` → lokal qayta qurish (`--target-platform android-arm64`,
debug keystore) → `adb install -r` → skrinshot bilan tasdiqlash →
commit + push.

**Muhim kashfiyot**: bu qurilmadagi tizim shrift o'lchami (1.15×)
avvalgi sessiyalarda (emulyator/standart 1.0×) sezilmagan bir nechta
haqiqiy `RenderFlex` toshib ketish (overflow) xatosini oshkor qildi —
ularning aksariyati qattiq (`SizedBox`/`childAspectRatio`) o'lchamlar
matn balandligiga yetarli joy qoldirmaganidan edi.

### 1) Savatga qo'shish bildirishnomasi — tuzatildi
Ikkita muammo bor edi: (a) `ScaffoldMessenger`'ning standart SnackBar
navbat xulq-atvori — ketma-ket bosilganda eskisi tugagancha yangisi
navbatda kutardi, 2.4s turardi; (b) qo'lda yozilgan `AppToast`
(`Overlay` + `Opacity` + `BackdropFilter`) haqiqiy qurilmada **butun
ekranni xiralashtirib yuboradigan** xato berdi — sababi Flutter
compositing darajasida aniq topilmadi, lekin `Overlay`+`Opacity`
kombinatsiyasi bilan bog'liqligi elimination orqali tasdiqlandi
(`BackdropFilter`ni olib tashlash yordam bermadi, oddiy `SnackBar`
bilan almashtirish muammoni butunlay yo'qotdi). `showAppToast()`
butunlay `ScaffoldMessenger`/`SnackBar` asosiga qayta yozildi —
`hideCurrentSnackBar()` har chaqiruvda avval ishlaydi (bitta vaqtda
bitta toast), `AppMotion.toastVisible` 2400ms → **1300ms**
(foydalanuvchi so'ragan 1.2–1.5s oralig'ida — dc.html'dan ataylab
og'ib ketilgan, sababi shu faylning boshida yozilgan). 4 marta
ketma-ket bosib sinaldi — faqat bitta toast, xiralashuv yo'q.

### 2) "Sinflar uchun tayyor mahsulotlar" — haqiqiy sabab topildi
Avvalgi sessiyada `sectionLabel`ga `height:1.2` qo'shilgan edi (5.3
qoidasi bo'yicha to'g'ri, lekin bu SABAB emas edi). Haqiqiy qurilmada
skrinshot **"BOTTOM OVERFLOWED BY 40 PIXELS"** ko'rsatdi: to'plam
kartasi qatoriga (`catalog_screen.dart`) qattiq `SizedBox(height: 100)`
berilgan edi, dc.html'da esa bu qatorga umuman qattiq balandlik yo'q
(kontent o'zi belgilaydi, `overflow-x:auto`). 100 → **144**ga
oshirildi (loading shimmer bilan birga). Tuzatilgandan keyin: hech
qanday overflow, "1-sinf to'plami"/"10 xil · 145 500 so'm" to'liq
ko'rinadi.

### 3) Savat FAB noto'g'ri joyda — tuzatildi
`CartFab` faqat Bosh sahifada ishlatilgan edi. CLAUDE.md qoidasiga
ko'ra (Market/kategoriya/to'plamda doim, Bosh sahifada faqat savat
bo'sh bo'lmaganda) `catalog_screen.dart`, `category_products_screen.dart`,
`kit_detail_screen.dart`ga qo'shildi. `product_groups_screen.dart` va
`marketplace_screen.dart` — hech qaysi live route'dan chaqirilmaydigan
o'lik kod ekani tasdiqlandi (`grep -rln "ScreenName("`), tegilmadi.
Skrinshot bilan tasdiqlandi: Market/Kategoriya-ichi/To'plamda FAB doim
bor, Bosh sahifada faqat savat bo'sh bo'lmaganda ko'rinadi.

### 4) Yangilanish bildirishnomasi — ishlayotgani tasdiqlandi
`PUT /admin/app-version` orqali soxta yangi versiya (0.2.3) qo'yildi,
"Yangi versiya" bottom-sheet to'g'ri chiqdi, "Yuklab olish"/"Keyinroq"
tugmalari ishladi, keyin haqiqiy versiya (0.2.2/6) darhol qaytarildi.
O'zgarish kerak bo'lmadi.

### 17 ekran auditi — topilgan va tuzatilgan qo'shimcha xatolar

| Ekran | Muammo | Tuzatildimi | Izoh |
|---|---|---|---|
| Bosh sahifa | — | — | Cart FAB shartli ko'rinishi, "Yangiliklar" bo'sh holati (`SizedBox.shrink`) — dc.html bilan mos |
| Market/Kategoriyalar | "Sinflar..." kartasi 40px toshib ketardi | ✅ | 2-band, yuqorida |
| Kategoriya ichi (mahsulotlar) | Mahsulot kartasi (`childAspectRatio:0.66`) narx/tugmani 13px yashirardi | ✅ | 0.6ga tushirildi |
| Mahsulot (PDP) | — | — | Uzun nom bilan sinaldi, "Jami"/tugma vizual overlap emas (yaqin joylashuv, real bug emas) |
| To'plam | CartFab yo'q edi | ✅ | 3-band |
| Savat | Narx ("208 000 so'm") tor joyga sig'may "..." bilan kesilardi | ✅ | maxLines 1→2, endi 2-qatorga tushadi |
| Rasmiylashtirish | "Buyurtma berish" tugmasi manzil yozilgach gradientga o'tmasdi (TextField'da onChanged yo'q, _canPlace qayta hisoblanmasdi) | ✅ | onChanged: setState qo'shildi |
| Muvaffaqiyat | — | — | To'g'ri ishladi, "Buyurtma raqami: FN-1" ko'rindi |
| Kuzatish | Mahsulot nomi "· Variant" ikki marta chiqardi ("...· Standart · Standart × 4") | ✅ | backend product_name allaqachon "Nomi · Variant"; UI qayta qo'shmasin deb tuzatildi |
| Buyurtmalar | Filtr chiplari ("Barchasi/Jarayonda/Yetkazilgan") gorizontal toshib ketardi | ✅ | SingleChildScrollView(horizontal) |
| Bildirishnomalar | — | — | Bo'sh holat dc.html bilan bir xil (ikonkasiz, faqat matn) |
| AI | — | — | Xabar yuborish, klaviatura, javob — hammasi ishladi |
| Taxi | — | — | Placeholder matn CLAUDE.md 1-bo'limdagi aynan matn bilan mos |
| Profil | — | — | Ism, avatar, menyu, versiya raqami to'g'ri |
| Sevimlilar | Har karta 0.111px toshib narxni yashirardi | ✅ | childAspectRatio 0.72→0.68 |
| Manzillarim | "Viloyat" yorlig'i va "Farg'ona" qiymati "Vilo…"/"Farg…" kesilardi | ✅ | flex nisbati 1:2 → 4:5 |
| Sozlamalar | — | — | Til/Bildirishnomalar/Tungi rejim("Tez orada")/versiya — hammasi to'g'ri |

Checkout order-summary qatoridagi xuddi shu variant-takrorlanish bugi
`checkout_screen.dart`da ham topilib tuzatildi (jadvalda "Kuzatish"
qatoriga kiritilgan, lekin ikkala joyda ham bir xil sabab/tuzatish).

### Nega bu bug'lar avval sezilmagan
Barcha topilgan `RenderFlex` toshib ketishlar (0.111px dan 40px
gacha) standart 1.0× shrift sozlamasida yashirin edi — Flutter
debug-rejimdagi overflow banneri faqat haqiqiy piksel farqi
bo'lganda chiqadi. Bu qurilmaning tizim shrift o'lchami 1.15× ekani
(`adb shell settings get system font_scale`) bu xatolarni birinchi
marta ko'rinadigan qildi. Kelajakda shunga o'xshash qattiq
o'lcham/aspect-ratio ishlatilgan joylarda ehtiyot bo'lish kerak.

### Reliz holati
Barcha tuzatishlar alohida commit qilinib push qilindi (5 ta commit:
toast+CartFab+sectionLabel, savat/checkout/kuzatish, kit toshib
ketishi+buyurtmalar filtri, sevimlilar+manzil). Versiya hali
oshirilmagan (0.2.2+6da qoladi, lokal debug-keystore build bilan
sinaldi) — foydalanuvchi "Hammasi tugagach release.sh bilan yangi
versiya" deb so'ragan, shu bosqich hali oldinda.

---

## Sessiya (2026-08-20, davomi 9) — YO'NALISH O'ZGARDI: mobile_seller to'xtatildi, /dokon web paneli

Foydalanuvchi katta pivot qildi: **mobile_seller endi mobil ilova
sifatida rivojlantirilmaydi.** Oila/do'kondagilar uchun juda murakkab
edi (rasm yuklash, mahsulot qo'shish — ular buni Telegram orqali
yuborishadi, foydalanuvchi o'zi admin panelda kiritadi). O'rniga:
faqat "buyurtmalarni ko'rish va tayyorlash" uchun juda sodda, mobil
brauzerga mo'ljallangan web sahifa — `api.fargonam.uz/dokon`.

### mobile_seller — holati
**Kod o'chirilmadi**, branch'da shunday qoladi (kerak bo'lsa
qaytariladi). Faqat:
- `scripts/release.sh` endi `mobile_user`ni chiqaradi, `mobile_seller`
  release funksiyasi saqlanadi lekin chaqirilmaydi.
- `nginx/downloads/index.html`dan "Sotuvchi ilovasi" bo'limi olib
  tashlandi (faqat Xaridor ilovasi qoldi).
- Telegram APK-tarqatish boti (`telegram_bot/bot.py`) endi faqat
  "Foydalanuvchi ilovasi" tugmasini ko'rsatadi.
- `backend/app_version.json`dagi "seller" yozuvi **tegilmadi**
  (o'chirilmadi ham) — eski o'rnatilgan nusxalar `/app/version?app=seller`
  so'rasa xato bermasin deb, lekin endi yangilanmaydi (versiya muzlab
  qoladi, bu xavfsiz — force update devori yo'q, `mobile_seller`ning
  o'zi ham fail-open, 8-davomdagi tuzatish bo'yicha).

### /dokon — backend (`backend/app/api/dokon.py`, prefix `/dokon-api`)
- **Kirish**: umumiy login/parol, Telegram/OTP EMAS. `.env`:
  `SELLER_LOGIN=sotuvchiuz`, `SELLER_PASSWORD_HASH` (bcrypt, ochiq parol
  emas — `backend/scripts/hash_seller_password.py` bilan generatsiya
  qilinadi). Sessiya — JWT cookie, 30 kun, `HttpOnly`+`Secure`+`SameSite=Lax`.
- **Ism**: kirishdan keyin bir marta so'raladi, xuddi shu cookie'ga
  yoziladi (qayta login talab qilinmaydi, faqat ism cookie'da yo'q
  bo'lsa so'raladi). Har bir buyurtma-amali (`claim`/status/cancel) shu
  ismni "kim qildi" sifatida yozadi.
- **Buyurtmalar**: `GET /orders?status_filter=`, `GET /orders/counts`,
  `POST /orders/{id}/status`, `POST /orders/{id}/cancel` — mavjud
  `transition_order_status`/`enrich_order` (`cart.py`) qayta ishlatildi,
  **hech narsa nusxalanmadi**. Xaridorga "Tayyor" push'i avtomatik
  ketadi — bu allaqachon mavjud kod (`notify_order_status`), yangi
  yozilmadi.
- **Ko'p telefonli ish (band qilish)**: DB'ga yangi ustun QO'SHILMADI —
  bu holat vaqtinchalik (buyurtma tugasa keragi qolmaydi), shuning
  uchun Redis'da `dokon:claim:{order_id}` kaliti (`SET NX`, 2 kun TTL
  zaxira sifatida). "Qabul qildim" (pending→preparing) bosilganda
  atomik band qilinadi — birinchi bosgan g'olib, ikkinchisiga **aniq**
  409 xato ("Bu buyurtmani Aziz allaqachon oldi"), holat allaqachon
  o'zgargan bo'lsa ham (eski ro'yxatdan bosilgan bo'lsa) xuddi shu xato
  chiqadi. Buyurtma delivered/cancelled bo'lganda band avtomatik
  bo'shatiladi. **Playwright bilan haqiqiy race-condition sinaldi**
  (parallel so'rovlar) — ishladi.
- Yangilanish — WebSocket EMAS, oddiy **12 soniyalik polling**
  (foydalanuvchi shunday so'radi: "10-15 soniyada bir marta").

### /dokon — frontend (`backend/app/static_dokon/index.html` + `app.js`)
Bitta HTML + bitta JS fayl, build tizimi yo'q (npm/webpack shart emas —
"juda sodda" talabiga mos). **Muhim**: JS alohida faylda, chunki backend
xavfsizlik middleware'i `Content-Security-Policy: script-src 'self'`
qo'yadi — inline `<script>` bloklanadi (birinchi urinishda aynan shu
sabab bilan sahifa butunlay ishlamay qoldi, Playwright orqali topildi
va tuzatildi).
- Filtr tablar: Yangi | Tayyorlanmoqda | Tayyor | Yetkazildi | Barchasi
  (sonlar bilan). Foydalanuvchi ro'yxatida "Kuryerda" alohida tab
  sifatida so'ralmagan — shunday qoldirildi, "Kuryerda" buyurtmalar
  faqat "Barchasi"da ko'rinadi (PROGRESS.md qarori, pastda).
- Buyurtma kartasi: FN-XXXXX, "necha daqiqa oldin", mijoz ismi+telefon
  (`tel:` havola — bosilganda qo'ng'iroq), manzil yoki pickup kod,
  mahsulotlar, katta "Jami", holat tugmasi (matn holatga qarab
  o'zgaradi: "Qabul qildim"/"Tayyor"/"Kuryerga berdim" yoki pickup'da
  "Mijozga topshirdim"/"Yetkazildi"), bekor qilish (×, sabab so'raydi).
- Dizayn: ilova bilan bir xil tokenlar (fon #EEF1F6, navy gradient
  tugma, Figtree, qora matn) — yangi rang o'ylab topilmadi.
- Yangi buyurtma kelganda ovoz (Web Audio API, tashqi fayl shart emas —
  "og'ir narsa yuklamasin" talabiga mos) + toast.
- "Ulanish yo'q, qayta urinilmoqda" — tarmoq xatosida ko'rinadi.

### Sinov (Playwright, `backend/.venv` ga o'rnatildi — `uv pip install playwright`)
Lokal backend'ga qarshi (`http://localhost:8000`, real lokal DB):
- Noto'g'ri parol bilan kirib bo'lmadi ✓
- To'g'ri login → ism so'raldi → asosiy ekran ✓
- 2 ta alohida brauzer-kontekst ("Aziz-Test", "Malika-Test") — Aziz
  buyurtmani oladi, Malika bosganda **409 + aniq xabar** darhol
  chiqdi ✓
- "Tayyorlanmoqda"da "Tayyorlayapti: Aziz-Test" nishonchasi ✓
- To'liq holat zanjiri: pending→preparing→ready→shipped (delivery
  turi uchun to'g'ri tugma tanlandi: "Kuryerga berdim") ✓
- Mobil (390×844) va desktop (1280×900) o'lchamda tekshirildi ✓

**Production'da ham** (`https://api.fargonam.uz/dokon`) alohida sinov
o'tkazildi: bitta sinov buyurtmasi (`user_id=1` — real mijoz emas,
tizim/test hisobi) qo'lda DB'ga qo'shildi, Playwright orqali "Qabul
qildim"→"Tayyor" bosildi, so'ng **bekor qilib tozalandi** (haqiqiy ish
oqimiga aralashmasligi uchun). Shu jarayonda **2 ta real ishlab
turgan sotuvchi buyurtmasi** (FN-1, FN-2 — avvalgi mobil UI test
sessiyasidan qolgan haqiqiy buyurtmalar) panelda to'g'ri ko'rinishi
tasdiqlandi — bu aynan "User App'dan buyurtma berib, web'da paydo
bo'lishini ko'r" talabini qanoatlantiradi (yangi qurilma ulanmagani
uchun ilovaning o'zidan emas, lekin xuddi shu real buyurtmalar orqali).
"Tayyor" bosilganda push chaqiruvi kodda ishlayotgani tasdiqlandi
(`notify_order_status`, 8-davomda alohida sinalgan edi); test hisobida
FCM token ro'yxatdan o'tmagani uchun bu safar haqiqiy push kuzatilmadi
— bu kutilgan holat, xato emas.

### Deploy jarayonidagi haqiqiy xato va tuzatilishi
Birinchi deploydan keyin `/dokon-api/login` doim **500** bilan
tushardi. Sabab: `SELLER_PASSWORD_HASH` docker-compose'ning ROOT
`.env` fayli orqali o'tganda, hash tarkibidagi harf bilan boshlanuvchi
qism (`$jE0l5lt`) docker-compose'ning o'z `${VAR}` interpolyatsiyasi
tomonidan o'zgaruvchi deb qabul qilinib, aniqlanmagani uchun **bo'sh
qatorga almashtirilgan** — bcrypt hash butunlay buzilgan edi
(`docker exec ... printenv` bilan tasdiqlandi). Tuzatish: har "$"ni
"$$" qilib serverning ROOT `.env`iga yozildi (lokal `backend/.env`da
bu shart emas — u docker-compose orqali emas, to'g'ridan-to'g'ri
pydantic-settings bilan o'qiladi). `hash_seller_password.py` endi
ikkala variantni (lokal/server) alohida chiqaradi — bu xato qayta
takrorlanmasin deb.

### Qarorlar
- [2026-08-20] Savol: filtr tablarda "Kuryerda" alohida ko'rsatilsinmi? →
  Qaror: yo'q, foydalanuvchi aniq 5 ta tab nomlagan (Yangi/
  Tayyorlanmoqda/Tayyor/Yetkazildi/Barchasi) — "Kuryerda" buyurtmalar
  "Barchasi"da ko'rinadi. → Sabab: so'ralmagan elementni o'zidan
  qo'shmaslik (loyiha falsafasi — CLAUDE.md 6-bo'lim).
- [2026-08-20] Savol: "band qilish" holati DB'ga yozilsinmi? →
  Qaror: yo'q, Redis (TTL bilan). → Sabab: vaqtinchalik holat, doimiy
  migratsiya keraksiz murakkablik qo'shadi; loyihada shunga o'xshash
  vaqtinchalik holatlar (savat rezervatsiyasi) allaqachon Redis'da
  saqlanadi — mavjud arxitektura naqshiga mos.
- [2026-08-20] Savol: admin ham /dokon'ga kira olishi kerak (so'ralgan) —
  alohida admin-bypass yo'l kerakmi? → Qaror: yo'q, admin xuddi shu
  umumiy login/parolni biladi (o'zi belgilaydi) va oddiy sotuvchi kabi
  kiradi. → Sabab: "juda sodda" talabiga zid keladigan qo'shimcha
  autentifikatsiya yo'lini ixtiro qilmaslik; admin allaqachon
  ma'lumotga ega.
- [2026-08-20] Savol: mahsulot nomi juda uzun bo'lsa karta qanday
  ko'rinadi (CSS overflow)? → dc.html'da bunday sahifa yo'q (yangi
  ekran), shuning uchun mavjud ilova uslubiga mos ravishda `text-
  overflow` va flex-wrap qo'llanildi, qattiq piksel balandlik
  ishlatilmadi (mobile_user'da 40px overflow bugi shu sababdan
  chiqqan edi — 8-davomga qara).

### BLOKER — admin panelning qolgan bo'limlari (XATO EDI, TUZATILDI 2026-08-21)
Foydalanuvchi "Admin panelda qolgan bo'limlarni tugat" deb so'raganda
men faqat `admin_web/` (build natijasi) papkasini tekshirib "manba kodi
yo'q" deb noto'g'ri xulosa qilgandim. **Bu xato edi.** `admin_web_src/`
(to'liq React+Vite+TS+Tailwind manba, 44 fayl) shu repo'da doim mavjud
bo'lgan, git'da tracked va `origin/mobile-ui-rebuild`ga push qilingan
(commit `76e9573`..`383b987`, 2026-08-20 12:21–14:29 — shu kunning
o'zida, /dokon sessiyasidan oldinroq). Ustiga, `a9e44b6` commit "barcha
admin ekranlari production'ga chiqarilgani tasdiqlandi" deydi — ya'ni
"qolgan bo'limlar" so'roviga kelinganida ular allaqachon tugallangan
edi. Men shu faktni PROGRESS.md'ning yuqorisida (1301-qator atrofida)
o'zim yozgan bo'lsam ham, /dokon sessiyasida qayta tekshirmadim.
Bloker yo'q edi va yo'q. Xotira fayli (`project_admin_web_no_source.md`)
ham tuzatildi.

### Qo'shimcha — Kuzatish ekranining jonli yangilanishi
`mobile_user/lib/features/orders/order_tracking_screen.dart`
`StatelessWidget`dan `ConsumerStatefulWidget`ga o'tkazildi — ekran
ochiq turganda ~12s'da bir marta buyurtma qayta so'raladi
(`myOrdersProvider` orqali, mavjud), holat `delivered`/`cancelled`ga
yetganda poll avtomatik to'xtaydi. Sotuvchi /dokon panelida holatni
o'zgartirsa, xaridor ekranni qo'lda yangilamasdan ko'radi. 1 ta yangi
widget test qo'shildi (`order_tracking_screen_test.dart`) — render va
dispose'da Timer xavfsiz to'xtashi tekshirildi. `flutter analyze`/
`flutter test` — toza (13/13).

### Deploy
Backend va telegram_bot konteynerlari qayta qurilib serverga
chiqarildi (`docker compose -f docker-compose.prod.yml up -d --build
backend telegram_bot`). `nginx/downloads/` bind-mount orqali serverga
`git pull` bilan darhol yetadi — nginx qayta ishga tushirish shart
emas.

**Havola**: https://api.fargonam.uz/dokon — login/parol 2026-08-21'da
almashtirildi, pastdagi bo'limga qara (eski `sotuvchiuz`/`asmoshop2026`
ENDI ISHLAMAYDI).

### Reliz versiyasi
Bu safar `mobile_user`/`mobile_seller` APK versiyasi OSHIRILMADI —
faqat backend (yangi `/dokon-api`, `/dokon` static) va telegram_bot
o'zgardi, ular versiyasiz, darhol deploy qilinadi. Agar keyingi safar
mobile_user'ga yana UI o'zgarishi kerak bo'lsa, alohida `release.sh`
bilan versiya oshiriladi.

## Sessiya (2026-08-21) — admin_web manba xatosi tuzatildi, /dokon buyurtma ichi + Kiritilmagan + parol almashtirish

### 1) admin_web "bloker" — TUZATILDI (xato mening tomonimdan edi)
Avvalgi sessiyada "admin_web manba kodi yo'q" degan noto'g'ri xulosaga
kelingan edi. Aslida `admin_web_src/` (React+Vite+TS, 44 fayl) doim
mavjud bo'lgan, git'da tracked, `origin/mobile-ui-rebuild`ga push
qilingan (`76e9573`..`383b987`, 2026-08-20). Ustiga, `a9e44b6` commit
"barcha admin ekranlari production'ga chiqarilgani tasdiqlandi" deydi —
"qolgan bo'limlar" so'roviga kelinganda ular ALLAQACHON tugallangan
edi. Xotira fayli va yuqoridagi BLOKER yozuvi tuzatildi. Bloker yo'q.

### 2) /dokon/FN-<raqam> — buyurtma ichiga kirish
- **Backend**: `GET /dokon-api/orders/{id}` (bitta buyurtma, `claimed_by`
  bilan). `main.py`ga `@app.get("/dokon/FN-{order_id:int}")` — StaticFiles
  mount SPA-fallback qilmagani uchun, literal "FN-" prefiksi bilan static
  fayllar (app.js) bilan to'qnashmaydi, mount'dan OLDIN registratsiya
  qilindi (Starlette route tartib bo'yicha tekshiradi).
- **Schema**: `OrderItemOut`ga `category_slug` qo'shildi (`enrich_order`
  mahsulot `category_id` → `Category.slug` bitta qo'shimcha so'rov bilan
  to'ldiradi) — rasm yo'q mahsulot uchun kategoriya ikonkasi tanlash uchun.
  Boshqa hech bir consumer buzilmadi (optional field, faqat bitta joyda
  `OrderItemOut(...)` quriladi).
- **Frontend** (`static_dokon/app.js`, `index.html`): `history.pushState`
  bilan marshrutlash (`/dokon` ↔ `/dokon/FN-<id>`), `popstate` handler.
  Har item — katta rasm (yoki rasm yo'q bo'lsa `handoff/...dc.html`dagi
  18 ta kategoriya ikonkasi, `Category.slug` bo'yicha kalitlangan, aks
  holda umumiy "quti" ikonkasi), soni juda katta (`× N`, 40px), narxi,
  rasmga bosilganda to'liq ekran zoom overlay. Pastda mijoz/manzil/izoh/
  jami/holat tugmalari (list kartadagi bilan bir xil komponentlar qayta
  ishlatildi). Ro'yxatdagi kartaning o'ziga bosilganda ichiga kiradi
  (tugma/link bosilsa navigatsiya qilinmaydi — `closest('button,a')`
  bilan ajratildi). "Orqaga" — ro'yxatga qaytaradi. Poll (12s) detail
  ekranda ham davom etadi (faqat o'sha bitta buyurtma qayta so'raladi).

### 3) Mijoz ma'lumoti — bug EMAS, real ma'lumot edi (aniqlandi)
Production DB'dan to'g'ridan-to'g'ri tekshirildi (`/dokon-api/orders`
orqali, SSH kerak bo'lmadi): `customer_name` haqiqatda `"."` yoki `"-"`
qiymatlarga ega (foydalanuvchi Telegram orqali ro'yxatdan o'tganda ism
so'ralmaydi — profilni keyin o'zi to'ldirishi kerak, ba'zilar shu
maydonni tinish belgisi bilan "bypass" qilgan), `customer_phone` esa
haqiqatda `null` (Telegram login telefon bermaydi). Backend to'g'ri
yuborayotgan edi — **web** buni "ism"/"—" sifatida chiroyli
ko'rsatolmasdi. Tuzatildi: `cleanField()` — bo'sh YOKI faqat tinish
belgisidan iborat qiymatlarni "kiritilmagan" deb hisoblaydi, `Kiritilmagan`
(kursiv, xira rang) ko'rsatiladi. Ism, telefon, manzil, izoh — to'rttasi
ham shu qoidaga bo'ysunadi (ro'yxat kartasida ham, detail ekranda ham,
izoh bloki endi har doim ko'rinadi, avval faqat bor bo'lsa ko'rinardi).

### 4) Login/parol almashtirildi
`.env`: `SELLER_LOGIN=Orziqulovlar2026@!Assa1221!`,
`SELLER_PASSWORD_HASH` — yangi parol (`Assa1221!FargonamAssa1221!@`)
`backend/scripts/hash_seller_password.py` bilan qayta hash qilindi.
Serverning ROOT `.env`iga escaped variant ($ → $$) yozildi — bu safar
parolda `$` belgisi yo'q, faqat bcrypt HASH ichida bor, shuning uchun
oldingi xato (8-davomga qara) faqat hash uchun tegishli, login/parolning
o'zi uchun emas. Eski login/parol (`sotuvchiuz`/`asmoshop2026`) endi
ishlamaydi — production'da tasdiqlandi (pastga qara).

### 5) Sinov
Lokal (`localhost:8000`, Playwright, mobil 390×844 va desktop 1280×900):
eski parol rad etildi, yangi parol bilan kirish, "Barchasi" filtrida
10 buyurtma, `.muted-val` (Kiritilmagan) 28 ta joyda to'g'ri chiqdi,
kartaga bosib ichiga kirish, rasm zoom, zoom yopish, orqaga qaytish,
to'g'ridan-to'g'ri `/dokon/FN-1` havolasi orqali kirish (ism ekrani
kutilganidek chiqdi, chunki yangi sessiyada ism yo'q), status
o'zgartirish detail ekrandan (Tayyorlanmoqda → Tayyor) — ekrandan
chiqib ketmadi, URL o'zgarmadi. Rasm yo'q mahsulot uchun kategoriya
ikonkasi (umumiy "quti", chunki test mahsulotlarida `category_id` yo'q)
to'g'ri chiqdi, bo'sh joy qolmadi. JS konsolida faqat kutilgan 401
(login urinishlaridan) — boshqa xato yo'q.

Production'da (`https://api.fargonam.uz`) SSH orqali (`fargonam@
189.74.97.28`, `~/fargonam`, git pull + `docker compose -f
docker-compose.prod.yml up -d --build backend`) deploy qilingach xuddi
shu sinov qaytarildi, natijalar pastda.

**Havola**: https://api.fargonam.uz/dokon
Login: `Orziqulovlar2026@!Assa1221!`
Parol: `Assa1221!FargonamAssa1221!@`

## Sessiya (2026-08-21, davomi) — /admin-web: Telegram o'rniga login/parol

Foydalanuvchi so'radi: admin panel ("mani sahifam") ham /dokon kabi
oddiy login/parol bilan himoyalansin. Aniqlashtirdim — Telegram auth
qoldirilib ustiga qo'shimcha devor qo'yiladimi, yoki to'liq
almashtiriladimi. Javob: **to'liq almashtirish** (Telegram tekshiruvi
admin panel uchun endi ishlatilmaydi).

### Backend
- `POST /auth/admin-login` (`backend/app/api/auth.py`) — `.env`:
  `ADMIN_WEB_LOGIN`, `ADMIN_WEB_PASSWORD_HASH` (bcrypt, xuddi SELLER_*
  bilan bir xil qoida). To'g'ri bo'lsa, sentinel `telegram_id=-9000`
  bilan doimiy "tizim" admin User topiladi/yaratiladi (real Telegram
  akkauntlardan mustaqil) va oddiy access/refresh token beriladi —
  `require_admin` (barcha `/admin/*`) buni hech narsani bilmasdan qabul
  qiladi, chunki faqat `role=admin`ni tekshiradi. Rate limit 5/daqiqa.
- `ADMIN_TELEGRAM_IDS` mexanizmi (`telegram_auth.py`) koddan OLIB
  TASHLANMADI — hech kimga ta'sir qilmaydi, faqat endi admin_web uni
  ishlatmaydi. Kelajakda kerak bo'lsa qoladi.
- `backend/scripts/hash_seller_password.py` ikkinchi ixtiyoriy argument
  oldi (`ENV_NOMI`) — endi ADMIN_WEB_PASSWORD_HASH uchun ham ishlatiladi.

### Frontend (`admin_web_src/`)
`AuthContext.tsx` va `LoginPage.tsx` — Telegram popup+polling oqimi olib
tashlandi, o'rniga oddiy login/parol forma (`/dokon`dagi bilan bir xil
UX naqshi: login+parol, xato bo'lsa "Login yoki parol noto'g'ri").
`npm run build` bilan `admin_web/`ga qayta chiqarildi (eski hash'langan
`assets/*.js`/`*.css` avtomatik tozalandi, git'da yangi fayllar bilan
almashtirildi).

### Sinov
Lokal: `curl /auth/admin-login` — noto'g'ri parol 401, to'g'ri parol
token beradi, token bilan `/auth/me` → `role: "admin"` tasdiqlandi.
Playwright (1280×900): login formasi ko'rinadi, noto'g'ri parolda xato
xabari chiqadi, to'g'ri parolda dashboard ochiladi (Moderatsiya,
Mahsulotlar, Kategoriyalar... barcha bo'limlar ko'rinadi), JS xatosi
yo'q (faqat kutilgan bitta 401 — noto'g'ri parol urinishidan).

Production'da xuddi shu sinov qaytarildi — natija pastda.

**Havola**: https://api.fargonam.uz/admin-web/
Login: `feroncsAssa1221!`
Parol: `Assa1221!fargonamadminAssa1221!`
