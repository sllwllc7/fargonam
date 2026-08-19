import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// dc.html tokenlaridan yig'ilgan `ThemeData`. Tab bar Material
/// `NavigationBar` orqali emas — `FloatingTabBar` widget orqali chiziladi
/// (6-bo'lim: Material 3 default'lari taqiqlangan), shuning uchun bu yerda
/// `navigationBarTheme` yo'q.
///
/// Prototipda dark-mode yo'q — `darkTheme` `lightTheme` bilan bir xil.
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: AppColors.background,
          error: AppColors.danger,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: AppTypography.title,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ctaStart,
            foregroundColor: AppColors.ctaText,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            textStyle: AppTypography.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primaryDark,
          contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
        textTheme: TextTheme(
          headlineLarge: AppTypography.h1,
          headlineMedium: AppTypography.h2,
          titleLarge: AppTypography.title,
          bodyLarge: AppTypography.body,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
        ),
      );

  static ThemeData get darkTheme => lightTheme;
}
