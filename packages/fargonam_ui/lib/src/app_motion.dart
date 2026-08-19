import 'package:flutter/material.dart';

/// Animatsiya konstantalari — HANDOFF.md "Animatsiyalar" bo'limi.
class AppMotion {
  /// Ekran kirishi: 320ms, translateX(14px)→0 + fade.
  static const screenIn = Duration(milliseconds: 320);
  static const screenInCurve = Curves.easeOutCubic; // cubic-bezier(.2,.8,.2,1)
  static const screenInOffset = 14.0;

  /// Ro'yxat elementlari: fadeUp(10px), stagger 35-40ms har biri orasida.
  static const fadeUp = Duration(milliseconds: 350);
  static const fadeUpOffset = 10.0;
  static const staggerStep = Duration(milliseconds: 38);

  /// Badge/FAB paydo bo'lishi: scale .6→1.15→1.
  static const pop = Duration(milliseconds: 350);

  /// Bosilganda: scale(.92-.98).
  static const pressedScale = 0.95;
  static const pressedScaleSmall = 0.92;

  /// Toast: pastdan 12px + fade, 2.4s ko'rinadi.
  static const toastIn = Duration(milliseconds: 300);
  static const toastVisible = Duration(milliseconds: 2400);
}
