import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final sellerOrdersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Buyurtmalar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Kod, ism yoki telefon bo\'yicha qidirish',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const _OrdersSkeleton(),
              error: (e, _) => ErrorRetryWidget(
                  error: e, onRetry: () => ref.invalidate(sellerOrdersProvider)),
              data: (orders) {
                if (orders.isEmpty) return const _EmptyOrdersState();
                final filtered = orders.where((o) => _matchesSearch(o, _search)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Hech narsa topilmadi',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.cream,
                  backgroundColor: AppColors.surfaceHigh,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    ref.invalidate(sellerOrdersProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _OrderCard(order: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ShimmerBox(
        width: double.infinity,
        height: 160,
        borderRadius: 20,
      ),
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
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.receipt_long,
                  size: 56, color: AppColors.cream),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hali buyurtma kelmagan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buyurtmalar shu yerda paydo bo\'ladi',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

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

  static const _statusFlow = ['pending', 'paid', 'shipped', 'delivered'];

  bool get _isPickup => widget.order['delivery_type'] == 'pickup';

  Map<String, String> get _statusLabels => {
        'pending': 'Kutilmoqda',
        'paid': 'To\'langan',
        'shipped': _isPickup ? 'Tayyor' : 'Yo\'lda',
        'delivered': _isPickup ? 'Topshirildi' : 'Yetkazildi',
        'cancelled': 'Bekor',
      };
  static const _statusColors = {
    'pending': AppColors.warning,
    'paid': AppColors.info,
    'shipped': AppColors.info,
    'delivered': AppColors.success,
    'cancelled': AppColors.error,
  };

  String? get _nextStatus {
    if (_status == 'cancelled') return null;
    final idx = _statusFlow.indexOf(_status);
    if (idx < 0 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  String? get _nextLabel {
    final next = _nextStatus;
    if (next == null) return null;
    return switch (next) {
      'paid' => 'To\'landi',
      'shipped' => _isPickup ? 'Tayyor' : 'Yuborildi',
      'delivered' => _isPickup ? 'Topshirdim' : 'Yetkazildi',
      _ => null,
    };
  }

  bool get _canCancel => _status == 'pending' || _status == 'paid';

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
          SnackBar(
            content: Text(
                'Status: ${_statusLabels[newStatus]}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.error,
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
        title: const Text('Yetkazildi deb belgilansinmi?'),
        content: const Text(
          'Bu amalni ortga qaytarib bo\'lmaydi. Buyurtma "Yetkazildi" '
          'holatiga o\'tadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
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
  /// ekanini ochiq ogohlantiradi (bu dialog o'zi tasdiqlash vazifasini
  /// bajaradi — alohida qo'shimcha tasdiqlash shart emas).
  Future<void> _cancelWithReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Buyurtmani bekor qilish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu amalni ortga qaytarib bo\'lmaydi. Zaxira avtomatik '
              'qaytariladi, xaridorga xabar boradi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${widget.order['id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.cream),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabels[_status] ?? _status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Xaridor ismi/telefoni
          if (widget.order['customer_name'] != null || widget.order['customer_phone'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        if (widget.order['customer_name'] != null) widget.order['customer_name'],
                        if (widget.order['customer_phone'] != null) widget.order['customer_phone'],
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Pickup kod — katta, ajratilgan
          if (_isPickup && widget.order['pickup_code'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    widget.order['pickup_code'] as String,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        letterSpacing: 4),
                  ),
                ),
              ),
            ),

          // Mahsulotlar
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item['product_name'] ?? 'Mahsulot #${item['product_id']}'} × ${item['quantity']}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatPrice(double.tryParse(
                            item['price_at_purchase']
                                    ?.toString() ??
                                '0') ??
                        0),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 22),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jami',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cream,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canCancel)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: _updating ? null : _cancelWithReason,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text(
                      'Bajarib bo\'lmaydi',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              if (_nextLabel != null)
                FilledButton.tonal(
                  onPressed: _updating
                      ? null
                      : () => _confirmAndAdvance(_nextStatus!),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.cream.withValues(alpha: 0.15),
                    foregroundColor: AppColors.cream,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cream))
                      : Text(
                          _nextLabel!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
