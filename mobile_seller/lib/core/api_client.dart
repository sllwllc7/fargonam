import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

/// Tokenni xavfsiz saqlash uchun (Android EncryptedSharedPreferences).
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  ),
);

/// Bitta umumiy Dio instansi — har so'rovga avtomatik Bearer token qo'shadi.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
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
          final refreshed = await _tryRefreshToken(dio, storage);
          if (refreshed) {
            final opts = e.requestOptions;
            final newToken = await storage.read(key: AppConfig.accessTokenKey);
            opts.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
          await storage.delete(key: AppConfig.accessTokenKey);
          await storage.delete(key: AppConfig.refreshTokenKey);
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});

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
