import 'package:flutter/material.dart';

/// Global navigator key — push notification va token expiry navigatsiyasi uchun.
final navigatorKey = GlobalKey<NavigatorState>();

/// Token muddati tugaganda chaqiriladigan callback.
/// Circular import'dan qochish uchun main.dart tomonidan o'rnatiladi.
VoidCallback? onTokenExpired;
