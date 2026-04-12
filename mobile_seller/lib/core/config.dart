/// Ilova konfiguratsiyasi.
/// Production'da HTTPS ishlatiladi.
class AppConfig {
  /// API manzili — build paytida o'zgartiriladi.
  /// Flutter build: --dart-define=API_URL=https://api.fargonam.uz
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.240:8000', // Local network
  );

  /// Token saqlash kalitlari
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
