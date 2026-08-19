import 'package:flutter/material.dart';

/// Soya tokenlari — dc.html'dan tasdiqlangan qiymatlar.
class AppShadows {
  /// Karta: `0 1px 2px rgba(23,19,39,.04), 0 12px 26px -16px rgba(23,19,39,.08)`.
  static const card = [
    BoxShadow(color: Color(0x0A171327), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14171327), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -16),
  ];

  /// CTA tugma: `0 8px 20px rgba(16,31,56,.28), inset 0 1px 0 rgba(255,255,255,.14)`.
  /// Eslatma: Flutter `BoxShadow` inset'ni qo'llab-quvvatlamaydi — faqat tashqi soya.
  static const cta = [
    BoxShadow(color: Color(0x47101F38), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Savat FAB: `0 10px 24px rgba(16,31,56,.3), inset 0 1px 0 rgba(255,255,255,.14)`.
  static const fab = [
    BoxShadow(color: Color(0x4D101F38), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Tab bar konteyneri: `0 14px 30px -10px rgba(23,19,39,.5)`.
  static const tabBar = [
    BoxShadow(color: Color(0x80171327), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -10),
  ];

  /// Faol tab bo'rtmasi: `0 8px 16px -4px rgba(16,31,56,.4)`.
  static const tabBubble = [
    BoxShadow(color: Color(0x66101F38), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -4),
  ];

  /// mobile_user eski ekranlarida ishlatiladi (cart/checkout/kit) — 3-bosqichda
  /// tegishli ekran o'qilganda dc.html'dan tasdiqlanadi yoki `cta` bilan almashadi.
  static const primaryButton = [
    BoxShadow(color: Color(0x405B21B6), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
