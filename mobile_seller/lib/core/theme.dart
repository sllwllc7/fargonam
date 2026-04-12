import 'package:flutter/material.dart';

/// Fargonam Biznes — yagona rang palitrasi
class AppColors {
  // ── Asosiy ranglar ──
  static const midnightIndigo = Color(0xFF212842);
  static const vanillaCream = Color(0xFFF0E7D5);

  // ── Indigo oilasi ──
  static const bgDeep = Color(0xFF181D33);
  static const bg = Color(0xFF1A1D2E);
  static const surface = Color(0xFF232842);
  static const surfaceHigh = Color(0xFF2D334E);
  static const surfaceBright = Color(0xFF3D476B);
  static const divider = Color(0xFF3A4468);

  // ── Vanilla oilasi ──
  static const cream = Color(0xFFF0E7D5);
  static const creamDim = Color(0xFFD4CBBA);

  // ── Matn ──
  static const textPrimary = Color(0xFFEDE9F5);
  static const textSecondary = Color(0xFF9A96A8);
  static const textMuted = Color(0xFF6E6B7A);

  // ── Funksional ──
  static const success = Color(0xFF22C55E);
  static const successSoft = Color(0xFF1E3A2A);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0xFF3D1F1F);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFF1F2A3D);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFF3D351F);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorSchemeSeed: AppColors.midnightIndigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.cream,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.cream,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.midnightIndigo,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.cream,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceHigh,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cream, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.cream.withValues(alpha: 0.12),
          elevation: 0,
          height: 65,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream);
            }
            return const TextStyle(
                fontSize: 11, color: AppColors.textMuted);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: AppColors.cream, size: 24);
            }
            return const IconThemeData(
                color: AppColors.textMuted, size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceBright,
          contentTextStyle:
              const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.cream,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
        ),
      );
}
