# FARGONAM — ISH QOIDALARI (majburiy)

Bu fayl loyihaning qonuni. Har bir vazifadan oldin qayta o'qi.
Bu yerdagi qoida bilan boshqa har qanday manba ziddiyatga tushsa — **bu fayl g'olib**.

---

## 0. HAQIQAT MANBALARI VA ULARNING TARTIBI

Ustunlik tartibi (yuqoridagi pastdagini bekor qiladi):

1. **Shu CLAUDE.md fayli**
2. **`handoff/Fargonam User App v2.dc.html`** — HTML prototip. Ranglar, matnlar, o'lchamlar, animatsiyalar, katalog ma'lumotlari — hammasi shu yerda, ishlaydigan holda.
3. `handoff/HANDOFF.md` — tavsif. Foydali, lekin **ichida eski versiyadan qolgan XATO qatorlar bor** (1-bo'limga qara).

Qoida: agar HANDOFF.md bilan dc.html bir-biriga zid kelsa — **dc.html to'g'ri**. Hech qachon o'rtacha yechim tanlama, "ikkalasini birlashtirmoqchi" bo'lma.

Fayl nomida bo'sh joy bor — bash'da doim qo'shtirnoq ishlat:
`grep -n "..." "handoff/Fargonam User App v2.dc.html"`

### 0.1 `kutuku-ui` SKILL — TO'LIQ BEKOR QILINADI

Agar `kutuku-ui` nomli skill yuklansa yoki avtomatik ishga tushsa — **uni butunlay e'tiborsiz qoldir**. U boshqa loyiha uchun yozilgan va bu loyihaga zid:

| kutuku-ui'dagi qoida | Bu loyihada |
|---|---|
| `design/reference/` PNG va `design/TOKENS.md` | Bunday papka yo'q. Manba faqat **dc.html** |
| `flutter_screenutil`, `ScreenUtilInit`, `designSize 375×812` | **Ishlatilmaydi.** Baza kenglik **393**, oddiy logical pixel |
| "Gradient taqiqlanadi" | **Noto'g'ri.** Asosiy tugma va tab pufakchasi — gradient (2-bo'lim) |
| "Yuklanish — skeleton shimmer majburiy" | **Yo'q.** 4-bo'limga qara — skeleton ishlatilmaydi |
| "Bo'sh holat — illustratsiya + CTA qo'sh" | Faqat dc.html'da bor bo'lsa va aynan o'sha matn bilan |
| `flutter_animate`, `shimmer`, `animated_flip_counter` | Taqiqlangan (6-bo'lim) |
| "O'lchab ko'rsat va to'xta", "paket uchun so'ra" | **Savol berma** (3-bo'lim) |
| "Faqat `presentation/` ga tegiladi" | Butun ilova noldan quriladi |
| `Curves.easeInOut`, "300–400ms" | Aniq qiymatlar 2-bo'limda |

Undan olinadigan yagona narsa — "jonlilik" tamoyili, u allaqachon 2.2 va 11-bo'limga kiritilgan. Boshqa hech nima.

---

## 1. HANDOFF.md DAGI BEKOR QILINGAN QATORLAR

Quyidagilar eskirgan. **Ularga umuman amal qilma:**

| ❌ HANDOFF.md'dagi xato | ✅ To'g'ri (dc.html'dan tasdiqlangan) |
|---|---|
| `solid #5B21B6, gradient EMAS`, radius 12px | Asosiy tugma: **gradient `#2A4A7F → #16294A → #0F1E38`** (135°), radius **16–17**, balandlik **52–54**, matn oq w700 |
| Savat FAB — apelsin `#F59E0B` | Savat FAB — **navy `#16294A`**, 60px dumaloq, oq ikonka |
| Markaziy Home tab "binafsha" | **Navy** gradient pufakcha (`#2A4A7F→#16294A`) |
| 5-bo'lim: `Plus Jakarta Sans` | **Figtree** (`google_fonts`) |
| "Hero CTA — oq tugma, to'q matn" | Bu **to'g'ri**, faqat Market hero kartasi uchun. Boshqa joyda emas. |

Loyihada `#5B21B6`, `#F59E0B` yoki binafsha/apelsin rang **umuman bo'lmasin**. Yozib qo'ysang — xato hisoblanadi.

---

## 2. DIZAYN TOKENLARI (theme.dart uchun aynan shu qiymatlar)

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
- **Asosiy egri chiziq:** dc.html'da `cubic-bezier(.2,.8,.2,1)` 43 joyda ishlatilgan. Bu ataylab — bitta tizim. Flutter'da uni `Cubic(0.2, 0.8, 0.2, 1.0)` deb bir marta `AppMotion.standard` sifatida yoz va hamma joyda shuni ishlat. `Curves.easeInOut` va `Curves.linear` — ishlatilmaydi.
- Narx formati: `2 500 so'm` — **NBSP (\u00A0)** minglik ajratgich, "so'm" ajralmas
- HTML piksel = Flutter logical pixel. Baza kenglik 393.

Bu qiymatlarni faqat `theme.dart` va `fargonam_ui` paketida yoz. **Ekran fayllarida hardcode rang/o'lcham yozish taqiqlanadi** — hammasi token orqali.

### 2.1 TIPOGRAFIKA METRIKALARI (majburiy — eng ko'p unutiladigan joy)

dc.html'da matn stillari faqat `font-size` va `font-weight` emas. U yerda:
- `letter-spacing`: `-.9px`, `-.8px`, `-.6px`, `-.4px`, `-.2px`, `-.1px`, `.4px`, `.5px`, `1.2px`
- `line-height`: `1.25`, `1.45`, `1.5`, `1.55`

Flutter default'da `letterSpacing: 0` va shriftning o'z `height`i. Ularni ko'chirmasang, rang va o'lcham to'g'ri bo'lsa ham matn **boshqacha ko'rinadi** — bu "maketdan qilinmagan" degan eng aniq belgi.

**Qoida:**
- HTML `letter-spacing: -.8px` → Flutter `letterSpacing: -0.8` (aynan, konvertatsiya yo'q)
- HTML `line-height: 1.45` → Flutter `height: 1.45`
- Har bir `TextStyle` da ikkalasi ham **majburiy yoziladi**. Tushirib qoldirish — xato.
- dc.html'da o'sha element uchun qiymat topilmasa: sarlavha `letterSpacing: -0.4`, tana matni `height: 1.45`.

`app_typography.dart` yozishdan oldin bir marta ishlat va chiqqan ro'yxatni asos qil:

```bash
grep -o "font-size:[^;\"]*\|font-weight:[^;\"]*\|letter-spacing:[^;\"]*\|line-height:[^;\"]*" \
  "handoff/Fargonam User App v2.dc.html" | sort | uniq -c | sort -rn
```

Barcha stillar `app_typography.dart` da nomlangan konstanta bo'ladi. Ekran faylida `TextStyle(...)` yozish taqiqlanadi.

### 2.2 PLATFORMAGA MOSLASHUV (3-bo'lim taqig'idan yagona ISTISNO)

Quyidagilar dc.html'da **yo'q**, chunki brauzerda bo'lishi mumkin emas. Lekin telefonda ular bo'lmasa, ilova "o'lik" tuyuladi. Shuning uchun ular **majburiy**:

**Haptika** (`import 'package:flutter/services.dart'`)
- `HapticFeedback.lightImpact()` — savatga qo'shish, yurakcha bosish, tab almashish
- `HapticFeedback.selectionClick()` — variant/parametr tanlash, stepper +/−
- `HapticFeedback.mediumImpact()` — buyurtmani tasdiqlash (checkout)
- Boshqa joyda haptika yo'q. Ortiqcha ishlatish ham xato.

**Tizim UI**
- `SystemUiOverlayStyle`: status bar shaffof, ikonkalar navy sarlavhali ekranda `light`, oq fonli ekranda `dark`
- Har `Scaffold` da `SafeArea` — pastki gesture-bar. Tab bar va Savat FAB uning ustida turadi
- `ScrollBehavior`: Android overscroll ko'k porlashi **o'chiriladi**, `ClampingScrollPhysics`

**Klaviatura** (dc.html'da 5 ta input bor: kategoriya qidirish, mahsulot qidirish, manzil, telefon, kuryer izohi, AI chat)
- `resizeToAvoidBottomInset: true`, klaviatura ochilganda faol maydonga avtomatik scroll
- Telefon: `TextInputType.phone`, format `+998 90 123 45 67` (dc.html placeholder'i), `TextInputFormatter` bilan maska
- Checkout formasida `textInputAction` bilan maydondan maydonga o'tish
- AI chat: xabar yuborilgandan keyin ro'yxat pastga silliq scroll

**Navigatsiya**
- Android apparat "orqaga" tugmasi (`PopScope`) har ekranda dc.html'dagi `back()` mantig'i bilan **bir xil** ishlaydi (1051-qatorga qara)
- Ekran o'tishi: `PageRouteBuilder`, 320ms, `AppMotion.standard`, translateX 14→0 + fade.
  **`MaterialPageRoute` default'i taqiqlanadi** — u Android'da pastdan ko'tarilish beradi va butun animatsiya tizimini buzadi

**Matn toshishi**
- Har `Text` da `maxLines` + `TextOverflow.ellipsis`. dc.html'dagi `ellipsis` / `-webkit-line-clamp` bo'lgan 7 joyni aynan takrorla
- Har ekranni **uzun matn bilan sinab ko'r** (60 belgili mahsulot nomi, uzun manzil). Sariq-qora overflow chizig'i chiqmasin
- `Row` ichidagi matn doim `Expanded`/`Flexible` ichida

**Bosilish maydoni**
- Har bosiladigan element kamida 44×44 (ikonka kichik bo'lsa `SizedBox` bilan kengaytiriladi)
- Material ripple hamma joyda o'chiriladi, o'rniga `AnimatedScale` (2-bo'lim)

### 2.3 ILOVA O'ZLIGI (APK ochilishidan oldin ko'rinadigan narsalar)

- Ilova nomi: **Fargonam** (`AndroidManifest.xml` → `android:label`). `fargonam_user` yoki `flutter_app` qolmasin
- `applicationId`: `uz.fargonam.user` va `uz.fargonam.seller`
- **Launcher ikonka:** `fergana-gate.png` asosida navy (`#16294A`) fonli adaptive icon. Default ko'k Flutter ikonkasi **qolmasin** — bu eng tez bilinadigan belgi
- **Splash:** navy `#16294A` fon + oq logotip, `android:windowSplashScreenBackground` orqali. Oq default ekran qolmasin
- `minSdk 21`, `targetSdk` — joriy barqaror versiya

---

## 3. TAQIQLAR (eng muhim bo'lim)

Quyidagilarni **hech qachon** qilma. Bularning har biri ishni buzadi:

**Dizaynda:**
- Yangi rang, gradient, shrift, radius, soya **o'ylab topish**
- Prototipda yo'q ekran, tugma, bo'lim, ikonka, animatsiya qo'shish (yagona istisno — 2.2)
- "Yaxshiroq bo'ladi" deb layout, tartib, o'lcham o'zgartirish
- Dark mode, tema almashtirish, responsive/tablet layout, ekran orientatsiyasi
- Material 3 default'larini qoldirish (ripple, default AppBar, default FAB rangi, `MaterialPageRoute`) — hammasi qo'lda sozlanadi

**Matnda:**
- Yangi matn yozish yoki mavjudini "tuzatish". Barcha UI matnlari dc.html'dan **copy-paste**
- Apostroflarni almashtirish: `‘` va `'` belgilarini aynan saqla (`qog‘oz`, `so'm`, `O‘chirg‘ich`)
- Ingliz tilidagi UI matni, lorem ipsum, "Coming soon"
- Emoji qo'shish (prototipda bo'lmasa)

**Kodda:**
- Ruxsat etilgan ro'yxatdan tashqari paket qo'shish (6-bo'limga qara)
- `flutter create` boilerplate'ini qoldirish: counter app, `MyHomePage`, template kommentariyalari, `// This widget is the root of your application.` va h.k. — hammasini o'chir
- Kod ichida ortiqcha kommentariya. Faqat murakkab matematika/animatsiya uchun 1 qator izoh
- `TODO`, `FIXME`, bo'sh `// implement later` qoldirish
- "Kelajak uchun" abstraksiya, ishlatilmaydigan class/interface/util
- Deprecated API (`withOpacity` → `withValues`, `MaterialStateProperty` → `WidgetStateProperty`)
- Test'larni o'tkazish uchun kodni soddalashtirish yoki test'ni `skip` qilish

**Hujjatda:**
- README.md, ARCHITECTURE.md, CONTRIBUTING.md, docs/ papkasi yozish
- Yagona ruxsat etilgan hujjat: **`PROGRESS.md`**

**Jarayonda:**
- Savol berib to'xtash. Noaniqlik bo'lsa: dc.html'ga qara → topilmasa best practice bo'yicha qaror qil → `PROGRESS.md` → "Qarorlar" ga 1 qator yoz → davom et
- Xatoni "keyin tuzataman" deb qoldirish
- Bosqichni tekshiruvsiz yopish (5-bo'lim)

---

## 4. HOZIR QILINMAYDI (kechiktirilgan)

1–4 bosqichda quyidagilar **yo'q**, chunki prototipda ham yo'q:

- Onboarding, OTP/SMS kirish (5-bosqichda)
- Xarita, manzil qo'shish formasi
- Global qidiruv ekrani, filtr bottom-sheet (Kategoriya ekranidagi "Filtr" tugmasi ko'rinadi, lekin bosilganda hozircha hech nima qilmaydi — dc.html'dagidek)
- Skeleton loader, shimmer, oflayn holat, xato ekranlari
- Buyurtmani bekor qilish
- Real mahsulot rasmlari — dc.html'dagi SVG ikonka-placeholder ishlatiladi
- Firebase, Analytics, Crashlytics, Sentry
- CI/CD, GitHub Actions, Fastlane
- iOS sozlash — faqat **Android APK**

---

## 5. HAR BOSQICH UCHUN TUGALLANGANLIK MEZONI (DoD)

**Har bir ekran** yozilgandan keyin, keyingisiga o'tishdan oldin:

```bash
flutter analyze                 # 0 error, 0 warning, 0 info
flutter test                    # barchasi yashil
```

**Har bosqich oxirida** (ekran emas — bosqich):

```bash
flutter build apk --debug       # muvaffaqiyatli
```

- Xato chiqsa — **o'zing tuzat va qaytadan ishlat**. Xato qolgan holda davom etma.
- Har ekran uchun kamida 1 widget test: ekran render bo'ladi + asosiy interaksiya ishlaydi (masalan savatga qo'shish → badge yangilanadi).
- Har ekrandan keyin git commit: `feat(user): <ekran nomi> ekrani`
- `PROGRESS.md` ga qator qo'sh: ekran nomi, fayl yo'li, test soni, holati.

**Ekranni yozishdan oldin majburiy qadam:**
dc.html'dan o'sha ekranga tegishli funksiyani (`render<Ekran>` / `screen === '...'` bloki) **to'liq o'qi** — boshidan oxirigacha, `view` bilan qator oralig'ini ko'rsatib. `grep` bilan yuzaki qarash yetarli emas: matnlar, shartlar (`stock === 0`, `qty > 0`), badge mantiqlari, `letter-spacing` va `line-height` qiymatlari o'sha yerda.

**Ekranni yopishdan oldin 11-bo'limdagi ro'yxatni o'z ichingda tekshir.**

---

## 6. RUXSAT ETILGAN PAKETLAR

1–4 bosqich: `flutter_riverpod`, `google_fonts`, `flutter_svg`
5-bosqich (backend): `dio`, `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `image_picker`

Boshqa paket kerak bo'lsa: nega kerakligini `PROGRESS.md` → "Qarorlar" ga yoz, keyin qo'sh.
**Ishlatilmaydi:** `get`, `provider`, `bloc`, `freezed`, `build_runner`, `auto_route`, `flutter_screenutil`, `flutter_animate`, `shimmer`, `animated_flip_counter`.

Ikonkalar: dc.html ichidagi `icon(catId)` metodidagi SVG `path` string'larini Dart'ga ko'chirib, `flutter_svg` bilan chiz. Tayyor ikonka kutubxonasidan o'xshashini olib qo'yma.

---

## 7. LOYIHA TUZILISHI (aynan shunday)

```
fargonam/
├── CLAUDE.md
├── PROGRESS.md
├── handoff/                     # tegilmaydi, faqat o'qiladi
│   ├── Fargonam User App v2.dc.html
│   ├── HANDOFF.md
│   └── fergana-gate.png
├── packages/
│   └── fargonam_ui/             # umumiy: theme, tokenlar, widgetlar
│       └── lib/
│           ├── fargonam_ui.dart
│           ├── theme/           app_colors, app_typography, app_theme,
│           │                    app_shadows, app_motion
│           └── widgets/         primary_button, app_card, qty_stepper, price_text,
│                                floating_tab_bar, cart_fab, depth_carousel, toast, chip
└── apps/
    ├── fargonam_user/
    │   └── lib/
    │       ├── main.dart
    │       ├── router/
    │       ├── data/            models/  mock/mock_catalog.dart  repository/
    │       ├── state/           riverpod providerlar
    │       └── screens/         home, catalog, kit, category, product, cart, checkout,
    │                            success, tracking, orders, notifs, ai, taxi, profile,
    │                            favs, address, settings
    └── fargonam_seller/         # 4-bosqichda
```

`fergana-gate.png` → `apps/fargonam_user/assets/images/` ga nusxala.

---

## 8. ISH BOSQICHLARI

**Seans qoidasi (majburiy):** har bosqich **alohida seansda** bajariladi. Bosqich tugagach `PROGRESS.md` yangilanadi, commit qilinadi va seans yopiladi. Sabab: dc.html 108 KB — bitta seansda 17 ekranni yozganda oxirgi ekranlarga borib aniq matnlar esdan chiqadi va model o'zidan yoza boshlaydi. 3-bosqichni ham 4–5 ekrandan iborat bo'laklarga bo'l.

**1-bosqich — Poydevor**
`fargonam_ui` paketi: to'liq theme + 2-bo'lim tokenlari + 2.1 tipografika + `app_motion.dart` + umumiy widgetlar. Shu bosqichda 2.2 (haptika, SafeArea, ScrollBehavior, PageRouteBuilder) va 2.3 (ikonka, splash, nom) ham tugallanadi.
Suzuvchi tab bar animatsiyasi shu bosqichda tugallanadi: aktiv ikonka navy pufakchada `translateY -24`, spring `cubic-bezier(.3,1.6,.5,1)` (Flutter: `Curves.easeOutBack` + `TweenAnimationBuilder`), pufakcha atrofida bar rangida 5px halqa ("o'yilib chiqqan" effekt), eski pufakcha pastga qaytadi, yozuv pufakcha ostida.
Natija: bo'sh 5 ta tab, o'tish animatsiyasi ishlaydi, APK'da to'g'ri ikonka va splash.

**2-bosqich — Ma'lumot qatlami**
dc.html'dagi `buildData()` (837-qator) ni Dart'ga aynan ko'chir: 18 kategoriya, barcha mahsulotlar, SKU kombinatsiyalari, 1–11 sinf to'plamlari, yangiliklar. Narx/zaxira raqamlari **aynan** o'sha. Modellar HANDOFF.md 3-bo'limidagidek. Riverpod providerlar + mock repository (`Future.delayed` bilan sun'iy kechikish qo'shma).

**3-bosqich — 17 ekran**
HANDOFF.md 2-bo'limidagi tartibda, birma-bir. Har biridan keyin 5-bo'limdagi tekshiruv.
Biznes qoidalari (majburiy):
- Variant tanlanganda narx/zaxira o'sha SKU'dan olinadi
- Stepper zaxiradan oshmaydi; `stock == 0` → "Tugagan", tugma o'chiq (`opacity .65`)
- Savatga bir xil SKU qo'shilsa yangi qator emas, `qty` oshadi
- Kit — bitta qator: `variant: "To'liq komplekt · N xil"`
- Kategoriya qatoridagi yashil badge: savatdagi shu kategoriya mahsulotlari soni
- Savat FAB: Market/kategoriya/to'plamda **doim**; bosh sahifada faqat savat bo'sh bo'lmaganda (dc.html 1196-qator)
- Orqaga qaytish mantig'i dc.html 1051-qatordagidek
- Buyurtma berilgach 8s dan keyin "tayyor" bildirishnomasi (prototipdagi timer)

**4-bosqich — Seller App**
`fargonam_ui` ni qayta ishlatib, HANDOFF.md 4-bo'limi. Xuddi shu UI, farq faqat funksiyada. Eng muhim ekran — mahsulot formasi: parametr qo'shish → qiymatlar chip → **SKU jadvali avtomatik generatsiya** (dekart ko'paytmasi), har qatorga narx + zaxira. Parametrsiz mahsulot = 1 ta SKU.

**5-bosqich — Backend**
HANDOFF.md 4-bo'limidagi REST endpointlar, mock repository o'rniga real client (interfeys o'zgarmaydi). OTP auth, FCM push, Gemini **faqat server proxy orqali** — API kalit ilovada bo'lmasin, `.env` ham emas.

**6-bosqich — Yakun**
10 va 11-bo'lim ro'yxatlarini to'liq tekshir → `flutter build apk --release` → APK yo'lini va bajarilgan ishlar ro'yxatini `PROGRESS.md` ga yoz.

---

## 9. PROGRESS.md FORMATI

```markdown
# PROGRESS

## Holat
| Bosqich | Ekran/Modul | Fayl | Testlar | Analyze | Holat |
|---|---|---|---|---|---|

## Qarorlar
- [sana] Savol: ... → Qaror: ... → Sabab: ...

## APK
yo'l: ...
```

Uzun matn yozma — jadval va qisqa qatorlar yetarli.

---

## 10. YAKUNIY TEKSHIRUV RO'YXATI

Ishni tugadi deyishdan oldin hammasi ✅ bo'lsin:

- [ ] `flutter analyze` — 0 muammo (ikkala ilova + paket)
- [ ] `flutter test` — barchasi o'tdi
- [ ] `flutter build apk --release` — muvaffaqiyatli
- [ ] Barcha UI matnlari o'zbekcha va dc.html bilan bir xil
- [ ] Ekran fayllarida hardcode rang va `TextStyle(...)` yo'q — faqat token
- [ ] 17 ta User ekran + Seller ekranlari ishlaydi, navigatsiya uzilmaydi
- [ ] Tab bar spring animatsiyasi va depth-carousel prototipdagidek
- [ ] README/qo'shimcha hujjat yaratilmagan (faqat PROGRESS.md)

Grep bilan tekshir — hammasi bo'sh natija bersin:

```bash
grep -rn "5B21B6\|F59E0B\|Plus Jakarta\|MyHomePage\|TODO\|FIXME" --include=*.dart --include=*.yaml --include=*.xml .
grep -rn "MaterialPageRoute\|Curves.easeInOut\|Curves.linear" --include=*.dart .
grep -rn "withOpacity\|MaterialStateProperty" --include=*.dart .
grep -rln "TextStyle(" apps/*/lib/screens/
```

---

## 11. "INSON QO'LI" RO'YXATI (har ekran yopilishidan oldin)

Bu ro'yxat ilovaning AI qilgandek ko'rinmasligi uchun. Har ekranni yopishdan oldin o'zingga savol ber — javob "yo'q" bo'lsa, ekran tugamagan:

- [ ] Har `TextStyle` da `letterSpacing` **va** `height` bormi? (2.1)
- [ ] Har bosiladigan element bosilganda vizual javob beradimi? (`AnimatedScale`, ripple emas)
- [ ] Kerakli joyda haptika bormi, ortiqcha joyda yo'qmi? (2.2)
- [ ] Bu ekranga o'tish `PageRouteBuilder` orqalimi? `MaterialPageRoute` qolmadimi?
- [ ] Apparat "orqaga" tugmasi bu ekranda to'g'ri ishlaydimi?
- [ ] Uzun matn bilan sinaldimi? Overflow chizig'i chiqmadimi?
- [ ] Input bo'lsa: klaviatura maydonni berkitmaydimi?
- [ ] Pastdagi tab bar / FAB gesture-bar bilan ustma-ust tushmaydimi?
- [ ] Ekrandagi barcha matn dc.html'dan **copy-paste**mi? Bittasini ham o'zimdan yozmadimmi?
- [ ] Ro'yxat elementlari stagger bilan chiqadimi (35–40ms)?

Agar bu ekranda "hech nima jonli tuyulmaydi" desang — ekran tugamagan, qaytib ko'r.
