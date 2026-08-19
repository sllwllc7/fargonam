import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografiya tokenlari — HANDOFF.md "Tipografika". Yagona shrift oilasi:
/// Plus Jakarta Sans (avvalgi Manrope+Inter juftligi o'rniga).
class AppTextStyles {
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color color = AppColors.text,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size.sp,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Ekran sarlavhasi (katta) — masalan "Kategoriyalar", "Profil". 28px/w800.
  static TextStyle get h1 => _jakarta(size: 28, weight: FontWeight.w800, letterSpacing: -0.8);

  /// Ekran sarlavhasi (o'rta) — masalan "Savat", "Buyurtmalar". 23px/w800.
  static TextStyle get h2 => _jakarta(size: 23, weight: FontWeight.w800, letterSpacing: -0.6);

  /// Orqaga-tugmali sarlavha — kategoriya/mahsulot nomi. 21px/w700.
  static TextStyle get title => _jakarta(size: 21, weight: FontWeight.w700, letterSpacing: -0.4);

  /// Bo'lim yorlig'i — UPPERCASE, textMuted. Matn `.toUpperCase()` bilan beriladi.
  static TextStyle get sectionLabel => _jakarta(
        size: 11.5,
        weight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      );

  /// Karta sarlavhasi (katta) — mahsulot nomi PDP'da. 16.5px/w700.
  static TextStyle get cardTitle => _jakarta(size: 16.5, weight: FontWeight.w700, letterSpacing: -0.2);

  /// Karta sarlavhasi (kichik) — ro'yxat qatorlari. 14px/w600.
  static TextStyle get cardTitleSm => _jakarta(size: 14, weight: FontWeight.w600, letterSpacing: -0.1);

  /// Asosiy matn. 14px/w400/lineHeight 1.5.
  static TextStyle get body => _jakarta(size: 14, weight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyMedium => _jakarta(size: 14, weight: FontWeight.w500, height: 1.4);

  static TextStyle get bodyLg => _jakarta(size: 16, weight: FontWeight.w400, height: 1.5);

  /// Narx — w800, katta ekranlarda (PDP) kattaroq o'lchamga copyWith qilinadi.
  static TextStyle get price => _jakarta(size: 18, weight: FontWeight.w800, letterSpacing: -0.3);

  /// Kichik yozuvlar — vaqt, sub-matnlar. 12.5px/w400/textMuted.
  static TextStyle get caption => _jakarta(size: 12.5, weight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);

  /// Eng kichik — badge, vaqt belgisi. 11px/w700/textSecondary.
  static TextStyle get small => _jakarta(size: 11, weight: FontWeight.w700, color: AppColors.textSecondary);

  /// Tugma matni. 16px/w700.
  static TextStyle get button => _jakarta(size: 16, weight: FontWeight.w700, color: Colors.white);

  /// DESIGN.md moslik uchun eski nomlar.
  static TextStyle get labelSm => small;
}

/// Prototipda dark-mode yo'q — light bilan bir xil qiymatlar (moslik uchun saqlanadi).
class AppTextStylesDark {
  static TextStyle get h1 => AppTextStyles.h1;
  static TextStyle get h2 => AppTextStyles.h2;
  static TextStyle get title => AppTextStyles.title;
  static TextStyle get body => AppTextStyles.body;
  static TextStyle get bodyLg => AppTextStyles.bodyLg;
  static TextStyle get caption => AppTextStyles.caption;
  static TextStyle get labelSm => AppTextStyles.small;
  static TextStyle get price => AppTextStyles.price;
}
