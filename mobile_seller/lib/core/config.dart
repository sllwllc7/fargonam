/// Ilova konfiguratsiyasi.
/// Production'da HTTPS ishlatiladi.
class AppConfig {
  /// API manzili — build paytida o'zgartiriladi.
  /// Flutter build: --dart-define=API_URL=https://api.fargonam.uz
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://45.92.173.42', // VPS server
  );

  /// Token saqlash kalitlari
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
