import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/push_service.dart';

class CurrentUser {
  final int id;
  final String phone;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  CurrentUser({required this.id, required this.phone, this.fullName, required this.role, this.avatarUrl});
  factory CurrentUser.fromJson(Map<String, dynamic> j) => CurrentUser(
        id: j['id'] as int,
        phone: j['phone'] as String,
        fullName: j['full_name'] as String?,
        role: j['role'] as String,
        avatarUrl: j['avatar_url'] as String?,
      );
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
    final tok = await storage.read(key: AppConfig.accessTokenKey);
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

  Future<void> login(String phone, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(dioProvider).post('/auth/login', data: {'phone': phone, 'password': password});
      await _saveTokens(res.data as Map<String, dynamic>);
      await _loadMe();
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.response?.data['detail']?.toString() ?? 'Tarmoq xatosi');
    }
  }

  Future<void> register(String phone, String password, String? fullName) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await ref.read(dioProvider).post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'role': 'buyer',
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      });
      await _saveTokens(res.data as Map<String, dynamic>);
      await _loadMe();
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.response?.data['detail']?.toString() ?? 'Tarmoq xatosi');
    }
  }

  Future<void> _loadMe() async {
    try {
      final res = await ref.read(dioProvider).get('/auth/me');
      state = state.copyWith(loading: false, user: CurrentUser.fromJson(res.data as Map<String, dynamic>), error: null);
      // Login muvaffaqiyatli — push notification'ni boshlash
      ref.read(pushServiceProvider).init();
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> logout() async {
    // Push tokenni o'chirish
    try { await ref.read(pushServiceProvider).unregister(); } catch (_) {}
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: AppConfig.accessTokenKey);
    await storage.delete(key: AppConfig.refreshTokenKey);
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
