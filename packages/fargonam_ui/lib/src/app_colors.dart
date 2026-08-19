import 'package:flutter/material.dart';

/// Fargonam dizayn tokenlari — `handoff/Fargonam User App v2.dc.html`
/// (md5 b3bc28ca50648663ea83630fb9de04ae) dan tasdiqlangan qiymatlar.
/// `mobile_user` va `mobile_seller` shu bitta manbadan foydalanadi.
class AppColors {
  static const background = Color(0xFFEEF1F6);
  static const surface = Color(0xFFFFFFFF);

  static const primary = Color(0xFF16294A);
  static const primaryDark = Color(0xFF0F1E38);
  static const primaryMid = Color(0xFF2A4A7F);
  static const primaryLight = Color(0xFFE3ECFA);

  static const tabBar = Color(0xFF0F1E33);

  static const success = Color(0xFF16A34A);
  static const successTint = Color(0xFFDCFCE7);
  static const danger = Color(0xFFDC2626);
  static const dangerTint = Color(0xFFFEE2E2);

  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF1C1C22);
  static const textMuted = Color(0xFF3F3F49);

  static const border = Color(0xFFE0E6EF);

  /// CTA tugma gradienti (savatga qo'shish, checkout va h.k.) — `#24406F → #12233F`.
  static const ctaStart = Color(0xFF24406F);
  static const ctaEnd = Color(0xFF12233F);
  static const ctaText = Color(0xFFEEF1F6);

  /// Tab bar bo'rtma va Savat FAB gradienti — `#2A4A7F → #16294A (55%) → #0F1E38`.
  static const bubbleStart = primaryMid;
  static const bubbleMid = primary;
  static const bubbleEnd = primaryDark;

  static const tabLabelActive = Color(0xFF6FA0E8);
  static const tabLabelInactive = Color(0xFF8DA2C0);
  static const tabIconActive = tabBar;
  static const tabIconInactive = border;

  /// Kategoriya ikonka fon/old plan juftliklari — dc.html `const T = [...]`.
  static const categoryTints = <List<Color>>[
    [Color(0xFFE3ECFA), Color(0xFF14243F)],
    [Color(0xFFE3ECFA), Color(0xFF16294A)],
    [Color(0xFFDCFCE7), Color(0xFF16A34A)],
    [Color(0xFFE5EEF9), Color(0xFF2F5FB3)],
    [Color(0xFFDDEAF8), Color(0xFF2F5FB3)],
    [Color(0xFFE7EDF6), Color(0xFF3A6EA5)],
  ];

  // ───────────────────────── LEGACY (mobile_seller) ─────────────────────────
  // mobile_seller hali eski "Warm Violet" qiymatlariga ko'plab ekranlarda
  // to'g'ridan-to'g'ri bog'langan (10-bo'lim, 4-bosqich shu ekranlarni
  // tuzatadi). Bu tokenlar shu bosqichgacha mobile_seller'ni vizual
  // o'zgarishsiz build qilib turish uchun saqlanadi — mobile_user ULARDAN
  // FOYDALANMAYDI.
  static const bg = Color(0xFFF8F7F3);
  static const text = Color(0xFF171327);
  static const error = danger;
  static const accent = Color(0xFFF59E0B);
  static const warning = Color(0xFFB45309);
  static const surfaceAlt = bg;
  static const sellerAccent = accent;
  static const sellerAccentSoft = Color(0xFFFDE9CC);
  static const successSoft = successTint;
  static const dangerSoft = dangerTint;
  static const warningSoft = Color(0xFFFEF3C7);
  static const borderStrong = Color(0xFFE0DCD4);

  /// LEGACY — dc.html'da tasdiqlanmagan, faqat eski kod moslik uchun.
  static const rating = Color(0xFFFFC120);
}

/// LEGACY — prototipda dark-mode yo'q (7-bo'lim). `ThemeData.dark`
/// referenslari buzilmasligi uchun `AppColors` bilan bir xil qiymatlar.
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
