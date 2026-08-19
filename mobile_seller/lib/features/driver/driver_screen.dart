import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/ws_service.dart';

/// Kutayotgan so'rovlar
final availableRidesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res =
        await ref.watch(dioProvider).get('/rides/driver/available');
    return (res.data as List).cast<Map<String, dynamic>>();
  } on DioException {
    return [];
  }
});

class DriverScreen extends ConsumerStatefulWidget {
  const DriverScreen({super.key});
  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen> {
  bool _isOnline = false;
  bool _hasProfile = false;
  Map<String, dynamic>? _activeRide;
  Timer? _pollTimer;
  bool _loading = false;
  bool _checking = true;

  // ── Real-time location broadcast ──
  DriverRideWsService? _rideWs;
  StreamSubscription<Position>? _positionSub;
  Timer? _locationThrottleTimer;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stopLocationBroadcast();
    super.dispose();
  }

  /// Active ride bo'lsa WebSocket'ga ulanib, joylashuv yuborish
  Future<void> _startLocationBroadcast(int rideId) async {
    // Allaqachon shu ride uchun ulangan bo'lsa, qayta ulanmaslik
    if (_rideWs?.isConnected == true && _rideWs?.rideId == rideId) return;

    // Eski WS'ni yopish
    _stopLocationBroadcast();

    // GPS ruxsatini tekshirish
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS xizmati o\'chirilgan');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('GPS ruxsati rad etildi');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('GPS ruxsati doimiy rad etilgan');
      return;
    }

    // WebSocket'ga ulanish
    _rideWs = DriverRideWsService();
    final ok = await _rideWs!.connect(
      rideId,
      ref.read(secureStorageProvider),
    );
    if (!ok) {
      debugPrint('WS ulanishda xato');
      return;
    }

    // GPS stream'ga obuna bo'lish (har 5 metrda yoki 2 sekundda)
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      _lastPosition = pos;
    });

    // Har 3 sekundda oxirgi joylashuvni yuborish
    _locationThrottleTimer?.cancel();
    _locationThrottleTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
      if (_lastPosition != null && _rideWs?.isConnected == true) {
        _rideWs!.sendLocation(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
        );
      }
    });

    debugPrint('Location broadcast boshlandi: ride/$rideId');
  }

  void _stopLocationBroadcast() {
    _locationThrottleTimer?.cancel();
    _locationThrottleTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
    _rideWs?.disconnect();
    _rideWs = null;
    _lastPosition = null;
  }

  Future<void> _checkProfile() async {
    setState(() => _checking = true);
    try {
      await ref.read(dioProvider).post('/rides/driver/online');
      setState(() {
        _hasProfile = true;
        _isOnline = true;
        _checking = false;
      });
      _startPolling();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() {
          _hasProfile = false;
          _checking = false;
        });
      } else {
        setState(() {
          _hasProfile = true;
          _checking = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _loadRides());
    _loadRides();
  }

  Future<void> _loadRides() async {
    if (!_isOnline) return;
    try {
      final myRes = await ref
          .read(dioProvider)
          .get('/rides/my', queryParameters: {'active_only': true});
      final myRides = (myRes.data as List).cast<Map<String, dynamic>>();
      final driverActive = myRides
          .where((r) =>
              r['driver_id'] != null &&
              ['accepted', 'arrived', 'in_progress']
                  .contains(r['status']))
          .toList();
      if (driverActive.isNotEmpty) {
        final ride = driverActive.first;
        setState(() => _activeRide = ride);
        // Real-time location broadcast boshlash
        _startLocationBroadcast(ride['id'] as int);
        return;
      }
      // Active ride yo'q — broadcast to'xtatish
      if (_activeRide != null) {
        _stopLocationBroadcast();
      }
      setState(() => _activeRide = null);
      ref.invalidate(availableRidesProvider);
    } catch (e) {
      debugPrint('_loadRides xato: $e');
    }
  }

  Future<void> _toggleOnline() async {
    HapticFeedback.lightImpact();
    try {
      final res = await ref.read(dioProvider).post('/rides/driver/online');
      final online = res.data['is_online'] as bool;
      setState(() => _isOnline = online);
      if (online) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    }
  }

  Future<void> _acceptRide(int rideId) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final res =
          await ref.read(dioProvider).post('/rides/$rideId/accept');
      setState(() => _activeRide = res.data as Map<String, dynamic>);
      // Qabul qilingandan so'ng darhol WS ulanish
      _startLocationBroadcast(rideId);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_activeRide == null) return;
    HapticFeedback.mediumImpact();
    try {
      final res = await ref.read(dioProvider).post(
        '/rides/${_activeRide!['id']}/status',
        data: {'status': newStatus},
      );
      final updated = res.data as Map<String, dynamic>;
      // WS orqali status o'zgarishini ham broadcast qilish
      _rideWs?.sendStatus(newStatus);
      if (newStatus == 'completed') {
        HapticFeedback.heavyImpact();
        _stopLocationBroadcast();
        setState(() => _activeRide = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Sayohat tugadi! ${formatSom(double.tryParse(updated['fare'].toString()) ?? 0)}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() => _activeRide = updated);
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!_hasProfile) {
      return _CreateProfileView(onCreated: _checkProfile);
    }

    return Column(
      children: [
        // ── Online status banner ──
        Container(
          margin: const EdgeInsets.all(16),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isOnline ? AppColors.successTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
                color: _isOnline
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isOnline
                      ? AppColors.success
                      : AppColors.textMuted,
                  shape: BoxShape.circle,
                  boxShadow: _isOnline
                      ? [
                          BoxShadow(
                            color: AppColors.success
                                .withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isOnline ? 'Onlayn rejimda' : 'Oflayn rejimda',
                  style: AppTypography.cardTitleSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: _isOnline,
                activeThumbColor: AppColors.success,
                onChanged: (_) => _toggleOnline(),
              ),
            ],
          ),
        ),

        // ── Content ──
        Expanded(
          child: _activeRide != null
              ? _ActiveRideDriver(
                  ride: _activeRide!, onUpdateStatus: _updateStatus)
              : _isOnline
                  ? _AvailableRides(
                      onAccept: _acceptRide, loading: _loading)
                  : const _OfflineState(),
        ),
      ],
    );
  }
}

class _OfflineState extends StatelessWidget {
  const _OfflineState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: const Icon(Icons.power_settings_new,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Oflayn rejimdasiz',
              style: AppTypography.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'So\'rovlarni olish uchun yuqoridagi\ntugma orqali onlayn bo\'ling',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateProfileView extends ConsumerStatefulWidget {
  const _CreateProfileView({required this.onCreated});
  final VoidCallback onCreated;
  @override
  ConsumerState<_CreateProfileView> createState() =>
      _CreateProfileViewState();
}

class _CreateProfileViewState
    extends ConsumerState<_CreateProfileView> {
  final _modelCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _modelCtrl.dispose();
    _numberCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    if (_modelCtrl.text.trim().isEmpty ||
        _numberCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Model va raqamni kiriting');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(dioProvider).post('/rides/driver/profile', data: {
        'car_model': _modelCtrl.text.trim(),
        'car_number': _numberCtrl.text.trim(),
        if (_colorCtrl.text.trim().isNotEmpty)
          'car_color': _colorCtrl.text.trim(),
      });
      HapticFeedback.lightImpact();
      widget.onCreated();
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _error =
            e.response?.data['detail']?.toString() ?? 'Xato');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: const Icon(Icons.local_taxi,
                  size: 48, color: AppColors.warning),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mashina ma\'lumotlari',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Haydovchi bo\'lish uchun mashina\nma\'lumotlarini kiriting',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(
              labelText: 'Mashina modeli',
              hintText: 'Cobalt',
              prefixIcon: Icon(Icons.directions_car),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numberCtrl,
            decoration: const InputDecoration(
              labelText: 'Raqami',
              hintText: '01 A 123 BC',
              prefixIcon: Icon(Icons.numbers),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _colorCtrl,
            decoration: const InputDecoration(
              labelText: 'Rangi (ixtiyoriy)',
              hintText: 'Oq',
              prefixIcon: Icon(Icons.palette_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerTint,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.ctaText),
                    )
                  : Text(
                      'Saqlash',
                      style: AppTypography.button,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableRides extends ConsumerWidget {
  const _AvailableRides({required this.onAccept, required this.loading});
  final Future<void> Function(int) onAccept;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(availableRidesProvider);
    return ridesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => ErrorRetryWidget(
          error: e, onRetry: () => ref.invalidate(availableRidesProvider)),
      data: (rides) {
        if (rides.isEmpty) return const _NoRidesState();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(availableRidesProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: rides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = rides[i];
              final fareStr = r['fare']?.toString() ?? '0';
              final fare = double.tryParse(fareStr) ?? 0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                                width: 1.5,
                                height: 26,
                                color: AppColors.border),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r['pickup_address']}',
                                style: AppTypography.cardTitleSm
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${r['destination_address']}',
                                style: AppTypography.cardTitleSm
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            formatSom(fare),
                            style: AppTypography.priceSm.copyWith(
                              color: AppColors.success,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: loading
                            ? null
                            : () => onAccept(r['id'] as int),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          'Qabul qilish',
                          style: AppTypography.button,
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NoRidesState extends StatelessWidget {
  const _NoRidesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: const Icon(Icons.search,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Hozircha so\'rov yo\'q',
              style: AppTypography.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Yangi so\'rov kelganda darhol\nko\'rsatamiz',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRideDriver extends StatelessWidget {
  const _ActiveRideDriver(
      {required this.ride, required this.onUpdateStatus});
  final Map<String, dynamic> ride;
  final Future<void> Function(String) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String;
    final (nextStatus, nextLabel) = switch (status) {
      'accepted' => ('arrived', 'Yetib keldim'),
      'arrived' => ('in_progress', 'Sayohatni boshlash'),
      'in_progress' => ('completed', 'Sayohatni tugatish'),
      _ => (null, ''),
    };
    final fareStr = ride['fare']?.toString() ?? '0';
    final fare = double.tryParse(fareStr) ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAOL SAYOHAT',
                  style: AppTypography.sectionLabel,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle),
                        ),
                        Container(
                            width: 2,
                            height: 28,
                            color: AppColors.border),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride['pickup_address'] as String,
                            style: AppTypography.cardTitle.copyWith(
                                fontSize: 15, letterSpacing: 0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ride['destination_address'] as String,
                            style: AppTypography.cardTitle.copyWith(
                                fontSize: 15, letterSpacing: 0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      formatSom(fare),
                      style: AppTypography.price.copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          if (nextStatus != null)
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: () => onUpdateStatus(nextStatus),
                icon: Icon(_iconForStatus(nextStatus)),
                label: Text(
                  nextLabel,
                  style: AppTypography.button.copyWith(fontSize: 17),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForStatus(String s) => switch (s) {
        'arrived' => Icons.location_on,
        'in_progress' => Icons.navigation,
        'completed' => Icons.check_circle,
        _ => Icons.arrow_forward,
      };
}
