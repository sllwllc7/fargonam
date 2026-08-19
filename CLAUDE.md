# Fargonam — Loyiha Qoidalari

Farg'ona vodiysi uchun hududiy Super App (marketplace, taksi, yangiliklar).
Bu fayl loyihaning qonuni. Har bir vazifadan oldin qayta o'qi.
Boshqa har qanday manba (skill, eski hujjat, xotira) shu fayl bilan ziddiyatga tushsa — **shu fayl g'olib**.

To'liq texnik asos: `/home/feron/Documents/Super App System Architecture Guide.pdf` va
`Super App - Loyiha Master Strategiyasi va Texnik Specification.docx` (2026-08-12 da tasdiqlangan).

---

## 0. HAQIQAT MANBALARI VA ULARNING TARTIBI

### Backend, arxitektura, biznes mantiq uchun
1. **Shu fayl** (1–4 va 14-bo'limlar)
2. `FARGONAM_TZ.md`, `PRODUCTION_TODO.md`, `project_issues.md`
3. Mavjud kod (`backend/`, `admin_web/`)

### Mobil UI uchun (5–13-bo'limlar)
1. **Shu fayl**
2. **`handoff/Fargonam User App v2.dc.html`** — HTML prototip. Ranglar, matnlar, o'lchamlar, animatsiyalar, katalog ma'lumotlari — hammasi shu yerda, ishlaydigan holda.
3. `handoff/HANDOFF.md` — tavsif. Foydali, lekin **ichida eski versiyadan qolgan XATO qatorlar bor** (5.1-bo'limga qara).

HANDOFF.md bilan dc.html zid kelsa — **dc.html to'g'ri**. O'rtacha yechim tanlama, "ikkalasini birlashtirmoqchi" bo'lma.

Fayl nomida bo'sh joy bor — bash'da doim qo'shtirnoq ishlat:
`grep -n "..." "handoff/Fargonam User App v2.dc.html"`

**Ishni boshlashdan oldin bir marta:**
```bash
mkdir -p handoff
cp "Mobile app design request"/* handoff/
ls handoff/    # dc.html, HANDOFF.md, fergana-gate.png bo'lishi kerak
```

**Har ishni boshlashdan oldin — fayl haqiqiyligini tekshir:**
```bash
md5sum "handoff/Fargonam User App v2.dc.html"
# b3bc28ca50648663ea83630fb9de04ae
grep -c "Figtree" "handoff/Fargonam User App v2.dc.html"
# 3
grep -c "16294A"  "handoff/Fargonam User App v2.dc.html"
# 8
```
Mos kelmasa — fayl eskirgan/xato. ISHNI BOSHLAMA, foydalanuvchini ogohlantir.

### 0.1 `kutuku-ui` SKILL — TO'LIQ BEKOR QILINADI

Agar `kutuku-ui` nomli skill yuklansa yoki avtomatik ishga tushsa — **butunlay e'tiborsiz qoldir**. U boshqa loyiha (Kutuku maketi) uchun yozilgan va bu loyihaga zid:

| kutuku-ui'dagi qoida | Bu loyihada |
|---|---|
| `design/reference/` PNG va `design/TOKENS.md` | **Manba emas.** Dizayn manbai faqat `handoff/…dc.html` |
| `flutter_screenutil`, `ScreenUtilInit`, `designSize 375×812` | **Ishlatilmaydi.** Baza kenglik **393**, oddiy logical pixel |
| "Gradient taqiqlanadi" | **Noto'g'ri.** Asosiy tugma va tab pufakchasi — gradient (5.2) |
| "Yuklanish — skeleton shimmer majburiy" | **Yo'q** (7-bo'lim) |
| "Bo'sh holat — illustratsiya + CTA qo'sh" | Faqat dc.html'da bor bo'lsa va aynan o'sha matn bilan |
| `flutter_animate`, `shimmer`, `animated_flip_counter` | Taqiqlangan (9-bo'lim) |
| "O'lchab ko'rsat va to'xta", "paket uchun so'ra" | Mobil UI ishida savol berilmaydi (6-bo'lim) |
| `Curves.easeInOut`, "300–400ms" | Aniq qiymatlar 5.2 da |

### 0.2 E'TIBORSIZ QOLDIRILADIGAN PAPKALAR

Bular eski/tajriba urinishlari. **O'qilmaydi, ko'chirilmaydi, misol qilib olinmaydi, ustiga qurilmaydi:**

```
design/reference/    mobile_ui_v3/    uikid/    testuiux/
gallery-dl/          stitch_markdown_project_documentation/
Mobile.zip           "Mobile app design request(1).zip"
```

Ular o'chirilmaydi ham — shunchaki tegilmaydi.

---

## 1. BIZNES BOSQICHLARI (roadmap)

- **1-bosqich (Avgust 2026, MVP):** Faqat o'quv qurollari monodo'koni faol. Barcha tovarlarni loyiha egasi sotadi (tashqi sotuvchilar yo'q). To'lov — offline, kuryer POS terminali orqali. Qolgan modullar UI'da "tez orada" holatida ko'rinadi.
- **2-bosqich (Sentabr 2026+):** Taksi/eltuv agregatori, AI Assistant, Yangiliklar, onlayn to'lovlar (Click/Payme/Uzum, xalqaro kartalar) ketma-ket yoqiladi.

Yangi modul qaysi bosqichga tegishli ekanini aniqlab, shunga mos scope'da qil — 1-bosqichda taksi/AI kabi 2-bosqich funksiyalarini to'liq qurishga urinma.

**Mobil UI uchun aniqlik:** dc.html'da Taksi va AI ekranlari **bor** va ular "tez orada" matni bilan chiziladi (masalan: `Farg'ona vodiysi bo'ylab tez va qulay taksi xizmati ustida ishlayapmiz. Ishga tushganda sizga xabar beramiz.`). Shu ekranlar aynan o'sha ko'rinishda quriladi — ortiqcha funksiya qo'shilmaydi, lekin ekranning o'zi tashlab ketilmaydi. Ingliz tilidagi "Coming soon" yozilmaydi.

---

## 2. TEXNIK STACK VA PAPKA XARITASI

- **Mobile:** Flutter — `mobile_user` (xaridor), `mobile_seller` (sotuvchi/haydovchi)
- **Umumiy UI paketi:** `packages/fargonam_ui`
- **Backend:** FastAPI (Python), PostgreSQL, Redis — `backend/`
- **Admin:** `admin_web/`  •  **Landing:** `landing/`
- **Deploy:** Docker (Postgres+Redis), nginx, systemd, Linux VPS

```
fargonam/
├── CLAUDE.md                 # shu fayl — yagona qonun
├── PROGRESS.md               # mavjud, USTIGA YOZILMAYDI — pastiga qo'shiladi
├── handoff/                  # tegilmaydi, faqat o'qiladi
│   ├── Fargonam User App v2.dc.html
│   ├── HANDOFF.md
│   └── fergana-gate.png
├── packages/
│   └── fargonam_ui/          # theme, tokenlar, umumiy widgetlar
│       └── lib/
│           ├── fargonam_ui.dart
│           ├── theme/        app_colors, app_typography, app_theme,
│           │                 app_shadows, app_motion
│           └── widgets/      primary_button, app_card, qty_stepper, price_text,
│                             floating_tab_bar, cart_fab, depth_carousel, toast, chip
├── mobile_user/              # mavjud ilova — 5.0 ga qara
├── mobile_seller/            # mavjud ilova — 5.0 ga qara
├── backend/  admin_web/  landing/  nginx/  scripts/
```

`handoff/fergana-gate.png` → `mobile_user/assets/images/` ga nusxalanadi.

---

## 3. ARXITEKTURA TAMOYILLARI (backend — MAJBURIY, o'zgarmaydi)

1. **Modular Monolith + Domain-Driven Design.** Mikroservisga ERTA o'tish TAQIQLANADI — kichik jamoa uchun operatsion murakkablikni oshiradi. Backend bitta deploy qilinadigan artifact bo'lib qoladi, domenlar orasidagi chegara til darajasida (modul/import) ta'minlanadi.
2. **Bounded context'lar:** Identity, Marketplace, Mobility, Wallet — har biri alohida PostgreSQL schema'da (`identity.*`, `marketplace.*`, `mobility.*`, `wallet.*`). Bir domen boshqa domenning jadvaliga to'g'ridan-to'g'ri query bermaydi — faqat aniqlangan interfeys/service funksiyalari orqali.
3. **Wallet/moliyaviy operatsiyalar:** Double-entry bookkeeping (har doim `SUM(Debits) = SUM(Credits)`). Balans yangilanishi pessimistic lock (`SELECT ... FOR UPDATE`) yoki optimistic concurrency (`version` ustuni) bilan himoyalanadi. Race condition'ga yo'l qo'yilmaydi.
4. **Idempotency:** To'lov, buyurtma va dispatch endpoint'larida idempotency key majburiy — tarmoq retry'lari qo'sh to'lov/qo'sh buyurtma yaratmasligi kerak.
5. **Marketplace order splitting:** Ko'p sotuvchili savat parent order + har bir sotuvchi uchun child order'larga bo'linadi, har biri mustaqil lifecycle state machine'ga ega.
6. **Inventory:** Overselling'ni oldini olish uchun ikki bosqichli reservation — avval Redis'da vaqtinchalik decrement (TTL ~15 daqiqa), to'lov tasdiqlangach DB'da optimistic lock bilan permanent commit.
7. **Mobility (taksi, 2-bosqich):** Geospatial indexing uchun **Uber H3** (hexagonal grid), Geohash/QuadTree emas — H3 uniform neighbor distance beradi, surge pricing va batch dispatch matching uchun mos. Haydovchi lokatsiyasi Redis'da (`GEOADD`/`HSET`), TTL ~15 soniya.
8. **Event-driven aloqa:** Domenlar orasida asinxron event uchun NATS JetStream (Kafka emas — yengil operatsion yuk). Transactional Outbox Pattern: business yozuv va event bitta DB tranzaksiyasida `outbox_events` jadvaliga yoziladi, alohida worker uni broker'ga yuboradi.
9. **Search:** Katalog qidiruvi uchun MeiliSearch (Postgres asosiy transactional DB bo'lib qoladi, MeiliSearch faqat read-optimized index).

---

## 4. XAVFSIZLIK

Ikkita asosiy CRITICAL muammo (2026-08-13) hal qilindi:

- ~~`STATIC_OTP = "5555"`~~ — butunlay olib tashlandi. Uchala klient ham (mobile_user, mobile_seller, admin_web) Telegram login ishlatadi (`/auth/telegram/*`, `backend/app/api/telegram_auth.py`). `ADMIN_TELEGRAM_IDS` `.env`da to'ldirilgan. Hali qolgan: production HTTPS domenda `TELEGRAM_USE_POLLING=false` + `set_telegram_webhook.py`.
- ~~`DEBUG=true` production'ga chiqib ketishi~~ — `deploy_backend.sh` serverga nusxalangan `.env`da `DEBUG`ni majburan `false` qiladi (lokal dev `.env` `true` bo'lib qoladi — bu normal).

Shu bilan birga tuzatildi: access token muddati 30 kundan 15 daqiqaga tushirildi, refresh token rotation+revocation (`/auth/logout`), keystore parollari `build.gradle.kts`'lardan gitignored `key.properties`ga ko'chirildi, `POST /orders`ga Idempotency-Key qo'llab-quvvatlashi, `android:allowBackup="false"`.

Tashqi audit checklist (`AUDIT_CHECKLIST.md`) asosida yana bir qancha kamroq muhim topilma bor (UX/checkout, test coverage, FTS, HTTPS/cleartext traffic) — tafsilotlar `project_issues.md`da, hali tuzatilmagan, foydalanuvchi so'raganda navbatma-navbat ko'rib chiqiladi.

**Bu tuzatilmaguncha loyihani real foydalanuvchilarga ochiq deb hisoblama va bu haqda foydalanuvchini ogohlantirib tur.**

Mobil UI ishida ham amal qiladi:
- API kalitlar (Gemini va boshqalar) ilovada bo'lmaydi, `.env`da ham emas — faqat server proxy orqali
- `key.properties` va `google-services.json` git'ga qo'shilmaydi
- Telegram auth oqimi UI o'zgarishida buzilmaydi
- `android:allowBackup="false"` saqlanadi

---

# MOBIL UI QAYTA QURISH

Quyidagi 5–13-bo'limlar faqat `mobile_user`, `mobile_seller` va `packages/fargonam_ui` uchun.

## 5.0 STRATEGIYA — NIMA ALMASHADI, NIMA QOLADI

**Mavjud ilova o'chirilmaydi va noldan yozilmaydi.** Almashadigan narsa — faqat ko'rinish qatlami.

| Qoladi (TEGILMAYDI) | Almashadi |
|---|---|
| Backend ulanishi, API client, endpoint'lar | Barcha ekran widget'lari |
| Model / DTO / repository | Theme, ranglar, shriftlar, o'lchamlar |
| State management (mavjud yechim) | Navigatsiya animatsiyalari, tab bar |
| Telegram auth oqimi | Umumiy widgetlar → `packages/fargonam_ui` ga |
| Idempotency, order lifecycle mantiqi | UI matnlari (dc.html'dan) |

Qoidalar:
- Ekran UI'sini almashtirganda o'sha ekranning **mavjud biznes mantiqi buzilmasin** — repository chaqiruvlari, state, xato ishlovi o'z joyida qoladi
- Mavjud model dc.html'dagi ma'lumot bilan mos kelmasa (SKU, variant, zaxira) — **modelni o'zgartirma**, farqni `PROGRESS.md` → "Backend farqlari" ga yoz va UI'ni mavjud modelga moslab chiz
- Mock data yozilmaydi — real repository ishlatiladi. dc.html'dagi katalog faqat **ko'rinish namunasi**, ma'lumot manbai emas
- Backend'ga yangi endpoint yoki maydon kerak bo'lsa: **to'xta va so'ra** (14-bo'lim). Bu mobil UI ishidagi yagona savol beriladigan holat

---

## 5.1 HANDOFF.md DAGI BEKOR QILINGAN QATORLAR

Quyidagilar eskirgan. **Ularga umuman amal qilma:**

| ❌ HANDOFF.md'dagi xato | ✅ To'g'ri (dc.html'dan tasdiqlangan) |
|---|---|
| `solid #5B21B6, gradient EMAS`, radius 12px | Asosiy tugma: **gradient `#2A4A7F → #16294A → #0F1E38`** (135°), radius **16–17**, balandlik **52–54**, matn oq w700 |
| Savat FAB — apelsin `#F59E0B` | Savat FAB — **navy `#16294A`**, 60px dumaloq, oq ikonka |
| Markaziy Home tab "binafsha" | **Navy** gradient pufakcha (`#2A4A7F→#16294A`) |
| 5-bo'lim: `Plus Jakarta Sans` | **Figtree** (`google_fonts`) |
| "Hero CTA — oq tugma, to'q matn" | Bu **to'g'ri**, faqat Market hero kartasi uchun. Boshqa joyda emas. |

Loyihada `#5B21B6`, `#F59E0B` yoki binafsha/apelsin rang **umuman bo'lmasin**.

---

## 5.2 DIZAYN TOKENLARI (aynan shu qiymatlar)

```
background   #EEF1F6      surface      #FFFFFF
primary      #16294A      primaryDark  #0F1E38     primaryMid #2A4A7F
primaryLight #E3ECFA      tabBar       #0F1E33
success      #16A34A      successTint  #DCFCE7
danger       #DC2626      dangerTint   #FEE2E2
textPrimary  #000000      textSecondary #1C1C22    textMuted  #3F3F49
border       #E0E6EF

kategoriya tintlari T[] = [
  (#E3ECFA,#14243F) (#E3ECFA,#16294A) (#DCFCE7,#16A34A)
  (#E5EEF9,#2F5FB3) (#DDEAF8,#2F5FB3) (#E7EDF6,#3A6EA5)
]
```

- Shrift: **Figtree**, `GoogleFonts.figtreeTextTheme()`
- Karta radius 16–18 (katta 22), chip/pill 999
- Karta soyasi: `0 1px 2px rgba(25,25,112,.05)` + `0 12px 26px -16px rgba(25,25,112,.14)`, border 1px `rgba(27,0,63,.08)`
- Bosilganda `scale .92–.98` (`AnimatedScale`, 120ms)
- Ekran kirishi: 320ms, `Curves.easeOutCubic`, translateX 14→0 + fade
- Ro'yxat: fadeUp 10px, stagger 35–40ms
- **Asosiy egri chiziq:** dc.html'da `cubic-bezier(.2,.8,.2,1)` 43 joyda ishlatilgan — bu ataylab, bitta tizim. Flutter'da `Cubic(0.2, 0.8, 0.2, 1.0)` ni `AppMotion.standard` deb bir marta yoz va hamma joyda shuni ishlat. `Curves.easeInOut` va `Curves.linear` — ishlatilmaydi.
- Narx formati: `2 500 so'm` — **NBSP (\u00A0)** minglik ajratgich, "so'm" ajralmas
- HTML piksel = Flutter logical pixel. Baza kenglik 393.

Bu qiymatlar faqat `packages/fargonam_ui` ichida yoziladi. **Ekran fayllarida hardcode rang/o'lcham taqiqlanadi** — hammasi token orqali.

## 5.3 TIPOGRAFIKA METRIKALARI (eng ko'p unutiladigan joy)

dc.html'da matn stillari faqat `font-size` va `font-weight` emas:
- `letter-spacing`: `-.9px`, `-.8px`, `-.6px`, `-.4px`, `-.2px`, `-.1px`, `.4px`, `.5px`, `1.2px`
- `line-height`: `1.25`, `1.45`, `1.5`, `1.55`

Flutter default'da `letterSpacing: 0` va shriftning o'z `height`i. Ularni ko'chirmasang — rang va o'lcham to'g'ri bo'lsa ham matn boshqacha ko'rinadi. Bu "maketdan qilinmagan" degan eng aniq belgi.

- HTML `letter-spacing: -.8px` → Flutter `letterSpacing: -0.8` (aynan, konvertatsiyasiz)
- HTML `line-height: 1.45` → Flutter `height: 1.45`
- Har `TextStyle` da ikkalasi ham **majburiy**. Tushirib qoldirish — xato.
- dc.html'da topilmasa: sarlavha `letterSpacing: -0.4`, tana matni `height: 1.45`

`app_typography.dart` yozishdan oldin bir marta ishlat va chiqqan ro'yxatni asos qil:

```bash
grep -o "font-size:[^;\"]*\|font-weight:[^;\"]*\|letter-spacing:[^;\"]*\|line-height:[^;\"]*" \
  "handoff/Fargonam User App v2.dc.html" | sort | uniq -c | sort -rn
```

Barcha stillar `app_typography.dart` da nomlangan konstanta. Ekran faylida `TextStyle(...)` yozish taqiqlanadi.

## 5.4 PLATFORMAGA MOSLASHUV (6-bo'lim taqig'idan yagona ISTISNO)

Quyidagilar dc.html'da **yo'q** — brauzerda bo'lishi mumkin emas. Telefonda ular bo'lmasa ilova "o'lik" tuyuladi, shuning uchun **majburiy**:

**Haptika** (`package:flutter/services.dart`)
- `HapticFeedback.lightImpact()` — savatga qo'shish, yurakcha, tab almashish
- `HapticFeedback.selectionClick()` — variant/parametr tanlash, stepper +/−
- `HapticFeedback.mediumImpact()` — buyurtmani tasdiqlash
- Boshqa joyda yo'q. Ortiqcha ishlatish ham xato.

**Tizim UI**
- `SystemUiOverlayStyle`: status bar shaffof; ikonkalar navy sarlavhali ekranda `light`, oq fonda `dark`
- Har `Scaffold` da `SafeArea` — tab bar va Savat FAB gesture-bar ustida turadi
- `ScrollBehavior`: Android overscroll ko'k porlashi o'chiriladi, `ClampingScrollPhysics`

**Klaviatura** (dc.html'da 6 ta input: kategoriya qidirish, mahsulot qidirish, manzil, telefon, kuryer izohi, AI chat)
- `resizeToAvoidBottomInset: true`, klaviatura ochilganda faol maydonga avtomatik scroll
- Telefon: `TextInputType.phone`, format `+998 90 123 45 67`, `TextInputFormatter` bilan maska
- Checkout formasida `textInputAction` bilan maydondan maydonga o'tish
- AI chat: xabar yuborilgach ro'yxat pastga silliq scroll

**Navigatsiya**
- Android apparat "orqaga" tugmasi (`PopScope`) dc.html'dagi `back()` mantig'i bilan bir xil (dc.html 1051-qator)
- Ekran o'tishi: `PageRouteBuilder`, 320ms, `AppMotion.standard`, translateX 14→0 + fade
- **`MaterialPageRoute` default'i taqiqlanadi** — Android'da pastdan ko'tarilish beradi va butun animatsiya tizimini buzadi

**Matn toshishi**
- Har `Text` da `maxLines` + `TextOverflow.ellipsis`; dc.html'dagi `ellipsis`/`-webkit-line-clamp` bo'lgan 7 joyni aynan takrorla
- Har ekranni uzun matn bilan sinab ko'r (60 belgili mahsulot nomi, uzun manzil) — sariq-qora overflow chizig'i chiqmasin
- `Row` ichidagi matn doim `Expanded`/`Flexible` ichida

**Bosilish maydoni**
- Har bosiladigan element kamida 44×44
- Material ripple o'chiriladi, o'rniga `AnimatedScale`

## 5.5 ILOVA O'ZLIGI (APK ochilishidan oldin ko'rinadigan narsalar)

- Ilova nomi: **Fargonam** / **Fargonam Sotuvchi** (`AndroidManifest.xml` → `android:label`)
- `applicationId` mavjudi **o'zgarmaydi** (keystore va Telegram auth'ga bog'liq)
- **Launcher ikonka:** `fergana-gate.png` asosida navy (`#16294A`) fonli adaptive icon. Default ko'k Flutter ikonkasi qolmasin
- **Splash:** navy `#16294A` fon + oq logotip (`android:windowSplashScreenBackground`). Oq default ekran qolmasin

---

## 6. TAQIQLAR (eng muhim bo'lim)

**Dizaynda:**
- Yangi rang, gradient, shrift, radius, soya o'ylab topish
- Prototipda yo'q ekran, tugma, bo'lim, ikonka, animatsiya qo'shish (yagona istisno — 5.4)
- "Yaxshiroq bo'ladi" deb layout, tartib, o'lcham o'zgartirish
- Dark mode, tema almashtirish, responsive/tablet layout, orientatsiya
- Material 3 default'larini qoldirish (ripple, default AppBar, default FAB rangi, `MaterialPageRoute`)

**Matnda:**
- Yangi UI matni yozish yoki mavjudini "tuzatish" — barchasi dc.html'dan **copy-paste**
- Apostroflarni almashtirish: `‘` va `'` aynan saqlanadi (`qog‘oz`, `so'm`, `O‘chirg‘ich`)
- Ingliz tilidagi UI matni, lorem ipsum, "Coming soon"
- Emoji qo'shish (prototipda bo'lmasa)

**Kodda:**
- Ruxsat etilgan ro'yxatdan tashqari paket qo'shish (9-bo'lim)
- `flutter create` boilerplate'i: counter app, `MyHomePage`, template kommentariyalari
- Ortiqcha kommentariya — faqat murakkab matematika/animatsiya uchun 1 qator
- `TODO`, `FIXME`, bo'sh `// implement later`
- "Kelajak uchun" abstraksiya, ishlatilmaydigan class/interface/util
- Deprecated API (`withOpacity` → `withValues`, `MaterialStateProperty` → `WidgetStateProperty`)
- Testni o'tkazish uchun kodni soddalashtirish yoki testni `skip` qilish
- Mavjud biznes mantiqni, repository yoki model'ni "yo'l-yo'lakay" o'zgartirish (5.0)

**Hujjatda:**
- **Yangi** hujjat yaratish: ARCHITECTURE.md, CONTRIBUTING.md, `docs/` ichiga yangi fayl, README qo'shimchasi
- Mavjud `README.md`, `docs/`, `FARGONAM_TZ.md`, `PRODUCTION_TODO.md`, `project_issues.md` — **o'chirilmaydi va tegilmaydi**
- `PROGRESS.md` — ustiga yozilmaydi, faqat pastiga qator qo'shiladi

**Jarayonda:**
- Mobil UI ishida savol berib to'xtash. Noaniqlik bo'lsa: dc.html'ga qara → topilmasa best practice bo'yicha qaror qil → `PROGRESS.md` → "Qarorlar" ga 1 qator yoz → davom et
- Xatoni "keyin tuzataman" deb qoldirish
- Bosqichni tekshiruvsiz yopish (8-bo'lim)

---

## 7. HOZIR QILINMAYDI

Prototipda ham yo'q, shuning uchun UI qayta qurishda ham yo'q:

- Global qidiruv ekrani, filtr bottom-sheet (Kategoriya ekranidagi "Filtr" tugmasi ko'rinadi, lekin bosilganda hech nima qilmaydi — dc.html'dagidek)
- Skeleton loader, shimmer, oflayn holat, yangi xato ekranlari
- Xarita, manzil qo'shish formasi
- Buyurtmani bekor qilish
- Real mahsulot rasmlari — dc.html'dagi SVG ikonka-placeholder
- Dark mode, ko'p til (uz/ru/en)
- Yangi Analytics/Crashlytics/Sentry ulash
- CI/CD, GitHub Actions, Fastlane
- iOS sozlash — faqat **Android APK**

---

## 8. TUGALLANGANLIK MEZONI (DoD)

**Har bir ekran** yozilgandan keyin:

```bash
export PATH="$PATH:/home/feron/tools/flutter/bin"
flutter analyze                 # 0 error, 0 warning, 0 info
flutter test                    # barchasi yashil
```

**Har bosqich oxirida:**

```bash
flutter build apk --debug
```

- Xato chiqsa — o'zing tuzat va qaytadan ishlat. Xato qolgan holda davom etma.
- Har ekran uchun kamida 1 widget test: render bo'ladi + asosiy interaksiya ishlaydi (savatga qo'shish → badge yangilanadi)
- Har ekrandan keyin git commit: `feat(user): <ekran nomi> ekrani UI`
- `PROGRESS.md` ga qator qo'sh

**Ekranni yozishdan OLDIN majburiy:**
1. dc.html'dan o'sha ekranning `render<Ekran>` / `screen === '...'` blokini **boshidan oxirigacha** o'qi (`view` bilan qator oralig'ini ko'rsatib). `grep` bilan yuzaki qarash yetarli emas — matnlar, shartlar (`stock === 0`, `qty > 0`), badge mantiqlari, `letter-spacing` va `line-height` o'sha yerda.
2. `mobile_user` dagi **mavjud** o'sha ekranni o'qi — qaysi repository/state chaqiriladi, qanday xato ishlovi bor. Ular saqlanadi.

**Ekranni yopishdan oldin 13-bo'limdagi ro'yxatni tekshir.**

---

## 9. RUXSAT ETILGAN PAKETLAR

UI qatlamiga qo'shiladigan yangi paketlar: `google_fonts`, `flutter_svg`.
State uchun **mavjud yechim saqlanadi** — yangi state kutubxonasi qo'shilmaydi.
Mavjud `pubspec.yaml` dagi paketlar (dio, firebase va h.k.) o'z joyida qoladi.

**Qo'shilmaydi:** `get`, `provider`, `bloc`, `freezed`, `build_runner`, `auto_route`, `flutter_screenutil`, `flutter_animate`, `shimmer`, `animated_flip_counter`.

Boshqa paket kerak bo'lsa: sababini `PROGRESS.md` → "Qarorlar" ga yoz, keyin qo'sh.

Ikonkalar: dc.html ichidagi `icon(catId)` metodidagi SVG `path` string'larini Dart'ga ko'chirib `flutter_svg` bilan chiz. Tayyor ikonka kutubxonasidan o'xshashini olib qo'yma.

---

## 10. ISH BOSQICHLARI

**Seans qoidasi (majburiy):** har bosqich **alohida seansda**. Bosqich tugagach `PROGRESS.md` yangilanadi, commit qilinadi, seans yopiladi. Sabab: dc.html 108 KB — bitta seansda hamma ekranni yozganda oxirgilariga borib aniq matnlar esdan chiqadi va model o'zidan yoza boshlaydi. 3-bosqich 4–5 ekrandan iborat bo'laklarga bo'linadi.

**1-bosqich — Poydevor**
`packages/fargonam_ui`: to'liq theme + 5.2 tokenlari + 5.3 tipografika + `app_motion.dart` + umumiy widgetlar. Shu bosqichda 5.4 (haptika, SafeArea, ScrollBehavior, PageRouteBuilder) va 5.5 (nom, ikonka, splash) ham tugallanadi.
Suzuvchi tab bar animatsiyasi: aktiv ikonka navy pufakchada `translateY -24`, spring `cubic-bezier(.3,1.6,.5,1)` (Flutter: `Curves.easeOutBack` + `TweenAnimationBuilder`), pufakcha atrofida bar rangida 5px halqa ("o'yilib chiqqan" effekt), eski pufakcha pastga qaytadi, yozuv pufakcha ostida.
Natija: paket `mobile_user` ga ulanadi, 5 ta tab o'tishi ishlaydi, APK'da to'g'ri ikonka va splash.

**2-bosqich — Moslik tekshiruvi**
dc.html'dagi `buildData()` (837-qator) ni o'qi va mavjud model/repository bilan solishtir: 18 kategoriya, mahsulotlar, SKU kombinatsiyalari, 1–11 sinf to'plamlari, yangiliklar.
**Kod yozilmaydi** — farqlar jadval ko'rinishida `PROGRESS.md` → "Backend farqlari" ga yoziladi. Backend'da yo'q maydon topilsa, uni qayd et va 14-bo'lim bo'yicha so'ra.

**3-bosqich — Ekranlar UI'si**
HANDOFF.md 2-bo'limidagi tartibda, birma-bir, mavjud ekran ustiga. Har biridan keyin 8-bo'lim tekshiruvi.
UI mantiqi (dc.html'dagidek, backend ruxsat bergan darajada):
- Variant tanlanganda narx/zaxira o'sha SKU'dan
- Stepper zaxiradan oshmaydi; `stock == 0` → "Tugagan", tugma o'chiq (`opacity .65`)
- Savatga bir xil SKU qo'shilsa yangi qator emas, `qty` oshadi
- Kit — bitta qator: `variant: "To'liq komplekt · N xil"`
- Kategoriya qatoridagi yashil badge: savatdagi shu kategoriya mahsulotlari soni
- Savat FAB: Market/kategoriya/to'plamda **doim**; bosh sahifada faqat savat bo'sh bo'lmaganda (dc.html 1196-qator)
- Orqaga qaytish mantig'i dc.html 1051-qatordagidek

**4-bosqich — Seller App**
`fargonam_ui` ni qayta ishlatib `mobile_seller` UI'si. Xuddi shu dizayn tizimi. Eng muhim ekran — mahsulot formasi: parametr qo'shish → qiymatlar chip → **SKU jadvali avtomatik generatsiya** (dekart ko'paytmasi), har qatorga narx + zaxira. Parametrsiz mahsulot = 1 ta SKU. Mavjud backend endpoint'lari o'zgarmaydi.

**5-bosqich — Yakun**
12 va 13-bo'lim ro'yxatlarini to'liq tekshir → `flutter build apk --release` (ikkala ilova) → APK yo'llarini va bajarilgan ishlarni `PROGRESS.md` ga yoz.

---

## 11. PROGRESS.md

Mavjud fayl **ustiga yozilmaydi**. Oxiriga shu bo'lim qo'shiladi va shu yerga yoziladi:

```markdown
## Mobil UI qayta qurish (2026-08)

| Bosqich | Ekran/Modul | Fayl | Testlar | Analyze | Holat |
|---|---|---|---|---|---|

### Qarorlar
- [sana] Savol: ... → Qaror: ... → Sabab: ...

### Backend farqlari
- [ekran] dc.html'da bor, API'da yo'q: ...

### APK
user: ...    seller: ...
```

Uzun matn yozma — jadval va qisqa qatorlar yetarli.

---

## 12. YAKUNIY TEKSHIRUV RO'YXATI

- [ ] `flutter analyze` — 0 muammo (ikkala ilova + paket)
- [ ] `flutter test` — barchasi o'tdi
- [ ] `flutter build apk --release` — ikkalasi ham muvaffaqiyatli
- [ ] Barcha UI matnlari o'zbekcha va dc.html bilan bir xil
- [ ] Ekran fayllarida hardcode rang va `TextStyle(...)` yo'q
- [ ] Ekranlar ishlaydi, navigatsiya uzilmaydi, backend chaqiruvlari saqlangan
- [ ] Telegram auth oqimi ishlaydi
- [ ] Tab bar spring animatsiyasi va depth-carousel prototipdagidek
- [ ] Yangi hujjat yaratilmagan; README/docs/TZ tegilmagan

```bash
grep -rn "5B21B6\|F59E0B\|Plus Jakarta\|MyHomePage\|TODO\|FIXME" \
  --include=*.dart --include=*.yaml --include=*.xml mobile_user mobile_seller packages
grep -rn "MaterialPageRoute\|Curves.easeInOut\|Curves.linear" --include=*.dart mobile_user mobile_seller packages
grep -rn "withOpacity\|MaterialStateProperty" --include=*.dart mobile_user mobile_seller packages
grep -rln "TextStyle(" mobile_user/lib/screens mobile_seller/lib/screens
```

Hammasi bo'sh natija bersin.

---

## 13. "INSON QO'LI" RO'YXATI (har ekran yopilishidan oldin)

Javob "yo'q" bo'lsa — ekran tugamagan:

- [ ] Har `TextStyle` da `letterSpacing` **va** `height` bormi? (5.3)
- [ ] Har bosiladigan element bosilganda vizual javob beradimi? (`AnimatedScale`, ripple emas)
- [ ] Kerakli joyda haptika bor, ortiqcha joyda yo'qmi? (5.4)
- [ ] Bu ekranga o'tish `PageRouteBuilder` orqalimi?
- [ ] Apparat "orqaga" tugmasi to'g'ri ishlaydimi?
- [ ] Uzun matn bilan sinaldimi? Overflow chizig'i chiqmadimi?
- [ ] Input bo'lsa: klaviatura maydonni berkitmaydimi?
- [ ] Tab bar / FAB gesture-bar bilan ustma-ust tushmaydimi?
- [ ] Ekrandagi barcha matn dc.html'dan copy-paste'mi?
- [ ] Ro'yxat elementlari stagger bilan chiqadimi (35–40ms)?
- [ ] Mavjud repository/state chaqiruvlari saqlanganmi? (5.0)

---

## 14. ISHLASH TARTIBI

- **Backend, arxitektura, DB sxemasi, deploy** bo'yicha katta o'zgarish (masalan backend'ni schema-isolation'ga o'tkazish) — avval reja bilan kelishiladi, so'ngra amalga oshiriladi. Bexosdan katta qayta qurishni boshlama.
- **Mobil UI** (5–13-bo'limlar) — savol berilmaydi, qaror mustaqil qabul qilinadi va `PROGRESS.md` ga yoziladi. Yagona istisno: backend'ga yangi endpoint yoki model maydoni kerak bo'lsa — to'xta va so'ra.
- Flutter PATH'da emas:
  ```bash
  export PATH="$PATH:/home/feron/tools/flutter/bin"
  ```
- Android qurilma USB orqali ulanadi (`adb devices`), birinchi o'rnatishda qurilma ekranida ruxsat tasdiqlanadi.
- Ish `mobile-ui-rebuild` branch'ida olib boriladi, `master` ga to'g'ridan-to'g'ri commit qilinmaydi.
