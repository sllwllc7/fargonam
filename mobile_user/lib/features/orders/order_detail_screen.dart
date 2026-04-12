import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  ConsumerState<OrderDetailScreen> createState() =>
      _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Map<String, dynamic> order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    order = Map.from(widget.order);
  }

  Future<void> _cancelOrder() async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Buyurtmani bekor qilish'),
        content: const Text(
          'Rostdan ham bu buyurtmani bekor qilmoqchimisiz?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    setState(() => _cancelling = true);
    try {
      await ref.read(dioProvider).post('/orders/${order['id']}/cancel');
      setState(() {
        order['status'] = 'cancelled';
      });
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Buyurtma bekor qilindi'),
              backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.response?.data['detail']?.toString() ?? 'Xato'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    final status = order['status'] as String;
    final dt = DateTime.tryParse(order['created_at'] as String);
    final date = dt != null
        ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
        : '';
    final totalStr = order['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Buyurtma #${order['id']}'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status holat kartochka ──
          Container(
            padding: const EdgeInsets.all(20),
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
                    const Text('Holat',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(date,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 18),
                if (status == 'cancelled')
                  const _CancelledBadge()
                else
                  _StatusStepper(currentStatus: status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Mahsulotlar ──
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'MAHSULOTLAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          for (final item in items)
            _OrderItemTile(item: item as Map<String, dynamic>),

          const SizedBox(height: 16),

          // ── Hisob-kitob ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              children: [
                if (items.isNotEmpty) ...[
                  for (final item in items) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(item as Map<String, dynamic>)['product_name'] ?? 'Mahsulot'} × ${item['quantity']}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatPrice(double.tryParse(
                                    item['price_at_purchase']
                                            ?.toString() ??
                                        '0') ??
                                0),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                ],
                Row(
                  children: [
                    const Text('Jami:',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(
                      _formatPrice(total),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cream,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Bekor qilish (faqat pending holatda) ──
          if (status == 'pending') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOrder,
                icon: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.error))
                    : const Icon(Icons.cancel_outlined,
                        color: AppColors.error),
                label: const Text(
                  'Buyurtmani bekor qilish',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Cancelled badge ──

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
          SizedBox(width: 10),
          Text('Buyurtma bekor qilingan',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Status stepper ──

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.currentStatus});
  final String currentStatus;

  static const _steps = [
    ('pending', 'Kutilmoqda', Icons.hourglass_empty),
    ('paid', 'To\'langan', Icons.payment),
    ('shipped', 'Yo\'lda', Icons.local_shipping),
    ('delivered', 'Yetkazildi', Icons.check_circle),
  ];

  int get _currentIndex =>
      _steps.indexWhere((s) => s.$1 == currentStatus).clamp(0, _steps.length - 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _StepRow(
            icon: _steps[i].$3,
            label: _steps[i].$2,
            isCompleted: i <= _currentIndex,
            isCurrent: i == _currentIndex,
          ),
          if (i < _steps.length - 1)
            _StepLine(isCompleted: i < _currentIndex),
        ],
      ],
    );
  }
}

class _StepRow extends StatefulWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.isCurrent) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StepRow old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isCompleted ? AppColors.success : AppColors.textMuted;
    return Row(
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = widget.isCurrent ? _ctrl.value : 0.0;
            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? AppColors.successSoft
                    : AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: widget.isCurrent
                    ? Border.all(color: AppColors.success, width: 2.5)
                    : null,
                boxShadow: widget.isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.success
                              .withValues(alpha: 0.2 + (0.4 * t)),
                          blurRadius: 14 + (8 * t),
                          spreadRadius: 1 + (2 * t),
                        ),
                      ]
                    : null,
              ),
              child: Icon(widget.icon, size: 18, color: color),
            );
          },
        ),
        const SizedBox(width: 14),
        Text(
          widget.label,
          style: TextStyle(
            fontWeight:
                widget.isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: widget.isCompleted
                ? AppColors.textPrimary
                : AppColors.textMuted,
            fontSize: widget.isCurrent ? 15 : 14,
          ),
        ),
        if (widget.isCurrent) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
          ),
        ],
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isCompleted});
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Container(
        width: 2,
        height: 28,
        color: isCompleted ? AppColors.success : AppColors.divider,
      ),
    );
  }
}

// ── Order item tile ──

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['product_name'] as String? ??
        'Mahsulot #${item['product_id']}';
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final qty = item['quantity'] as int;
    final priceStr = item['price_at_purchase']?.toString();
    final price = priceStr != null ? double.tryParse(priceStr) ?? 0 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: fullImg != null
                  ? AppCachedImage(
                      url: fullImg,
                      width: 60,
                      height: 60,
                      borderRadius: 0,
                    )
                  : Container(
                      color: AppColors.surfaceHigh,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPrice(price.toDouble())} × $qty',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatPrice(price * qty),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.cream,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
