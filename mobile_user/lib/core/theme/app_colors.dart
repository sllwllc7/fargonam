import 'package:flutter/material.dart';

/// Marketplace UI dizayn tokenlari — LIGHT rejim.
///
/// 2026-08-16 UX qarori bilan Kutuku-Violet (#514EB7) palitrasi butunlay
/// bekor qilindi — bu fayl endi `core/theme.dart`dagi Midnight-Indigo
/// palitrasidan qiymat oladi (fayl/klass nomi atayin saqlangan — uni
/// import qiluvchi 9 ta widget/tema fayli o'zgarishsiz qoladi, faqat
/// ko'rgan rangi almashadi).
class AppColors {
  static const primary = Color(0xFF212842); // Midnight Indigo
  static const primaryLight = Color(0xFFDCDEE6);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFEDEEEF);
  static const surfaceAlt = Color(0xFFE1E3E4);
  static const border = Color(0xFFC6C6CE);
  static const textPrimary = Color(0xFF191C1D);
  static const textSecondary = Color(0xFF46464D);
  static const success = Color(0xFF27AE60);
  static const rating = Color(0xFFFFC120); // brend hue'ga bog'liq emas — yulduz reytingi o'zgarmadi
  static const error = Color(0xFFBA1A1A);
}

/// DARK rejim uchun moslashtirilgan variant.
///
/// `core/theme.dart`ning dark-first Indigo palitrasidan (bg=Midnight Indigo,
/// aksent=Vanilla Cream) qarzga olingan — o'sha fayl bilan bir xil his
/// beradi, ikkalasi endi bitta manba (Indigo) atrofida uyg'unlashgan.
class AppColorsDark {
  static const primary = Color(0xFFF0E7D5); // Vanilla Cream — dark fonda aksent
  static const primaryLight = Color(0xFF333D60);
  static const background = Color(0xFF181D33);
  static const surface = Color(0xFF2A3254);
  static const surfaceAlt = Color(0xFF333D60);
  static const border = Color(0xFF3A4468);
  static const textPrimary = Color(0xFFEDE9F5);
  static const textSecondary = Color(0xFF9A96A8);
  static const success = Color(0xFF27AE60);
  static const rating = Color(0xFFFFC120);
  static const error = Color(0xFFD96B6B); // och qizil — indigo fonda kontrastliroq
}
