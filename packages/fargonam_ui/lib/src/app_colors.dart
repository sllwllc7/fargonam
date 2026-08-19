import 'package:flutter/material.dart';

/// Marketplace UI dizayn tokenlari — "Warm Violet" (HANDOFF.md, 2026-08-19
/// qayta ko'rilgan versiya — krem fon, oq kartalar, binafsha CTA, apelsin aksent).
///
/// `Fargonam User App v2.dc.html` prototipidan olingan qiymatlar. Ikkala ilova
/// (`mobile_user`, `mobile_seller`) shu bitta manbadan foydalanadi.
class AppColors {
  static const bg = Color(0xFFF8F7F3); // iliq krem — ekran foni
  static const surface = Color(0xFFFFFFFF); // kartalar, tab bar
  static const primary = Color(0xFF6D28D9); // gradient boshi — asosiy tugmalar, FAB
  static const primaryDark = Color(0xFF5B21B6); // gradient oxiri / solid CTA / brend
  static const text = Color(0xFF171327); // asosiy matn
  static const textSecondary = Color(0xFF77738A); // ikkilamchi matn
  static const textMuted = Color(0xFFA29EAF); // placeholder, vaqt, badge
  static const border = Color(0xFFE8E5E0); // karta chegaralari (1px, solid)
  static const borderStrong = Color(0xFFE0DCD4); // outlined pill/chip/input chegarasi
  static const accent = Color(0xFFF59E0B); // apelsin — savat FAB, badge, "+" tugma
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);

  /// Seller App'ga xos — faqat QO'SHISH/TAHRIRLASH (CRUD) amallari uchun.
  /// Endi asosiy `accent` (apelsin) bilan bir xil — HANDOFF'ning yangilangan
  /// versiyasida apelsin butun ilova uchun rasmiy aksent bo'ldi.
  static const sellerAccent = accent;
  static const sellerAccentSoft = Color(0xFFFDE9CC);

  // Eski nomlar bilan moslik (theme.dart / boshqa fayllar shu tokenlarni kutadi)
  static const background = bg;
  static const surfaceAlt = bg; // dc.html: input/bottom-fade foni ekran foni bilan bir xil
  static const textPrimary = text;
  static const error = danger;
  static const rating = Color(0xFFFFC120);
  static const primaryLight = Color(0xFFEDE9FE);

  /// Kategoriya ikonka fonlari — HANDOFF.md T[] massivi (tint, foreground juftlik).
  static const categoryTints = <List<Color>>[
    [Color(0xFFEDE9FE), Color(0xFF5B21B6)],
    [Color(0xFFFEF3C7), Color(0xFFB45309)],
    [Color(0xFFDCFCE7), Color(0xFF16A34A)],
    [Color(0xFFFFE8D9), Color(0xFFC2571B)],
    [Color(0xFFE0F2FE), Color(0xFF0369A1)],
    [Color(0xFFFCE7F3), Color(0xFFBE3D7F)],
  ];
}

/// Prototipda dark-mode yo'q — "Tungi rejim" Sozlamalar'da "Tez orada" sifatida
/// ko'rsatiladi. Shu klass faqat mavjud `ThemeData.dark` referenslari buzilmasligi
/// uchun light bilan bir xil qiymatlarni saqlaydi.
class AppColorsDark {
  static const primary = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const background = AppColors.bg;
  static const surface = AppColors.surface;
  static const surfaceAlt = AppColors.surfaceAlt;
  static const border = AppColors.border;
  static const textPrimary = AppColors.text;
  static const textSecondary = AppColors.textSecondary;
  static const success = AppColors.success;
  static const rating = AppColors.rating;
  static const error = AppColors.danger;
}
