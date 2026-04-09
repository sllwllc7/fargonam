import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

/// Haydovchi profili
final driverProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    await ref.watch(dioProvider).get('/rides/driver/available');
    return {'exists': true}; // profil bor demak
  } on DioException catch (e) {
    if (e.response?.statusCode == 400) return null; // profil yo'q yoki offlayn
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

/// Kutayotgan so'rovlar
final availableRidesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ref.watch(dioProvider).get('/rides/driver/available');
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

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    try {
      // Profil tekshirish — online toggle orqali
      await ref.read(dioProvider).post('/rides/driver/online');
      setState(() { _hasProfile = true; _isOnline = true; });
      _startPolling();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() => _hasProfile = false);
      } else {
        setState(() => _hasProfile = true);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadRides());
    _loadRides();
  }

  Future<void> _loadRides() async {
    if (!_isOnline) return;
    try {
      // Faol ride bormi
      final myRes = await ref.read(dioProvider).get('/rides/my', queryParameters: {'active_only': true});
      final myRides = (myRes.data as List).cast<Map<String, dynamic>>();
      final driverActive = myRides.where((r) =>
          r['driver_id'] != null && ['accepted', 'arrived', 'in_progress'].contains(r['status'])).toList();
      if (driverActive.isNotEmpty) {
        setState(() => _activeRide = driverActive.first);
        return;
      }
      setState(() => _activeRide = null);
      ref.invalidate(availableRidesProvider);
    } catch (_) {}
  }

  Future<void> _toggleOnline() async {
    try {
      final res = await ref.read(dioProvider).post('/rides/driver/online');
      final online = res.data['is_online'] as bool;
      setState(() => _isOnline = online);
      if (online) _startPolling(); else _pollTimer?.cancel();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    }
  }

  Future<void> _acceptRide(int rideId) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post('/rides/$rideId/accept');
      setState(() => _activeRide = res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_activeRide == null) return;
    try {
      final res = await ref.read(dioProvider).post(
        '/rides/${_activeRide!['id']}/status',
        data: {'status': newStatus},
      );
      final updated = res.data as Map<String, dynamic>;
      if (newStatus == 'completed') {
        setState(() => _activeRide = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sayohat tugadi! Narx: ${updated['fare']} so\'m'), backgroundColor: Colors.green),
          );
        }
      } else {
        setState(() => _activeRide = updated);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasProfile) return _CreateProfileView(onCreated: () => _checkProfile());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haydovchi'),
        actions: [
          // Onlayn/Oflayn tugma
          TextButton.icon(
            onPressed: _toggleOnline,
            icon: Icon(
              _isOnline ? Icons.circle : Icons.circle_outlined,
              color: _isOnline ? Colors.green : Colors.grey,
              size: 14,
            ),
            label: Text(_isOnline ? 'Onlayn' : 'Oflayn',
                style: TextStyle(color: _isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _activeRide != null
          ? _ActiveRideDriver(ride: _activeRide!, onUpdateStatus: _updateStatus)
          : _isOnline
              ? _AvailableRides(onAccept: _acceptRide, loading: _loading)
              : const Center(
                  child: Text('Buyurtmalar olish uchun onlayn rejimga o\'ting',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
    );
  }
}

class _CreateProfileView extends ConsumerStatefulWidget {
  const _CreateProfileView({required this.onCreated});
  final VoidCallback onCreated;
  @override
  ConsumerState<_CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends ConsumerState<_CreateProfileView> {
  final _modelCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _modelCtrl.dispose();
    _numberCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mashina ma\'lumotlari')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Haydovchi bo\'lish uchun mashina ma\'lumotlarini kiriting',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(controller: _modelCtrl, decoration: const InputDecoration(labelText: 'Mashina modeli', hintText: 'Cobalt', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _numberCtrl, decoration: const InputDecoration(labelText: 'Raqami', hintText: '01 A 123 BC', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Rangi (ixtiyoriy)', hintText: 'Oq', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await ref.read(dioProvider).post('/rides/driver/profile', data: {
                    'car_model': _modelCtrl.text.trim(),
                    'car_number': _numberCtrl.text.trim(),
                    if (_colorCtrl.text.trim().isNotEmpty) 'car_color': _colorCtrl.text.trim(),
                  });
                  widget.onCreated();
                } on DioException catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato')));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(child: Text('Hozircha so\'rov yo\'q\nKutyapsiz...', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rides[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['pickup_address']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                    Text('${r['destination_address']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Narx: ${r['fare']} so\'m', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : () => onAccept(r['id'] as int),
                        child: const Text('Qabul qilish'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveRideDriver extends StatelessWidget {
  const _ActiveRideDriver({required this.ride, required this.onUpdateStatus});
  final Map<String, dynamic> ride;
  final Future<void> Function(String) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String;
    final (nextStatus, nextLabel, nextColor) = switch (status) {
      'accepted' => ('arrived', 'Yetib keldim', Colors.blue),
      'arrived' => ('in_progress', 'Sayohatni boshlash', Colors.indigo),
      'in_progress' => ('completed', 'Sayohatni tugatish', Colors.green),
      _ => (null, '', Colors.grey),
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Faol sayohat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('📍 ${ride['pickup_address']}'),
                  const SizedBox(height: 4),
                  Text('🏁 ${ride['destination_address']}'),
                  const SizedBox(height: 8),
                  Text('Narx: ${ride['fare']} so\'m', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (nextStatus != null)
            FilledButton(
              onPressed: () => onUpdateStatus(nextStatus),
              style: FilledButton.styleFrom(backgroundColor: nextColor, padding: const EdgeInsets.symmetric(vertical: 18)),
              child: Text(nextLabel, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
