import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

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
    final tok = await storage.read(key: 'access_token');
    if (tok == null || tok.isEmpty) return;
    await _loadMe();
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/auth/login', data: {'phone': phone, 'password': password});
      final token = res.data['access_token'] as String;
      await ref.read(secureStorageProvider).write(key: 'access_token', value: token);
      await _loadMe();
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.response?.data['detail']?.toString() ?? 'Tarmoq xatosi',
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
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
    await ref.read(secureStorageProvider).delete(key: 'access_token');
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
