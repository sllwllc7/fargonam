import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fargonam yagona rang palitrasi.
/// Asosiy ranglar: Midnight Indigo (#212842) + Vanilla Cream (#F0E7D5)
class AppColors {
  // ── Asosiy ranglar ──
  static const midnightIndigo = Color(0xFF212842);
  static const vanillaCream = Color(0xFFF0E7D5);

  // ── Marketplace UI (Stitch mockup, 2026-08-16 UX qarori) ──
  // Yangi nomlangan token'lar — pastdagi success/warning/error/divider'ga
  // TEGILMADI (taxi_screen.dart yolg'iz 37 marta ishlatadi, boshqa
  // unrelated ekranlar rangini o'zgartirib yubormaslik uchun).
  static const paperWhite = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8F9FA);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF46464D);
  static const outlineVariant = Color(0xFFC6C6CE);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const marketPrimaryText = Color(0xFF0C132C);
  static const statusSuccess = Color(0xFF27AE60);
  static const statusWarning = Color(0xFFF2994A);
  static const statusError = Color(0xFFBA1A1A);

  // ── Indigo oilasi (dark -> light) ──
  static const bgDeep = Color(0xFF181D33);      // eng qorong'i fon
  static const bg = Color(0xFF212842);           // asosiy fon
  static const surface = Color(0xFF2A3254);      // card fon
  static const surfaceHigh = Color(0xFF333D60);  // ko'tarilgan element
  static const surfaceBright = Color(0xFF3D476B); // hover/active
  static const divider = Color(0xFF3A4468);

  // ── Vanilla oilasi (light -> dark) ──
  static const cream = Color(0xFFF0E7D5);        // asosiy aksent
  static const creamDim = Color(0xFFD4CBBA);     // pasaytirilgan aksent
  static const creamSoft = Color(0xFFBEB5A5);    // muted aksent

  // ── Matn ranglari ──
  static const textPrimary = Color(0xFFEDE9F5);  // asosiy matn (indigo ustida)
  static const textSecondary = Color(0xFF9A96A8); // ikkilamchi matn
  static const textMuted = Color(0xFF6E6B7A);    // muted/hint matn

  // ── Funksional ranglar (uyg'un) ──
  static const success = Color(0xFF5CB07A);       // yashil (muvaffaqiyat)
  static const successSoft = Color(0xFF1E3A2A);   // yashil fon
  static const error = Color(0xFFD96B6B);          // qizil (xato)
  static const errorSoft = Color(0xFF3D1F1F);      // qizil fon
  static const info = Color(0xFF6B8FBF);           // ko'k (ma'lumot)
  static const infoSoft = Color(0xFF1F2A3D);       // ko'k fon
  static const warning = Color(0xFFD4A94B);        // sariq (ogohlantirish)
  static const warningSoft = Color(0xFF3D351F);    // sariq fon
}

/// Fargonam ilova temalari — dark-first dizayn.
class AppTheme {
  // Eski alias'lar (asta-sekin olib tashlanadi)
  static const Color primary = AppColors.vanillaCream;
  static const Color secondary = AppColors.success;
  static const Color accent = AppColors.error;
  static const Color dark = AppColors.midnightIndigo;

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
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.cream,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceHigh,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.cream, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream);
            }
            return const TextStyle(
                fontSize: 11, color: AppColors.textMuted);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.cream, size: 24);
            }
            return const IconThemeData(color: AppColors.textMuted, size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceBright,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.cream,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(
              color: AppColors.cream,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorSchemeSeed: AppColors.midnightIndigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.midnightIndigo,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.midnightIndigo,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5E1DA), width: 0.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.midnightIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.midnightIndigo,
            side: const BorderSide(color: Color(0xFFE5E1DA)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF9A96A8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E1DA), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.midnightIndigo, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.midnightIndigo.withValues(alpha: 0.08),
          elevation: 0,
          height: 65,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midnightIndigo);
            }
            return const TextStyle(
                fontSize: 11, color: Color(0xFF9A96A8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.midnightIndigo, size: 24);
            }
            return const IconThemeData(color: Color(0xFF9A96A8), size: 24);
          }),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE5E1DA)),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.midnightIndigo,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.midnightIndigo,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1A1A2E)),
          bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
          bodySmall: TextStyle(color: Color(0xFF6E6B7A)),
          titleLarge: TextStyle(
              color: AppColors.midnightIndigo,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
        ),
      );
}

/// Bo'shliq shkalasi — Stitch mockup (2026-08-16 UX qarori).
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

/// Radius shkalasi — Stitch mockup (2026-08-16 UX qarori).
class AppRadius {
  static const sm = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const full = 9999.0;
}

/// Fixed balandliklar — Stitch mockup (2026-08-16 UX qarori).
class AppSizes {
  static const topBar = 64.0;
  static const bottomNav = 72.0;
  static const searchInput = 48.0;
  static const primaryButton = 56.0;
}

/// Marketplace UI shrift shkalasi — Inter, Stitch mockup (2026-08-16 UX
/// qarori). Rang shu yerda belgilanmaydi — chaqiruvchi `.copyWith(color:)`
/// bilan kontekstga mos rang qo'shadi.
class AppTypography {
  static TextStyle get headlineLgMobile => GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 24,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get priceDisplay => GoogleFonts.inter(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
      );
}
