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

  /// Oq fondagi kiritish/tugma chegarasi (Filtr tugmasi, AI input, AI chip) —
  /// `#D5DDE9`, karta chegarasi (`border`)dan farqli, ammo shunga yaqin token.
  static const inputBorder = Color(0xFFD5DDE9);

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

  // mobile_user'ning bir nechta hali tuzatilmagan ekrani eski NOM bilan shu
  // yerga murojaat qiladi — qiymat eskirmagan, joriy tokenlarga ishora
  // qiladi (`AppColorsDark` kabi). 3-bosqichda ekranlar to'g'ridan-to'g'ri
  // yuqoridagi nomlarga o'tkaziladi va bu aliaslar o'chiriladi.
  static const bg = background;
  static const text = textPrimary;
  static const error = danger;
  static const accent = textPrimary;
  static const surfaceAlt = background;
  static const successSoft = successTint;
  static const dangerSoft = dangerTint;

  /// 3-bosqichda tegishli ekran o'qilganda dc.html'dan tasdiqlanadi.
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
  static const borderStrong = Color(0xFFE0DCD4);
  static const rating = Color(0xFFFFC120);
}
