import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

// Farg'ona shahar markazi (GPS olinmaguncha default)
const _ferghanaCenter = LatLng(40.3842, 71.7872);

/// GPS joylashuvni olish
Future<LatLng> _getCurrentLocation() async {
  bool enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return _ferghanaCenter;

  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return _ferghanaCenter;
  }
  if (perm == LocationPermission.deniedForever) return _ferghanaCenter;

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
  );
  return LatLng(pos.latitude, pos.longitude);
}

final activeRideProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final res = await ref.watch(dioProvider).get('/rides/my', queryParameters: {'active_only': true});
  final list = (res.data as List).cast<Map<String, dynamic>>();
  return list.isNotEmpty ? list.first : null;
});

class TaxiScreen extends ConsumerWidget {
  const TaxiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(activeRideProvider);
    return Scaffold(
      body: rideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (activeRide) {
          if (activeRide != null) return _ActiveRideMap(ride: activeRide);
          return const _RequestRideWithMap();
        },
      ),
    );
  }
}

class _RequestRideWithMap extends ConsumerStatefulWidget {
  const _RequestRideWithMap();
  @override
  ConsumerState<_RequestRideWithMap> createState() => _RequestRideWithMapState();
}

class _RequestRideWithMapState extends ConsumerState<_RequestRideWithMap> {
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _mapCtrl = MapController();
  bool _loading = false;
  String? _error;
  LatLng _myLocation = _ferghanaCenter;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await _getCurrentLocation();
    if (mounted) {
      setState(() => _myLocation = loc);
      _mapCtrl.move(loc, 15);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pickupCtrl.text.trim().length < 3 || _destCtrl.text.trim().length < 3) {
      setState(() => _error = 'Ikkala manzilni ham kiriting');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioProvider).post('/rides', data: {
        'pickup_address': _pickupCtrl.text.trim(),
        'destination_address': _destCtrl.text.trim(),
      });
      ref.invalidate(activeRideProvider);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Xarita
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(initialCenter: _myLocation, initialZoom: 15),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              Marker(
                point: _myLocation,
                width: 40, height: 40,
                child: const Icon(Icons.my_location, color: AppTheme.primary, size: 32),
              ),
            ]),
          ],
        ),

        // Pastdagi form
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Qaerga boramiz?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pickupCtrl,
                    decoration: InputDecoration(
                      hintText: 'Qayerdan',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 14),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _destCtrl,
                    decoration: InputDecoration(
                      hintText: 'Qayerga',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.monetization_on, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Taxminiy: ', style: TextStyle(fontSize: 14)),
                        Text('15,000 so\'m', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.local_taxi),
                    label: const Text('Taksi chaqirish'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveRideMap extends ConsumerStatefulWidget {
  const _ActiveRideMap({required this.ride});
  final Map<String, dynamic> ride;
  @override
  ConsumerState<_ActiveRideMap> createState() => _ActiveRideMapState();
}

class _ActiveRideMapState extends ConsumerState<_ActiveRideMap> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => ref.invalidate(activeRideProvider));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final status = r['status'] as String;
    final driverName = r['driver_name'] as String?;
    final carModel = r['car_model'] as String?;
    final carNumber = r['car_number'] as String?;

    final (statusText, statusColor, statusIcon) = switch (status) {
      'searching' => ('Haydovchi qidirilmoqda...', Colors.orange, Icons.search),
      'accepted' => ('Haydovchi yo\'lda', Colors.blue, Icons.directions_car),
      'arrived' => ('Haydovchi yetib keldi!', AppTheme.secondary, Icons.place),
      'in_progress' => ('Sayohat davom etmoqda', AppTheme.primary, Icons.navigation),
      _ => (status, Colors.grey, Icons.info),
    };

    return Stack(
      children: [
        // Xarita
        FlutterMap(
          options: const MapOptions(initialCenter: _ferghanaCenter, initialZoom: 14),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              Marker(
                point: _ferghanaCenter,
                width: 40, height: 40,
                child: const Icon(Icons.person_pin_circle, color: AppTheme.primary, size: 36),
              ),
            ]),
          ],
        ),

        // Tepadagi holat
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(statusText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor))),
                ],
              ),
            ),
          ),
        ),

        // Pastdagi panel
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Manzillar
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r['pickup_address'] as String, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r['destination_address'] as String, style: const TextStyle(fontSize: 13))),
                    ],
                  ),

                  // Haydovchi
                  if (driverName != null) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driverName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              if (carModel != null) Text('$carModel  •  $carNumber',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${r['fare']} so\'m',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  ],

                  // Bekor qilish
                  if (status == 'searching' || status == 'accepted') ...[
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(dioProvider).post('/rides/${r['id']}/cancel');
                        ref.invalidate(activeRideProvider);
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accent)),
                      child: const Text('Bekor qilish', style: TextStyle(color: AppTheme.accent)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
