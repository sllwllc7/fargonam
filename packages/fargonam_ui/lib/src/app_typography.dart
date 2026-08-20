import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografiya tokenlari — dc.html'dan tasdiqlangan qiymatlar (shrift: Figtree).
///
/// Har bir uslub `letterSpacing` **va** `height` bilan beriladi (5.3-bo'lim) —
/// dc.html'da aniq topilmagan joyda 5.3'dagi standart qiymat ishlatiladi:
/// sarlavha uchun `letterSpacing: -0.4`, tana matni uchun `height: 1.45`.
class AppTypography {
  static TextStyle _figtree({
    required double size,
    required FontWeight weight,
    required double letterSpacing,
    double? height,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.figtree(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  /// Ekran sarlavhasi (katta) — 28px/w800/-.8px.
  static TextStyle get h1 => _figtree(size: 28, weight: FontWeight.w800, letterSpacing: -0.8);

  /// Ekran sarlavhasi (o'rta) — 23px/w800/-.6px.
  static TextStyle get h2 => _figtree(size: 23, weight: FontWeight.w800, letterSpacing: -0.6);

  /// Ekran sarlavhasi (orqaga tugmasi yonida) — 21px/w700/-.4px. dc.html'da
  /// Kategoriya/Kit/Checkout/Kuzatish/Bildirishnomalar sarlavhalarida ishlatiladi.
  static TextStyle get title => _figtree(size: 21, weight: FontWeight.w700, letterSpacing: -0.4);

  /// Bo'lim yorlig'i — UPPERCASE, textSecondary. Matn `.toUpperCase()` bilan beriladi.
  // dc.html'da bu qator uchun line-height ko'rsatilmagan (brauzer
  // standarti ~1.2 ishlatiladi) — Figtree'ning o'z standart height'i
  // sezilarli kattaroq bo'lgani uchun height ko'rsatilmasa matn o'z
  // qatori ichida pastga siljib ko'rinadi ("Sinflar uchun tayyor
  // mahsulotlar" sarlavhasi pastlab ketgan bug — height:1.2 bilan tuzatildi).
  static TextStyle get sectionLabel => _figtree(
        size: 11.5,
        weight: FontWeight.w800,
        letterSpacing: 1.2,
        height: 1.2,
        color: AppColors.textSecondary,
      );

  /// Forma bo'lim yorlig'i (Rasmiylashtirish: "Yetkazib berish"/"To'lov"/
  /// "Buyurtma") — UPPERCASE, textMuted, `sectionLabel`dan farqli
  /// o'lcham/rang. Matn `.toUpperCase()` bilan beriladi.
  static TextStyle get formSectionLabel =>
      _figtree(size: 12, weight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.textMuted);

  /// Kichik UPPERCASE yorliq (masalan bosh sahifa salomlashuvi) — textMuted.
  /// Matn `.toUpperCase()` bilan beriladi.
  static TextStyle get eyebrow =>
      _figtree(size: 12, weight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textMuted);

  /// Brend nomi — faqat Bosh sahifa salomlashuvida. 27px/w800/-.9px.
  static TextStyle get brandTitle => _figtree(size: 27, weight: FontWeight.w800, letterSpacing: -0.9);

  /// Hero karta sarlavhasi (to'q fon ustida, oq matn). 21px/w800/-.3px.
  static TextStyle get heroTitle =>
      _figtree(size: 21, weight: FontWeight.w800, letterSpacing: -0.3, color: Colors.white);

  /// Hero karta tavsifi (to'q fon ustida, oq matn). 13px/w400/height1.45.
  static TextStyle get heroSubtitle =>
      _figtree(size: 13, weight: FontWeight.w400, letterSpacing: 0, height: 1.45, color: Colors.white);

  /// Oq pill tugma matni (hero CTA). 13.5px/w700.
  static TextStyle get pillButton => _figtree(size: 13.5, weight: FontWeight.w700, letterSpacing: 0);

  /// Ro'yxat qatori sarlavhasi (faol buyurtma, yetkazib berish va h.k). 14.5px/w700.
  static TextStyle get rowTitle => _figtree(size: 14.5, weight: FontWeight.w700, letterSpacing: 0);

  /// Yangiliklar/xabar kartasi sarlavhasi. 14.5px/w700/-.1px/height1.3.
  static TextStyle get newsTitle =>
      _figtree(size: 14.5, weight: FontWeight.w700, letterSpacing: -0.1, height: 1.3);

  /// Vaqt belgisi (masalan "Bugun", "3 kun oldin") — textSecondary. 11px/w400.
  static TextStyle get timeLabel =>
      _figtree(size: 11, weight: FontWeight.w400, letterSpacing: 0, color: AppColors.textSecondary);

  /// Kichik pill-badge matni. 11px/w700.
  static TextStyle get badgeText => _figtree(size: 11, weight: FontWeight.w700, letterSpacing: 0);

  /// Karta sarlavhasi (katta) — mahsulot nomi PDP'da. 16.5px/w700/-.2px.
  static TextStyle get cardTitle => _figtree(size: 16.5, weight: FontWeight.w700, letterSpacing: -0.2);

  /// Karta sarlavhasi (kichik) — ro'yxat qatorlari. 14px/w600/-.1px.
  static TextStyle get cardTitleSm => _figtree(size: 14, weight: FontWeight.w600, letterSpacing: -0.1);

  /// Asosiy matn. 14px/w400/-.1px/height 1.5.
  static TextStyle get body => _figtree(size: 14, weight: FontWeight.w400, letterSpacing: -0.1, height: 1.5);

  static TextStyle get bodyMedium =>
      _figtree(size: 14, weight: FontWeight.w500, letterSpacing: -0.1, height: 1.45);

  /// Katta tana matni — mahsulot tavsifi. 15px/w400/-.1px/height 1.5.
  static TextStyle get bodyLg => _figtree(size: 15, weight: FontWeight.w400, letterSpacing: -0.1, height: 1.5);

  /// Narx (jami, PDP) — 18px/w800/-.3px.
  static TextStyle get price => _figtree(size: 18, weight: FontWeight.w800, letterSpacing: -0.3);

  /// Narx (karta ichida) — 14.5px/w700/-.2px.
  static TextStyle get priceSm => _figtree(size: 14.5, weight: FontWeight.w700, letterSpacing: -0.2);

  /// Kichik yozuvlar — vaqt, sub-matnlar. 12.5px/w400/textMuted/height 1.4.
  static TextStyle get caption =>
      _figtree(size: 12.5, weight: FontWeight.w400, letterSpacing: -0.1, color: AppColors.textMuted, height: 1.4);

  /// Eng kichik — badge, vaqt belgisi, tab yorlig'i. 11px/w600/textSecondary.
  static TextStyle get small =>
      _figtree(size: 11, weight: FontWeight.w600, letterSpacing: -0.1, color: AppColors.textSecondary);

  /// Tugma matni. 16px/w700/-.2px.
  static TextStyle get button => _figtree(size: 16, weight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.ctaText);

  /// Eski nom, `small` bilan bir xil — faqat ishlatilmaydigan
  /// `marketplace_screen.dart`da qolgan, boshqa joyda kerak emas.
  static TextStyle get labelSm => small;
}
