import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/push_service.dart';

/// Server javob bermagan (ulanish darajasidagi) xatoda "Tarmoq xatosi"
/// o'rniga qaysi manzilga, qanday xato bilan yiqilganini ko'rsatadi —
/// aks holda sabab (noto'g'ri URL, DNS, timeout, sertifikat) aniqlab
/// bo'lmaydi. `e.response` bor bo'lsa (server javob berdi, faqat xato
/// status) — bu funksiya chaqirilmaydi, `detail` ishlatiladi.
String describeConnectionError(DioException e) {
  final url = e.requestOptions.uri.toString();
  final typeLabel = switch (e.type) {
    DioExceptionType.connectionTimeout => 'ulanish vaqti tugadi',
    DioExceptionType.sendTimeout => 'so\'rov yuborish vaqti tugadi',
    DioExceptionType.receiveTimeout => 'javob kutish vaqti tugadi',
    DioExceptionType.badCertificate => 'SSL sertifikat xato',
    DioExceptionType.connectionError => 'ulanib bo\'lmadi',
    DioExceptionType.cancel => 'bekor qilindi',
    _ => 'noma\'lum xato',
  };
  return 'Tarmoq xatosi: $typeLabel\n$url\n${e.message ?? e.error ?? ''}';
}

class CurrentUser {
  final int id;
  final String? phone;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  CurrentUser({required this.id, this.phone, this.fullName, required this.role, this.avatarUrl});
  factory CurrentUser.fromJson(Map<String, dynamic> j) => CurrentUser(
        id: j['id'] as int,
        phone: j['phone'] as String?,
        fullName: j['full_name'] as String?,
        role: j['role'] as String,
        avatarUrl: j['avatar_url'] as String?,
      );
}

class TelegramSession {
  final String sessionId;
  final String botUrl;
  const TelegramSession({required this.sessionId, required this.botUrl});
}

class AuthState {
  final bool loading;
  final CurrentUser? user;
  final String? error;
  const AuthState({this.loading = false, this.user, this.error});
  AuthState copyWith({bool? loading, CurrentUser? user, String? error}) =>
      AuthState(loading: loading ?? this.loading, user: user ?? this.user, error: error);
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> tryAutoLogin() async {
    final storage = ref.read(secureStorageProvider);
    String? tok;
    try {
      tok = await storage.read(key: AppConfig.accessTokenKey);
    } catch (_) {
      // Shifrlash kaliti buzilgan — eski ma'lumotlarni tozalash
      await storage.deleteAll();
      return;
    }
    if (tok == null || tok.isEmpty) return;
    await _loadMe();
  }

  /// Login va register'dan qaytgan tokenlarni xavfsiz saqlash.
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AppConfig.accessTokenKey, value: data['access_token'] as String);
    if (data['refresh_token'] != null) {
      await storage.write(key: AppConfig.refreshTokenKey, value: data['refresh_token'] as String);
    }
  }

  /// Telegram login sessiyasini boshlaydi — bot havolasini qaytaradi.
  Future<TelegramSession?> startTelegramLogin() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(dioProvider).post('/auth/telegram/session');
      final data = res.data as Map<String, dynamic>;
      state = state.copyWith(loading: false);
      return TelegramSession(
        sessionId: data['session_id'] as String,
        botUrl: data['bot_url'] as String,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.response?.data['detail']?.toString() ?? describeConnectionError(e));
      return null;
    }
  }

  /// Sessiya holatini bir marta tekshiradi.
  /// true = tasdiqlangan va login qilindi, false = hali kutilmoqda, null = sessiya tugagan/xato.
  Future<bool?> pollTelegramSession(String sessionId) async {
    try {
      final res = await ref.read(dioProvider).get('/auth/telegram/session/$sessionId');
      final data = res.data as Map<String, dynamic>;
      if (data['status'] == 'confirmed') {
        await _saveTokens(data);
        await _loadMe();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 410) return null;
      return false;
    }
  }

  /// Profilga telefon raqam qo'shish (Telegram orqali kirgan foydalanuvchi uchun).
  Future<bool> addPhone(String phone) async {
    try {
      await ref.read(dioProvider).post('/auth/me/phone', data: {'phone': phone});
      await _loadMe();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: e.response?.data['detail']?.toString() ?? describeConnectionError(e));
      return false;
    }
  }

  /// Profil ma'lumotini (masalan avatar) yangilagandan keyin qayta yuklash.
  Future<void> refreshMe() => _loadMe();

  Future<void> _loadMe() async {
    try {
      final res = await ref.read(dioProvider).get('/auth/me');
      state = state.copyWith(loading: false, user: CurrentUser.fromJson(res.data as Map<String, dynamic>), error: null);
      // Login muvaffaqiyatli — push notification'ni boshlash
      ref.read(pushServiceProvider).init();
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.response?.data['detail']?.toString() ?? describeConnectionError(e));
    }
  }

  Future<void> logout() async {
    // Push tokenni o'chirish
    try { await ref.read(pushServiceProvider).unregister(); } catch (_) {}
    final storage = ref.read(secureStorageProvider);
    // Refresh tokenni serverda ham bekor qilish (boshqa qurilmada o'g'irlansa ishlamasin)
    try {
      final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(dioProvider).post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } catch (_) {}
    await storage.delete(key: AppConfig.accessTokenKey);
    await storage.delete(key: AppConfig.refreshTokenKey);
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
