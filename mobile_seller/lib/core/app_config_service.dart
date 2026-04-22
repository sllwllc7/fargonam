import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'config.dart';

class RemoteConfig {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minAppVersion;
  final String supportPhone;
  final String supportTelegram;

  const RemoteConfig({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.minAppVersion,
    required this.supportPhone,
    required this.supportTelegram,
  });

  static const RemoteConfig defaults = RemoteConfig(
    maintenanceMode: false,
    maintenanceMessage: '',
    minAppVersion: '1.0.0',
    supportPhone: '',
    supportTelegram: '',
  );

  factory RemoteConfig.fromJson(Map<String, dynamic> j) => RemoteConfig(
        maintenanceMode: j['maintenance_mode'] == 'true',
        maintenanceMessage: j['maintenance_message'] as String? ?? '',
        minAppVersion: j['min_app_version_seller'] as String? ?? '1.0.0',
        supportPhone: j['support_phone'] as String? ?? '',
        supportTelegram: j['support_telegram'] as String? ?? '',
      );
}

int compareVersions(String a, String b) {
  final pa = a.split('.').map(int.tryParse).toList();
  final pb = b.split('.').map(int.tryParse).toList();
  for (var i = 0; i < 3; i++) {
    final va = i < pa.length ? (pa[i] ?? 0) : 0;
    final vb = i < pb.length ? (pb[i] ?? 0) : 0;
    if (va < vb) return -1;
    if (va > vb) return 1;
  }
  return 0;
}

Future<RemoteConfig> fetchRemoteConfig() async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get('/app-config');
    return RemoteConfig.fromJson(res.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('RemoteConfig yuklashda xato: $e');
    return RemoteConfig.defaults;
  }
}

Future<bool> needsForceUpdate(String minVersion) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return compareVersions(info.version, minVersion) < 0;
  } catch (_) {
    return false;
  }
}
