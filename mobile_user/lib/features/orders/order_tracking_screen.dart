import 'dart:async';

import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'orders_screen.dart' show myOrdersProvider;

/// Kuzatishda holat o'zgarishini o'zi bilib turishi uchun poll oralig'i —
/// /dokon paneli ham xuddi shu ~12s bilan yangilanadi (bir-biriga mos).
const _pollInterval = Duration(seconds: 12);
const _terminalStatuses = {'delivered', 'cancelled'};

const _stages = ['pending', 'preparing', 'ready', 'shipped', 'delivered'];
const _stageTitles = {
  'pending': 'Qabul qilindi',
  'preparing': 'Tayyorlanmoqda',
  'ready': 'Tayyor',
  'shipped': 'Kuryerda',
  'delivered': 'Yetkazildi',
};
const _stageSubs = {
  'pending': 'Buyurtmangiz qabul qilindi',
  'preparing': 'Mahsulotlar yig\'ilmoqda',
  'ready': 'Buyurtma tayyor bo\'ldi',
  'shipped': 'Kuryer yo\'lda',
  'delivered': 'Buyurtma topshirildi',
};

const _checkIconSvg =
    '<svg viewBox="0 0 12 10"><path d="m1 5 3.5 3.5L11 1" stroke="#EEF1F6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';

/// Kuzatish — HANDOFF.md 2-bo'lim, 9-band.
///
/// Sotuvchi (/dokon paneli) holatni o'zgartirsa, foydalanuvchi bu ekranni
/// qo'lda yangilamasdan ko'rishi kerak — shuning uchun ekran ochiq turganda
/// ~12s'da bir marta buyurtma qayta so'raladi (dc.html'da bu jonli oqim
/// yo'q edi, chunki backend/real vaqt hali mavjud emas edi).
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  late Map<String, dynamic> _order;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (!_terminalStatuses.contains(_order['status'])) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(myOrdersProvider);
    List<Map<String, dynamic>> orders;
    try {
      orders = await ref.read(myOrdersProvider.future);
    } catch (_) {
      return; // keyingi pollda qayta urinamiz — foydalanuvchiga xato ko'rsatilmaydi
    }
    if (!mounted) return;
    Map<String, dynamic>? updated;
    for (final o in orders) {
      if (o['id'] == _order['id']) {
        updated = o;
        break;
      }
    }
    if (updated == null) return;
    final newOrder = updated;
    setState(() => _order = newOrder);
    if (_terminalStatuses.contains(newOrder['status'])) {
      _pollTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = order['status'] as String? ?? 'pending';
    final isPickup = order['delivery_type'] == 'pickup';
    final cancelled = status == 'cancelled';
    final idx = _stages.indexOf(isPickup && status == 'shipped' ? 'ready' : status);
    final items = (order['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final total = double.tryParse(order['total']?.toString() ?? '') ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FN-${order['id']}', style: AppTypography.title),
                        if (order['created_at'] != null) Text(_formatDate(order['created_at'] as String), style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPickup && order['pickup_code'] != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      Text('Do\'kondan olib ketish kodi', style: AppTypography.caption.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(order['pickup_code'] as String, style: AppTypography.h1.copyWith(color: AppColors.success, letterSpacing: 6, fontSize: 28)),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: cancelled
                    ? Row(
                        children: [
                          const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bekor qilingan', style: AppTypography.cardTitle.copyWith(color: AppColors.danger, fontSize: 15)),
                                if ((order['cancel_reason'] as String?)?.isNotEmpty == true)
                                  Text(order['cancel_reason'] as String, style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < _stages.length; i++)
                            if (!(isPickup && _stages[i] == 'shipped'))
                              _TimelineStep(
                                done: i <= idx,
                                lineDone: i < idx,
                                title: _stageTitles[_stages[i]]!,
                                sub: _stageSubs[_stages[i]]!,
                                isLast: i == _stages.length - 1 || (isPickup && _stages[i + 1] == 'shipped' && i + 1 == _stages.length - 2),
                              ),
                        ],
                      ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final l in items)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    // `product_name` backend'dan allaqachon "Nomi · Variant"
                                    // ko'rinishida keladi — variant qayta qo'shilmasin.
                                    TextSpan(text: l['product_name'] as String? ?? '', style: AppTypography.rowTitle.copyWith(fontSize: 13.5)),
                                    TextSpan(
                                      text: ' × ${l['quantity']}',
                                      style: AppTypography.caption.copyWith(height: null, fontSize: 13.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatSom((double.tryParse(l['price_at_purchase']?.toString() ?? '') ?? 0) * (l['quantity'] as int? ?? 0)),
                              style: AppTypography.rowTitle.copyWith(fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jami', style: AppTypography.price.copyWith(fontSize: 15)),
                          Text(formatSom(total), style: AppTypography.price.copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];
    return '${dt.day}-${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.done, required this.lineDone, required this.title, required this.sub, required this.isLast});
  final bool done;
  final bool lineDone;
  final String title;
  final String sub;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done ? AppColors.textPrimary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: done ? AppColors.textPrimary : AppColors.primaryLight, width: 2),
                ),
                alignment: Alignment.center,
                child: done ? SvgPicture.string(_checkIconSvg, width: 11, height: 9) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: lineDone ? AppColors.textPrimary : AppColors.primaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitleSm.copyWith(fontSize: 15, color: done ? AppColors.textPrimary : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
