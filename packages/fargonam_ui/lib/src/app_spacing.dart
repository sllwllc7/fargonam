import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing shkalasi (4/8 tarmoq) — `docs/DESIGN.md` ("Layout & Spacing" bo'limi).
class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 24.w;
  static double get xxl => 32.w;
  static double get xxxl => 40.w;

  // Semantik nomlar (DESIGN.md spacing qoidalariga mos)
  static double get screenPadding => xl; // 24
  static double get cardGap => lg; // 16
  static double get sectionGap => xxl; // 32
  static double get cardPadding => md; // 12
}

/// Fixed balandliklar — HANDOFF.md prototipidagi piksel qiymatlar.
class AppSizes {
  static const topBar = 58.0;
  static const bottomNav = 84.0; // tab bar balandligi (dc.html)
  static const searchInput = 48.0;
  static const primaryButton = 54.0; // 52-54px
}
