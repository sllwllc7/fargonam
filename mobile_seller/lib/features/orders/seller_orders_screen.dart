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

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Buyurtmalar')),
      body: ordersAsync.when(
        loading: () => const _OrdersSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(sellerOrdersProvider)),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyOrdersState();
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(sellerOrdersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _OrderCard(order: orders[i]),
            ),
          );
        },
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
  static const _statusLabels = {
    'pending': 'Kutilmoqda',
    'paid': 'To\'langan',
    'shipped': 'Yo\'lda',
    'delivered': 'Yetkazildi',
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
      'shipped' => 'Yuborildi',
      'delivered' => 'Yetkazildi',
      _ => null,
    };
  }

  Future<void> _updateStatus(String newStatus) async {
    HapticFeedback.mediumImpact();
    setState(() => _updating = true);
    try {
      await ref.read(dioProvider).patch(
        '/seller/orders/${widget.order['id']}/status',
        queryParameters: {'new_status': newStatus},
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
          const SizedBox(height: 12),

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
              if (_nextLabel != null)
                FilledButton.tonal(
                  onPressed:
                      _updating ? null : () => _updateStatus(_nextStatus!),
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
