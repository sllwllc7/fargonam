import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient tokenlari — dc.html'dan tasdiqlangan qiymatlar.
class AppGradients {
  /// CTA tugma (savatga qo'shish, checkout, kuzatish, AI yuborish) — 180°.
  static const cta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.ctaStart, AppColors.ctaEnd],
  );

  /// Savat FAB / faol tab bo'rtmasi — 180°, `#16294A` 55%da.
  static const bubble = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bubbleStart, AppColors.bubbleMid, AppColors.bubbleEnd],
    stops: [0.0, 0.55, 1.0],
  );

  /// Faol tab bo'rtmasi (2 to'xtash — dc.html `tabs` massivida shunday).
  static const tabBubble = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bubbleStart, AppColors.bubbleMid],
  );

  // LEGACY (mobile_seller, 4-bosqichgacha) — app_colors.dart'dagi izohga qarang.
  static const primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
  );
}
