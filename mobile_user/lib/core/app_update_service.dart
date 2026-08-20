import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config_service.dart' show compareVersions;
import 'config.dart';

/// `/app/version` javobi — yangi versiya mavjudligini bildiradi.
class AppUpdateInfo {
  final String version;
  final int build;
  final String apkUrl;
  final String notes;
  final bool force;

  const AppUpdateInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.notes,
    required this.force,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) => AppUpdateInfo(
        version: j['version'] as String,
        build: j['build'] as int,
        apkUrl: j['apk_url'] as String,
        notes: j['notes'] as String? ?? '',
        force: j['force'] as bool? ?? false,
      );
}

/// Serverdagi versiya joriy o'rnatilgan versiyadan yangimi tekshiradi.
/// Yangi bo'lmasa yoki so'rov muvaffaqiyatsiz bo'lsa — jim `null` qaytaradi.
Future<AppUpdateInfo?> checkForUpdate(String appId) async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get('/app/version', queryParameters: {'app': appId});
    final info = AppUpdateInfo.fromJson(res.data as Map<String, dynamic>);

    final current = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(current.buildNumber) ?? 0;
    final isNewer = compareVersions(current.version, info.version) < 0 ||
        (compareVersions(current.version, info.version) == 0 && info.build > currentBuild);
    return isNewer ? info : null;
  } catch (e) {
    debugPrint('Yangilanish tekshirishda xato: $e');
    return null;
  }
}
