import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient tokenlari — HANDOFF.md "primary" (#6D28D9 → #5B21B6, 180deg).
class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primary, AppColors.primaryDark],
  );
}
