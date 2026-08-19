import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';

final sellerOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/seller/orders');
  return (res.data as List).cast<Map<String, dynamic>>();
});

bool _matchesSearch(Map<String, dynamic> order, String query) {
  if (query.isEmpty) return true;
  final q = query.trim().toLowerCase();
  final code = (order['pickup_code'] as String?)?.toLowerCase() ?? '';
  final phone = (order['customer_phone'] as String?)?.toLowerCase() ?? '';
  final name = (order['customer_name'] as String?)?.toLowerCase() ?? '';
  return code.contains(q) || phone.contains(q) || name.contains(q);
}

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Buyurtmalar', style: AppTypography.h2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Kod, ism yoki telefon bo\'yicha qidirish',
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ordersAsync.when(
                  loading: () => const _OrdersSkeleton(),
                  error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(sellerOrdersProvider)),
                  data: (orders) {
                    if (orders.isEmpty) return const _EmptyOrdersState();
                    final filtered = orders.where((o) => _matchesSearch(o, _search)).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('Hech narsa topilmadi', style: AppTypography.body.copyWith(color: AppColors.textMuted)),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(sellerOrdersProvider);
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 4, 20, AppSizes.tabBarHeight + AppSizes.tabBarBottomInset),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => FadeUpItem(
                          delay: AppMotion.staggerStep * i,
                          child: _OrderCard(order: filtered[i]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 4, 20, AppSizes.tabBarHeight + AppSizes.tabBarBottomInset),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const ShimmerBox(width: double.infinity, height: 160, borderRadius: AppRadius.card),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Hali buyurtma kelmagan', style: AppTypography.cardTitle),
            const SizedBox(height: 6),
            Text('Buyurtmalar shu yerda paydo bo\'ladi',
                style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Delivery: Qabul qilindi -> Tayyorlanmoqda -> Tayyor -> Kuryerda -> Yetkazildi
/// Pickup:   Qabul qilindi -> Tayyorlanmoqda -> Tayyor -> Topshirildi (kuryer bosqichisiz)
const _deliveryFlow = ['pending', 'preparing', 'ready', 'shipped', 'delivered'];
const _pickupFlow = ['pending', 'preparing', 'ready', 'delivered'];

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});
  final Map<String, dynamic> order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  late String _status;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'] as String;
  }

  bool get _isPickup => widget.order['delivery_type'] == 'pickup';
  List<String> get _flow => _isPickup ? _pickupFlow : _deliveryFlow;

  Map<String, String> get _statusLabels => {
        'pending': 'Qabul qilindi',
        'preparing': 'Tayyorlanmoqda',
        'ready': 'Tayyor',
        'shipped': 'Kuryerda',
        'delivered': _isPickup ? 'Topshirildi' : 'Yetkazildi',
        'cancelled': 'Bekor qilingan',
      };
  static const _statusColors = {
    'pending': AppColors.textMuted,
    'preparing': AppColors.warning,
    'ready': AppColors.primary,
    'shipped': AppColors.primary,
    'delivered': AppColors.success,
    'cancelled': AppColors.danger,
  };

  String? get _nextStatus {
    if (_status == 'cancelled') return null;
    final idx = _flow.indexOf(_status);
    if (idx < 0 || idx >= _flow.length - 1) return null;
    return _flow[idx + 1];
  }

  String? get _nextLabel {
    final next = _nextStatus;
    if (next == null) return null;
    return switch (next) {
      'preparing' => 'Tayyorlashni boshlash',
      'ready' => 'Tayyor',
      'shipped' => 'Kuryerga berish',
      'delivered' => _isPickup ? 'Topshirdim' : 'Yetkazildi',
      _ => null,
    };
  }

  bool get _canCancel => _status == 'pending' || _status == 'preparing' || _status == 'ready';

  Future<void> _callCustomer(String phone) async {
    HapticFeedback.selectionClick();
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _updateStatus(String newStatus, {String? reason}) async {
    HapticFeedback.mediumImpact();
    setState(() => _updating = true);
    try {
      await ref.read(dioProvider).patch(
        '/seller/orders/${widget.order['id']}/status',
        queryParameters: {
          'new_status': newStatus,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      setState(() => _status = newStatus);
      ref.invalidate(sellerOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Holat: ${_statusLabels[newStatus]}'), backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// 'delivered' — terminal holat, ortga qaytarib bo'lmaydi. Tasodifiy
  /// tap bilan tuzatib bo'lmaydigan holat yaratmaslik uchun tasdiqlash.
  Future<void> _confirmAndAdvance(String newStatus) async {
    if (newStatus != 'delivered') {
      await _updateStatus(newStatus);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text(_isPickup ? 'Topshirildi deb belgilansinmi?' : 'Yetkazildi deb belgilansinmi?'),
        content: const Text(
          'Bu amalni ortga qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, tasdiqlayman'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus(newStatus);
    }
  }

  /// "Bajarib bo'lmaydi" — sababni majburiy so'raydi, terminal holat
  /// ekanini ochiq ogohlantiradi.
  Future<void> _cancelWithReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Buyurtmani bekor qilish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu amalni ortga qaytarib bo\'lmaydi. Zaxira avtomatik qaytariladi, xaridorga xabar boradi.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Sabab (majburiy)',
                hintText: 'Masalan: mahsulot omborda tugagan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Bekor qilaman'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      await _updateStatus('cancelled', reason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List?) ?? [];
    final color = _statusColors[_status] ?? AppColors.textMuted;
    final totalStr = widget.order['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text('#${widget.order['id']}',
                    style: AppTypography.small.copyWith(color: AppColors.textPrimary, fontSize: 13)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabels[_status] ?? _status,
                    style: AppTypography.small.copyWith(color: color, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.order['customer_name'] != null || widget.order['customer_phone'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (widget.order['customer_name'] as String?) ?? '',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.order['customer_phone'] != null)
                    InkWell(
                      onTap: () => _callCustomer(widget.order['customer_phone'] as String),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.call, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(widget.order['customer_phone'] as String,
                                style: AppTypography.small.copyWith(color: AppColors.success, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (!_isPickup && (widget.order['delivery_address'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(widget.order['delivery_address'] as String,
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (_isPickup && widget.order['pickup_code'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Text(
                    widget.order['pickup_code'] as String,
                    style: AppTypography.h2.copyWith(color: AppColors.success, letterSpacing: 4, fontSize: 22),
                  ),
                ),
              ),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item['product_name'] ?? 'Mahsulot #${item['product_id']}'} × ${item['quantity']}',
                      style: AppTypography.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatSom(double.tryParse(item['price_at_purchase']?.toString() ?? '0') ?? 0),
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jami', style: AppTypography.caption.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(formatSom(total), style: AppTypography.price.copyWith(fontSize: 17)),
                  ],
                ),
              ),
              if (_canCancel)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: _updating ? null : _cancelWithReason,
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Bajarib bo\'lmaydi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
              if (_nextLabel != null)
                FilledButton(
                  onPressed: _updating ? null : () => _confirmAndAdvance(_nextStatus!),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  child: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_nextLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
