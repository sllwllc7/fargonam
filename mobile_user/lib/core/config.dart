/// Ilova konfiguratsiyasi.
/// Production'da HTTPS ishlatiladi, sertifikat pinning qo'shiladi.
class AppConfig {
  /// API manzili — environment'ga qarab o'zgartiriladi.
  /// Flutter build: --dart-define=API_URL=https://api.fargonam.uz
  /// Build: flutter run --dart-define=API_URL=https://api.fargonam.uz
  /// Yoki: flutter build apk --dart-define=API_URL=https://api.fargonam.uz
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://fargonam.duckdns.org', // VPS server (HTTPS)
  );

  /// Token saqlash kalitlari
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
