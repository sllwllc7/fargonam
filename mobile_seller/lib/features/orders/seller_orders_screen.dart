import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:fargonam_ui/theme/legacy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      backgroundColor: LegacyColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text('Buyurtmalar', style: LegacyTextStyles.h2.copyWith(color: LegacyColors.primaryDark)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: LegacyColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: LegacyTextStyles.body.copyWith(color: LegacyColors.text),
                  decoration: InputDecoration(
                    hintText: 'Kod, ism yoki telefon bo\'yicha qidirish',
                    hintStyle: LegacyTextStyles.body.copyWith(color: LegacyColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: LegacyColors.textMuted, size: 20.sp),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
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
                      child: Text('Hech narsa topilmadi', style: LegacyTextStyles.body.copyWith(color: LegacyColors.textMuted)),
                    );
                  }
                  return RefreshIndicator(
                    color: LegacyColors.primary,
                    backgroundColor: LegacyColors.surface,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      ref.invalidate(sellerOrdersProvider);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) => _OrderCard(order: filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
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
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, _) => ShimmerBox(width: double.infinity, height: 160.h, borderRadius: AppRadius.card),
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
              width: 96.w,
              height: 96.w,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, size: 42.sp, color: LegacyColors.textMuted),
            ),
            SizedBox(height: 20.h),
            Text('Hali buyurtma kelmagan', style: LegacyTextStyles.cardTitle),
            SizedBox(height: 6.h),
            Text('Buyurtmalar shu yerda paydo bo\'ladi',
                style: LegacyTextStyles.body.copyWith(color: LegacyColors.textMuted)),
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
    'pending': LegacyColors.textMuted,
    'preparing': LegacyColors.warning,
    'ready': LegacyColors.accent,
    'shipped': LegacyColors.accent,
    'delivered': LegacyColors.success,
    'cancelled': LegacyColors.danger,
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
          SnackBar(content: Text('Holat: ${_statusLabels[newStatus]}'), backgroundColor: LegacyColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: LegacyColors.danger,
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
        backgroundColor: LegacyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text(_isPickup ? 'Topshirildi deb belgilansinmi?' : 'Yetkazildi deb belgilansinmi?'),
        content: const Text(
          'Bu amalni ortga qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LegacyColors.primary),
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
        backgroundColor: LegacyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Buyurtmani bekor qilish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu amalni ortga qaytarib bo\'lmaydi. Zaxira avtomatik qaytariladi, xaridorga xabar boradi.',
              style: LegacyTextStyles.caption,
            ),
            SizedBox(height: 12.h),
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
            style: FilledButton.styleFrom(backgroundColor: LegacyColors.danger),
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
    final color = _statusColors[_status] ?? LegacyColors.textMuted;
    final totalStr = widget.order['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: LegacyColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: LegacyColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(color: LegacyColors.surfaceAlt, borderRadius: BorderRadius.circular(8.r)),
                child: Text('#${widget.order['id']}',
                    style: LegacyTextStyles.small.copyWith(color: LegacyColors.text, fontSize: 13)),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(_statusLabels[_status] ?? _status,
                    style: LegacyTextStyles.small.copyWith(color: color, fontSize: 11.5)),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (widget.order['customer_name'] != null || widget.order['customer_phone'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 15.sp, color: LegacyColors.textMuted),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      (widget.order['customer_name'] as String?) ?? '',
                      style: LegacyTextStyles.bodyMedium.copyWith(color: LegacyColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.order['customer_phone'] != null)
                    InkWell(
                      onTap: () => _callCustomer(widget.order['customer_phone'] as String),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        child: Row(
                          children: [
                            Icon(Icons.call, size: 14.sp, color: LegacyColors.success),
                            SizedBox(width: 4.w),
                            Text(widget.order['customer_phone'] as String,
                                style: LegacyTextStyles.small.copyWith(color: LegacyColors.success, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (!_isPickup && (widget.order['delivery_address'] as String?)?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 15.sp, color: LegacyColors.textMuted),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(widget.order['delivery_address'] as String,
                        style: LegacyTextStyles.body.copyWith(color: LegacyColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (_isPickup && widget.order['pickup_code'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: LegacyColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: LegacyColors.success.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Text(
                    widget.order['pickup_code'] as String,
                    style: LegacyTextStyles.h2.copyWith(color: LegacyColors.success, letterSpacing: 4, fontSize: 22),
                  ),
                ),
              ),
            ),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: LegacyColors.textMuted, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      '${item['product_name'] ?? 'Mahsulot #${item['product_id']}'} × ${item['quantity']}',
                      style: LegacyTextStyles.body.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatSom(double.tryParse(item['price_at_purchase']?.toString() ?? '0') ?? 0),
                    style: LegacyTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          Divider(height: 22.h, color: LegacyColors.border),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jami', style: LegacyTextStyles.caption.copyWith(fontSize: 11)),
                    SizedBox(height: 2.h),
                    Text(formatSom(total), style: LegacyTextStyles.price.copyWith(fontSize: 17)),
                  ],
                ),
              ),
              if (_canCancel)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: TextButton(
                    onPressed: _updating ? null : _cancelWithReason,
                    style: TextButton.styleFrom(foregroundColor: LegacyColors.danger),
                    child: const Text('Bajarib bo\'lmaydi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
              if (_nextLabel != null)
                FilledButton(
                  onPressed: _updating ? null : () => _confirmAndAdvance(_nextStatus!),
                  style: FilledButton.styleFrom(
                    backgroundColor: LegacyColors.sellerAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  child: _updating
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
