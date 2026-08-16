import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cached_image.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../addresses/addresses_screen.dart' show addressesProvider;

final cartProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/cart');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final title = isDark ? AppTextStylesDark.title : AppTextStyles.title;

    final cartAsync = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('Savatcha', style: title),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      body: cartAsync.when(
        loading: () => const _CartSkeleton(),
        error: (e, _) => AppErrorState(error: e, onRetry: () => ref.invalidate(cartProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyCartState();

          double total = 0;
          int totalQty = 0;
          for (final ci in items) {
            final priceStr = ci['product_price']?.toString();
            final price = priceStr != null ? double.tryParse(priceStr) ?? 0 : 0;
            final qty = (ci['quantity'] as int?) ?? 0;
            total += price * qty;
            totalQty += qty;
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: primary,
                  backgroundColor: background,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    ref.invalidate(cartProvider);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => _CartItemCard(item: items[i]),
                  ),
                ),
              ),

              // Pastki panel — jami narx, yetkazib berish, checkout
              Container(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
                  boxShadow: AppShadows.floating,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: textSecondary),
                          SizedBox(width: AppSpacing.xs),
                          Text('Yetkazib berish: Bepul', style: TextStyle(color: textSecondary, fontSize: 13.sp)),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text('Jami:', style: TextStyle(color: textSecondary, fontSize: 14.sp)),
                          SizedBox(width: AppSpacing.xs),
                          Text('($totalQty ta)', style: TextStyle(color: textSecondary, fontSize: 12.sp)),
                          const Spacer(),
                          Text(_formatPrice(total), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: primary)),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      _CheckoutButton(itemCount: items.length),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Cart item ───────────────────────────────────────────────

class _CartItemCard extends ConsumerStatefulWidget {
  const _CartItemCard({required this.item});
  final Map<String, dynamic> item;

  @override
  ConsumerState<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<_CartItemCard> {
  late int _qty;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.item['quantity'] as int;
  }

  @override
  void didUpdateWidget(covariant _CartItemCard old) {
    super.didUpdateWidget(old);
    final newQty = widget.item['quantity'] as int;
    if (!_busy && newQty != _qty) _qty = newQty;
  }

  Future<void> _changeQty(int delta) async {
    final next = _qty + delta;
    if (next < 1 || _busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _qty = next;
      _busy = true;
    });
    try {
      await ref.read(dioProvider).patch('/cart/${widget.item['id']}', queryParameters: {'quantity': next});
      ref.invalidate(cartProvider);
    } catch (_) {
      if (mounted) setState(() => _qty -= delta);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDelete() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            title: const Text('O\'chirish?'),
            content: Text('Mahsulotni savatchadan olib tashlamoqchimisiz?',
                style: TextStyle(color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: isDark ? AppColorsDark.error : AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('O\'chirish'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _delete() async {
    try {
      await ref.read(dioProvider).delete('/cart/${widget.item['id']}');
      ref.invalidate(cartProvider);
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('O\'chirishda xato. Sahifani yangilang.'),
            backgroundColor: isDark ? AppColorsDark.error : AppColors.error,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
      ref.invalidate(cartProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final item = widget.item;
    final name = item['product_name'] as String? ?? 'Mahsulot #${item['product_id']}';
    final priceStr = item['product_price']?.toString();
    final price = priceStr != null ? double.tryParse(priceStr) ?? 0 : 0;
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final lineTotal = price * _qty;
    final isAvailable = item['is_available'] as bool? ?? true;

    return Dismissible(
      key: ValueKey('cart_${item['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _delete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Icon(Icons.delete_outline, color: error, size: 28),
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: isAvailable ? null : Border.all(color: error.withValues(alpha: 0.4), width: 1),
        ),
        child: Opacity(
          opacity: isAvailable ? 1 : 0.55,
          child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: SizedBox(
                width: 72.w,
                height: 72.w,
                child: fullImg != null
                    ? AppCachedImage(url: fullImg, width: 72.w, height: 72.w, borderRadius: 0)
                    : Container(color: background, child: Icon(Icons.image_outlined, color: textSecondary)),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  if (!isAvailable)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        'Mavjud emas — o\'chirib tashlang',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: error),
                      ),
                    ),
                  Text(_formatPrice(price.toDouble()), style: TextStyle(fontSize: 12.sp, color: textSecondary)),
                  SizedBox(height: AppSpacing.sm),
                  // Miqdor stepper — gorizontal pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.chip)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(icon: Icons.remove, onTap: () => _changeQty(-1), enabled: isAvailable && _qty > 1),
                            SizedBox(
                              width: 28.w,
                              child: Text('$_qty', textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: textPrimary)),
                            ),
                            _QtyButton(icon: Icons.add, onTap: () => _changeQty(1), enabled: isAvailable),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(_formatPrice(lineTotal.toDouble()),
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: primary)),
                    ],
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
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26.w,
        height: 26.w,
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: enabled ? primary : textSecondary.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ── Checkout tugmasi ────────────────────────────────────────

class _CheckoutButton extends ConsumerStatefulWidget {
  const _CheckoutButton({required this.itemCount});
  final int itemCount;
  @override
  ConsumerState<_CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends ConsumerState<_CheckoutButton> {
  bool _loading = false;
  String? _idempotencyKey;

  Future<void> _checkout() async {
    HapticFeedback.mediumImpact();
    final result = await _showPaymentSheet();
    if (result == null || !mounted) return;

    setState(() => _loading = true);
    _idempotencyKey ??= '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    try {
      final res = await ref.read(dioProvider).post(
        '/orders',
        data: {
          'payment_method': result['payment_method'],
          'delivery_type': result['delivery_type'],
          if (result['delivery_address'] != null) 'delivery_address': result['delivery_address'],
          if (result['delivery_address_id'] != null) 'delivery_address_id': result['delivery_address_id'],
        },
        options: Options(headers: {'Idempotency-Key': _idempotencyKey}),
      );
      ref.invalidate(cartProvider);
      _idempotencyKey = null;
      if (mounted) {
        await _showSuccessDialog(res.data);
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: isDark ? AppColorsDark.error : AppColors.error,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _showPaymentSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      builder: (ctx) => const _PaymentSheet(),
    );
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> order) async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColorsDark.success : AppColors.success;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SuccessCheckmark(color: success),
              SizedBox(height: AppSpacing.lg),
              Text('Buyurtma qabul qilindi!',
                  style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w700, color: textPrimary)),
              SizedBox(height: AppSpacing.xs),
              Text('Buyurtma raqami: #${order['id'] ?? '—'}', style: TextStyle(color: textSecondary, fontSize: 14.sp)),
              if (order['total'] != null) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.input)),
                  child: Text(
                    _formatPrice(double.tryParse(order['total'].toString()) ?? 0),
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: success),
                  ),
                ),
              ],
              if (order['delivery_type'] == 'pickup' && order['pickup_code'] != null) ...[
                SizedBox(height: AppSpacing.lg),
                Text('Do\'kondan olib ketish kodi', style: TextStyle(color: textSecondary, fontSize: 13.sp)),
                SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: success.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Text(
                    order['pickup_code'] as String,
                    style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w900, color: success, letterSpacing: 6),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text('Do\'konga kelganda shu kodni ayting', style: TextStyle(color: textSecondary, fontSize: 12.sp)),
              ],
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Davom etish',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: _loading ? 'Yuborilmoqda...' : 'Buyurtma berish (${widget.itemCount})',
      icon: Icons.shopping_bag,
      loading: _loading,
      onPressed: _checkout,
    );
  }
}

// ── Success checkmark animatsiyasi ──────────────────────────

class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark({required this.color});
  final Color color;

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final scale = Curves.elasticOut.transform(_ctrl.value);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
        );
      },
    );
  }
}

// ── Empty state ─────────────────────────────────────────────

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Savatcha bo\'sh',
      subtitle: 'Marketplace\'dan o\'zingizga\nyoqqan mahsulotni qo\'shing',
      action: AppButton(
        label: 'Marketplace\'ga o\'tish',
        icon: Icons.storefront,
        fullWidth: false,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Skeleton ────────────────────────────────────────────────

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => AppShimmer(height: 100.h, borderRadius: AppRadius.card),
    );
  }
}

// ── To'lov usuli tanlash ────────────────────────────────────

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet();

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  String _method = 'cash';
  String _deliveryType = 'delivery';
  final _addressCtrl = TextEditingController();
  int? _selectedAddressId;
  bool _useFreeText = false;
  bool _initializedDefault = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final h2 = isDark ? AppTextStylesDark.h2 : AppTextStyles.h2;
    final addressesAsync = ref.watch(addressesProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text('To\'lov usulini tanlang', style: h2),
            SizedBox(height: AppSpacing.md),
            _PayMethod(
              value: 'cash',
              selected: _method,
              icon: Icons.payments_outlined,
              title: 'Naqd pul',
              subtitle: 'Kuryerga qo\'lda to\'lash',
              onTap: () => setState(() => _method = 'cash'),
            ),
            SizedBox(height: AppSpacing.sm),
            _PayMethod(
              value: 'card',
              selected: _method,
              icon: Icons.credit_card_outlined,
              title: 'Plastik karta',
              subtitle: 'Kuryerga POS terminal orqali',
              onTap: () => setState(() => _method = 'card'),
            ),
            SizedBox(height: AppSpacing.sm),
            _PayMethod(
              value: 'payme',
              selected: _method,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payme',
              subtitle: 'Tez orada ishga tushadi',
              enabled: false,
              onTap: () {},
            ),
            SizedBox(height: AppSpacing.lg),
            Text('Qanday olasiz?', style: h2),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _PayMethod(
                    value: 'delivery',
                    selected: _deliveryType,
                    icon: Icons.local_shipping_outlined,
                    title: 'Yetkazib berish',
                    subtitle: 'Kuryer olib keladi',
                    onTap: () => setState(() => _deliveryType = 'delivery'),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PayMethod(
                    value: 'pickup',
                    selected: _deliveryType,
                    icon: Icons.storefront_outlined,
                    title: 'Do\'kondan olib ketish',
                    subtitle: 'Kod bilan do\'konda olasiz',
                    onTap: () => setState(() => _deliveryType = 'pickup'),
                  ),
                ),
              ],
            ),

            if (_deliveryType == 'delivery') ...[
            SizedBox(height: AppSpacing.lg),
            Text('Yetkazib berish manzili', style: h2),
            SizedBox(height: AppSpacing.md),

            addressesAsync.when(
              loading: () => AppShimmer(height: 64.h, borderRadius: AppRadius.card),
              error: (_, _) => const SizedBox.shrink(),
              data: (addrs) {
                if (addrs.isEmpty) return const SizedBox.shrink();
                // Birinchi ochilganda — asosiy (yoki birinchi) manzil avtomatik tanlanadi
                if (!_initializedDefault) {
                  _initializedDefault = true;
                  final def = addrs.firstWhere((a) => a['is_default'] == true, orElse: () => addrs.first);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedAddressId = def['id'] as int);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in addrs) ...[
                      _SavedAddressTile(
                        address: a,
                        selected: !_useFreeText && _selectedAddressId == a['id'],
                        onTap: () => setState(() {
                          _useFreeText = false;
                          _selectedAddressId = a['id'] as int;
                        }),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],
                    _FreeTextAddressToggle(
                      selected: _useFreeText,
                      onTap: () => setState(() => _useFreeText = true),
                    ),
                    SizedBox(height: AppSpacing.sm),
                  ],
                );
              },
            ),

            if (_useFreeText || (addressesAsync.value?.isEmpty ?? true))
              TextField(
                controller: _addressCtrl,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Yetkazish manzili',
                  hintText: 'Ko\'cha, uy, xonadon raqami',
                  prefixIcon: Icon(Icons.location_on_outlined, color: textSecondary),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ],
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Buyurtma berish',
              onPressed: () {
                HapticFeedback.mediumImpact();
                final useAddressId = !_useFreeText && _selectedAddressId != null;
                Navigator.pop(context, {
                  'payment_method': _method,
                  'delivery_type': _deliveryType,
                  if (_deliveryType == 'delivery' && useAddressId) 'delivery_address_id': _selectedAddressId,
                  if (_deliveryType == 'delivery' && !useAddressId && _addressCtrl.text.trim().isNotEmpty)
                    'delivery_address': _addressCtrl.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  const _SavedAddressTile({required this.address, required this.selected, required this.onTap});
  final Map<String, dynamic> address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final parts = [address['region'], address['district'], address['address']].whereType<String>().where((s) => s.isNotEmpty);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: selected ? primary : textSecondary, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address['label'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp, color: textPrimary)),
                  Text(parts.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: textSecondary)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FreeTextAddressToggle extends StatelessWidget {
  const _FreeTextAddressToggle({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.1) : surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_location_alt_outlined, color: selected ? primary : textSecondary, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text('Boshqa manzil kiritish', style: TextStyle(fontSize: 13.sp, color: selected ? primary : textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _PayMethod({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final isSelected = value == selected && enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.1) : surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: isSelected ? primary : Colors.transparent, width: 1.5),
        ),
        child: ListTile(
          onTap: enabled ? onTap : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          leading: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(color: isSelected ? primary : background, borderRadius: BorderRadius.circular(AppRadius.input)),
            child: Icon(icon, color: isSelected ? Colors.white : textSecondary, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: textSecondary)),
          trailing: enabled
              ? Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? primary : textSecondary, width: 2),
                    color: isSelected ? primary : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                )
              : Text('tez orada', style: TextStyle(fontSize: 11.sp, color: textSecondary)),
        ),
      ),
    );
  }
}

// ── Helper ──────────────────────────────────────────────────

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf so\'m';
}
