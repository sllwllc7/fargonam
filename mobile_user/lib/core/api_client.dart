import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';
import 'navigator_key.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // FIX: encryptedSharedPreferences olib tashlandi (v11+ da deprecated,
      // shifrlash endi avtomatik custom ciphers orqali amalga oshiriladi)
      resetOnError: true,
    ),
  ),
);

// Bir vaqtda bir nechta 401 kelganda faqat bitta refresh yuboriladi.
bool _isRefreshing = false;
Completer<bool>? _refreshCompleter;

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30), // FIX: fayl yuklash uchun
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: AppConfig.accessTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // 401 bo'lsa — refresh token bilan yangilashga urinish
        if (e.response?.statusCode == 401) {
          bool refreshed;

          if (_isRefreshing) {
            // Boshqa refresh bajarilmoqda — tugashini kutish (double request oldini olish)
            refreshed = await _refreshCompleter!.future;
          } else {
            _isRefreshing = true;
            _refreshCompleter = Completer<bool>();
            final result = await _tryRefreshToken(dio, storage);
            _refreshCompleter!.complete(result);
            _isRefreshing = false;
            _refreshCompleter = null;
            refreshed = result;
          }

          if (refreshed) {
            // Asl so'rovni qayta yuborish
            final opts = e.requestOptions;
            final newToken = await storage.read(key: AppConfig.accessTokenKey);
            opts.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
          // Refresh ham muvaffaqiyatsiz — tokenlarni tozalash va login'ga qaytarish
          await storage.delete(key: AppConfig.accessTokenKey);
          await storage.delete(key: AppConfig.refreshTokenKey);
          _navigateToLogin();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});

/// Token muddati tugaganda login sahifasiga yo'naltirish.
void _navigateToLogin() {
  onTokenExpired?.call();
}

/// Refresh token orqali yangi access token olish.
Future<bool> _tryRefreshToken(
  Dio dio,
  FlutterSecureStorage storage,
) async {
  final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);
  if (refreshToken == null || refreshToken.isEmpty) return false;

  try {
    final response = await Dio(
      BaseOptions(baseUrl: AppConfig.apiBaseUrl),
    ).post('/auth/refresh', data: {'refresh_token': refreshToken});

    if (response.statusCode == 200) {
      final data = response.data;
      await storage.write(
        key: AppConfig.accessTokenKey,
        value: data['access_token'],
      );
      await storage.write(
        key: AppConfig.refreshTokenKey,
        value: data['refresh_token'],
      );
      return true;
    }
  } catch (_) {}
  return false;
}
