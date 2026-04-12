import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// OSRM (Open Source Routing Machine) — bepul marshrut API
/// Ko'cha bo'ylab haqiqiy yo'l chizadi
class RouteService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://router.project-osrm.org',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Ikki nuqta orasidagi marshrut
  /// Qaytaradi: polyline nuqtalari + masofa (km) + vaqt (min)
  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    try {
      final res = await _dio.get(
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': false,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List).cast<List<dynamic>>();

      // GeoJSON: [lng, lat] → LatLng(lat, lng)
      final points = coords.map((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      )).toList();

      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      return RouteResult(
        points: points,
        distanceKm: distanceM / 1000,
        durationMin: (durationS / 60).ceil(),
      );
    } catch (e) {
      debugPrint('OSRM xato: $e');
      return null;
    }
  }
}

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;
  const RouteResult({required this.points, required this.distanceKm, required this.durationMin});
}
