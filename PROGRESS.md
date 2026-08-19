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

### Backend farqlari
- [Market/kategoriyalar] Dev bazada `categories` jadvali bo'sh (`GET /categories` → `[]`),
  garchi `products` jadvalida test mahsulotlari bor. Kategoriyasiz UI to'g'ri ishlaydi
  (bo'sh holat ko'rsatiladi), lekin haqiqiy ko'rinish uchun kategoriya ma'lumoti kerak.
- [Sinf to'plami] `KitItem` modelida kategoriya/slug yo'q — dc.html'dagi per-item
  kategoriya ikonkasi o'rniga bitta neytral ikonka ishlatildi (yuqoridagi Qarorlar
  yozuviga qarang).
- [Bildirishnomalar] Backend `Notification.type` faqat umumiy satr ("order",
  "seller_order", "ride", "chat", "promo", "system") — dc.html'dagi buyurtma
  bosqichi ichki farqi (prep/ready/done, har biri boshqa ikonka/rang) yo'q. Buyurtma
  turidagi bildirishnomalar uchun eng ko'p uchraydigan (tayyor/topshirildi) ikonkasi
  ishlatiladi.
(2-bosqich hali to'liq bajarilmadi — `buildData()` va mavjud model/repository to'liq
solishtiruvi shu yerga keyingi seansda yoziladi.)

### APK
user: `mobile_user/build/app/outputs/flutter-apk/app-debug.apk` (debug, muvaffaqiyatli)
seller: `mobile_seller/build/app/outputs/flutter-apk/app-debug.apk` (debug, muvaffaqiyatli —
faqat mavjud "Fargonam Biznes" ko'rinishida, dizayn 4-bosqichda almashadi)
