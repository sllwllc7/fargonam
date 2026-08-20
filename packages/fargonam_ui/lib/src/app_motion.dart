import 'package:flutter/animation.dart';

/// Animatsiya konstantalari — dc.html'dan tasdiqlangan qiymatlar.
class AppMotion {
  /// Asosiy egri chiziq — dc.html'da `cubic-bezier(.2,.8,.2,1)`, 40 joyda.
  static const standard = Cubic(0.2, 0.8, 0.2, 1.0);

  /// Tab bo'rtmasi ko'tarilishi — `cubic-bezier(.3,1.6,.5,1)`, spring/overshoot.
  static const tabSpring = Cubic(0.3, 1.6, 0.5, 1.0);

  /// Ekran kirishi: 320ms, translateX(14px)→0 + fade.
  static const screenIn = Duration(milliseconds: 320);
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
  static const pressedDuration = Duration(milliseconds: 120);

  /// Tab bo'rtmasi: transform .5s spring, rang/border .25s ease.
  static const tabTransform = Duration(milliseconds: 500);
  static const tabColor = Duration(milliseconds: 250);

  /// Toast: pastdan 12px + fade, 2.4s ko'rinadi.
  static const toastIn = Duration(milliseconds: 300);
  // dc.html asl qiymati 2400ms edi — foydalanuvchi bu ekranda aniq
  // qisqartirishni so'radi (1.2-1.5s), shuning uchun bu bittasi dc.html'dan
  // ataylab og'ib ketadi.
  static const toastVisible = Duration(milliseconds: 1300);

  /// `standard`ning `Curves`-asosidagi muqobili — `Cubic` qabul qilmaydigan
  /// API'lar (masalan `TweenAnimationBuilder`ning ba'zi qurilishlari) uchun.
  static const screenInCurve = Curves.easeOutCubic;
}
