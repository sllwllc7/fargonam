import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'order_tracking_screen.dart';

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/orders');
  return (res.data as List).cast<Map<String, dynamic>>();
});

const _statusLabels = {
  'pending': 'Qabul qilindi',
  'preparing': 'Tayyorlanmoqda',
  'ready': 'Tayyor',
  'shipped': 'Kuryerda',
  'delivered': 'Yetkazildi',
  'cancelled': 'Bekor qilingan',
};

/// dc.html `statusBadge()` — holat belgisi rangi.
(Color, Color) _statusBadgeColors(String status) {
  if (status == 'delivered') return (AppColors.successTint, AppColors.success);
  if (status == 'shipped') return (AppColors.primaryLight, AppColors.primaryDeep);
  if (status == 'cancelled') return (AppColors.dangerTint, AppColors.danger);
  return (AppColors.primaryLight, AppColors.primary);
}

/// Buyurtmalar — HANDOFF.md 2-bo'lim, 10-band.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _tab = 'all';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(
                      onTap: () {
                        if (!Navigator.of(context).canPop()) return;
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    Text('Buyurtmalar', style: AppTypography.h2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    _FilterChip(label: 'Barchasi', selected: _tab == 'all', onTap: () => setState(() => _tab = 'all')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Jarayonda', selected: _tab == 'progress', onTap: () => setState(() => _tab = 'progress')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Yetkazilgan', selected: _tab == 'done', onTap: () => setState(() => _tab = 'done')),
                  ],
                ),
              ),
              Expanded(
                child: ordersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTypography.caption)),
                  data: (allOrders) {
                    final orders = allOrders.where((o) {
                      final status = o['status'] as String;
                      if (_tab == 'all') return true;
                      if (_tab == 'done') return status == 'delivered';
                      return status != 'delivered' && status != 'cancelled';
                    }).toList();

                    if (orders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Buyurtmalar yo\'q', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                              const SizedBox(height: 6),
                              Text('Bu bo\'limda hozircha buyurtma yo\'q', style: AppTypography.caption.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(myOrdersProvider);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => FadeUpItem(
                          delay: AppMotion.staggerStep * i,
                          child: _OrderCard(order: orders[i]),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.95,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
        decoration: BoxDecoration(color: selected ? AppColors.textPrimary : AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.chip)),
        child: Text(label, style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5, color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final items = (o['items'] as List?) ?? [];
    final status = o['status'] as String;
    final total = double.tryParse(o['total']?.toString() ?? '') ?? 0;
    final (bg, fg) = _statusBadgeColors(status);

    return PressableScale(
      scale: 0.98,
      onTap: () {
        HapticFeedback.lightImpact();
        pushAppRoute(context, (_) => OrderTrackingScreen(order: o));
      },
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FN-${o['id']}', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(_statusLabels[status] ?? status, style: AppTypography.small.copyWith(color: fg, fontSize: 11.5)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text('${_formatDate(o['created_at'] as String?)} · ${items.length} ta mahsulot', style: AppTypography.caption),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatSom(total), style: AppTypography.cardTitle.copyWith(fontSize: 15.5)),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];
    return '${dt.day}-${months[dt.month - 1]}';
  }
}
