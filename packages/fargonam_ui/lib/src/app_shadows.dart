import 'package:flutter/material.dart';

/// Soya tokenlari — HANDOFF.md "Shakl va soyalar" (Warm Violet, 2026-08-19).
class AppShadows {
  /// Karta: `0 1px 2px rgba(23,19,39,.04), 0 12px 26px -16px rgba(23,19,39,.08)`.
  static List<BoxShadow> get card => [
        const BoxShadow(color: Color(0x0A171327), blurRadius: 2, offset: Offset(0, 1)),
        const BoxShadow(color: Color(0x14171327), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -16),
      ];

  /// Asosiy tugma: `0 8px 20px rgba(91,33,182,.25)`.
  static List<BoxShadow> get primaryButton => [
        const BoxShadow(color: Color(0x405B21B6), blurRadius: 20, offset: Offset(0, 8)),
      ];

  /// Savat FAB / markaziy tab tugmasi / hero karta: `0 12px 28px rgba(91,33,182,.28)`.
  static List<BoxShadow> get fab => [
        const BoxShadow(color: Color(0x475B21B6), blurRadius: 28, offset: Offset(0, 12)),
      ];

  /// Moslik uchun eski nom — endi `card` bilan bir xil.
  static List<BoxShadow> get floating => card;
}
