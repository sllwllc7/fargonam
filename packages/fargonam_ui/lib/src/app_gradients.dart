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

  /// Eski nom, `cta` bilan bir xil — mobile_user'ning bir nechta hali
  /// tuzatilmagan ekrani ishlatadi (3-bosqichda `cta`ga to'liq o'tkaziladi).
  static const primary = cta;
}
