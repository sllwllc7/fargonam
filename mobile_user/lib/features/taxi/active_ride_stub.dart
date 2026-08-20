import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 2026-08-20: Yandex MapKit vaqtincha o'chirilgani uchun `taxi_screen.dart`
/// butunlay kommentariyga o'ralgan (APK hajmi). `app_shell.dart` global
/// WebSocket'dan "ride_status" kelganda shu provider'ni invalidate qiladi —
/// bu minimal stub faqat o'sha chaqiruv kompilyatsiya bo'lishi uchun, taksi
/// o'chirilgan holda haqiqiy faol sayohat bo'lishi mumkin emas.
///
/// Taksi qaytarilganda: bu fayl o'chiriladi, `app_shell.dart`dagi import
/// asl `taxi_screen.dart`ga qaytariladi (PROGRESS.md "Taksi qaytarish").
final activeRideProvider = FutureProvider<Map<String, dynamic>?>((ref) async => null);
