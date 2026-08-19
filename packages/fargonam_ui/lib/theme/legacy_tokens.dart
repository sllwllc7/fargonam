// O'chiriladi: mobile_user'ning 2 ta shim fayli — 3-bosqich oxirida;
// mobile_seller (butun fayl) — 4-bosqichda. Sabab: ikkalasi hali eski
// nom/qiymatlarga bog'langan, `fargonam_ui.dart` esa endi faqat
// dc.html'dan tasdiqlangan joriy tokenlarni beradi.
//
// Bu fayl `fargonam_ui.dart` barrel'idan EKSPORT QILINMAYDI — chaqiruvchi
// fayllar shu yerdan to'g'ridan-to'g'ri import qiladi, shunda yangi kod bu
// qiymatlarni tasodifan ishlatib qolmaydi.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../fargonam_ui.dart';

// ═══════════════ mobile_seller — asl "Warm Violet" qiymatlar (o'zgarmas) ═══════════════
// mobile_seller ~14 faylda shu nomlarga to'g'ridan-to'g'ri bog'langan edi.
// Qiymatlar joriy (navy/Figtree) tokenlardan ATAYLAB farq qiladi — maqsad
// seller ekranlarini 4-bosqichgacha vizual o'zgarishsiz saqlash.

class LegacyColors {
  static const bg = Color(0xFFF8F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF6D28D9);
  static const primaryDark = Color(0xFF5B21B6);
  static const text = Color(0xFF171327);
  static const textPrimary = text;
  static const textSecondary = Color(0xFF77738A);
  static const textMuted = Color(0xFFA29EAF);
  static const border = Color(0xFFE8E5E0);
  static const accent = Color(0xFFF59E0B);
  static const sellerAccent = accent;
  static const sellerAccentSoft = Color(0xFFFDE9CC);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFDC2626);
  static const error = danger;
  static const surfaceAlt = bg;
}

class LegacyGradients {
  static const primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
  );
}

class LegacyShadows {
  /// Eslatma: joriy `AppShadows.fab` rgba(16,31,56,..) — bu esa asl
  /// rgba(91,33,182,..). Ataylab har xil, seller markaziy tugmasi uchun.
  static const fab = [
    BoxShadow(color: Color(0x475B21B6), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

class LegacySizes {
  static const bottomNav = 84.0;
}

class LegacyTextStyles {
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color color = LegacyColors.text,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle get h1 => _jakarta(size: 28, weight: FontWeight.w800, letterSpacing: -0.8);
  static TextStyle get h2 => _jakarta(size: 23, weight: FontWeight.w800, letterSpacing: -0.6);
  static TextStyle get title => _jakarta(size: 21, weight: FontWeight.w700, letterSpacing: -0.4);
  static TextStyle get sectionLabel =>
      _jakarta(size: 11.5, weight: FontWeight.w800, letterSpacing: 1.2, color: LegacyColors.textMuted);
  static TextStyle get cardTitle => _jakarta(size: 16.5, weight: FontWeight.w700, letterSpacing: -0.2);
  static TextStyle get cardTitleSm => _jakarta(size: 14, weight: FontWeight.w600, letterSpacing: -0.1);
  static TextStyle get body => _jakarta(size: 14, weight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => _jakarta(size: 14, weight: FontWeight.w500, height: 1.4);
  static TextStyle get price => _jakarta(size: 18, weight: FontWeight.w800, letterSpacing: -0.3);
  static TextStyle get caption =>
      _jakarta(size: 12.5, weight: FontWeight.w400, color: LegacyColors.textMuted, height: 1.4);
  static TextStyle get small => _jakarta(size: 11, weight: FontWeight.w700, color: LegacyColors.textSecondary);
}

// ═══════════════ mobile_user — eski NOM, joriy (to'g'ri) qiymatga ishora ═══════════════
// Qiymat eskirmagan — faqat 2 ta shim fayl (core/theme/app_colors.dart,
// core/theme/app_text_styles.dart) hali eski nomdan foydalanadi.

typedef AppTextStyles = AppTypography;

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

class AppColorsDark {
  static const primary = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceAlt = AppColors.surfaceAlt;
  static const border = AppColors.border;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const success = AppColors.success;
  static const rating = AppColors.rating;
  static const error = AppColors.danger;
}
