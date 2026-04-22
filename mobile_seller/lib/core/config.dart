/// Ilova konfiguratsiyasi.
/// Production'da HTTPS ishlatiladi.
class AppConfig {
  /// API manzili — build paytida o'zgartiriladi.
  /// Flutter build: --dart-define=API_URL=https://api.fargonam.uz
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://fargonam.duckdns.org', // VPS server (HTTPS)
  );

  /// Token saqlash kalitlari
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
