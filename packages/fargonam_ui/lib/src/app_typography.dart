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

  /// Ekran sarlavhasi (katta) — 28px/w800/-.9px.
  static TextStyle get h1 => _figtree(size: 28, weight: FontWeight.w800, letterSpacing: -0.9);

  /// Ekran sarlavhasi (o'rta) — 23px/w800/-.6px.
  static TextStyle get h2 => _figtree(size: 23, weight: FontWeight.w800, letterSpacing: -0.6);

  /// Bo'lim/karta sarlavhasi — 21px/w700/-.3px (masalan hero "Market").
  static TextStyle get title => _figtree(size: 21, weight: FontWeight.w700, letterSpacing: -0.3);

  /// Bo'lim yorlig'i — UPPERCASE, textMuted. Matn `.toUpperCase()` bilan beriladi.
  static TextStyle get sectionLabel => _figtree(
        size: 11.5,
        weight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      );

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

  /// Narx — w800.
  static TextStyle get price => _figtree(size: 18, weight: FontWeight.w800, letterSpacing: -0.4);

  static TextStyle get priceSm => _figtree(size: 14.5, weight: FontWeight.w800, letterSpacing: -0.2);

  /// Kichik yozuvlar — vaqt, sub-matnlar. 12.5px/w400/textMuted/height 1.4.
  static TextStyle get caption =>
      _figtree(size: 12.5, weight: FontWeight.w400, letterSpacing: -0.1, color: AppColors.textMuted, height: 1.4);

  /// Eng kichik — badge, vaqt belgisi, tab yorlig'i. 11px/w600/textSecondary.
  static TextStyle get small =>
      _figtree(size: 11, weight: FontWeight.w600, letterSpacing: -0.1, color: AppColors.textSecondary);

  /// Tugma matni. 16px/w700/-.2px.
  static TextStyle get button => _figtree(size: 16, weight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.ctaText);

  /// LEGACY — eski nom, `small` bilan bir xil.
  static TextStyle get labelSm => small;
}

/// LEGACY (mobile_seller, 4-bosqichgacha) — eski nom bilan bog'langan
/// ekranlar buzilmasligi uchun. mobile_user `AppTypography`dan foydalanadi.
typedef AppTextStyles = AppTypography;

/// LEGACY — prototipda dark-mode yo'q (7-bo'lim), `AppTypography` bilan bir xil.
class AppTextStylesDark {
  static TextStyle get h1 => AppTypography.h1;
  static TextStyle get h2 => AppTypography.h2;
  static TextStyle get title => AppTypography.title;
  static TextStyle get body => AppTypography.body;
  static TextStyle get bodyLg => AppTypography.bodyLg;
  static TextStyle get caption => AppTypography.caption;
  static TextStyle get labelSm => AppTypography.small;
  static TextStyle get price => AppTypography.price;
}
