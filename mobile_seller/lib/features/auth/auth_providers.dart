import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';

/// Joriy foydalanuvchi (UserOut). null = login qilinmagan.
class CurrentUser {
  final int id;
  final String phone;
  final String? fullName;
  final String role;
  CurrentUser({required this.id, required this.phone, required this.fullName, required this.role});

  factory CurrentUser.fromJson(Map<String, dynamic> j) => CurrentUser(
        id: j['id'] as int,
        phone: j['phone'] as String,
        fullName: j['full_name'] as String?,
        role: j['role'] as String,
      );
}

class AuthState {
  final bool loading;
  final CurrentUser? user;
  final String? error;
  const AuthState({this.loading = false, this.user, this.error});

  AuthState copyWith({bool? loading, CurrentUser? user, String? error, bool clearUser = false}) =>
      AuthState(
        loading: loading ?? this.loading,
        user: clearUser ? null : (user ?? this.user),
        error: error,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> tryAutoLogin() async {
    final storage = ref.read(secureStorageProvider);
    final tok = await storage.read(key: AppConfig.accessTokenKey);
    if (tok == null || tok.isEmpty) return;
    await _loadMe();
  }

  /// Tokenlarni xavfsiz saqlash.
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AppConfig.accessTokenKey, value: data['access_token'] as String);
    if (data['refresh_token'] != null) {
      await storage.write(key: AppConfig.refreshTokenKey, value: data['refresh_token'] as String);
    }
  }

  /// Telefon raqamga OTP yuborish. is_new_user — yangi foydalanuvchimi.
  Future<bool?> sendOtp(String phone) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(dioProvider).post('/auth/send-otp', data: {'phone': phone});
      state = state.copyWith(loading: false);
      return res.data['is_new_user'] as bool?;
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.response?.data['detail']?.toString() ?? 'Tarmoq xatosi',
      );
      return null;
    }
  }

  /// OTP tasdiqlash — kirish yoki ro'yxatdan o'tish.
  Future<void> verifyOtp(String phone, String otp, {String? fullName, String role = 'seller'}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(dioProvider).post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
        'role': role,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      });
      await _saveTokens(res.data as Map<String, dynamic>);
      await _loadMe();
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.response?.data['detail']?.toString() ?? 'Tarmoq xatosi',
      );
    }
  }

  Future<void> _loadMe() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/auth/me');
      final user = CurrentUser.fromJson(res.data as Map<String, dynamic>);
      state = state.copyWith(loading: false, user: user, error: null);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: AppConfig.accessTokenKey);
    await storage.delete(key: AppConfig.refreshTokenKey);
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
