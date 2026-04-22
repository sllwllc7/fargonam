import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final cartProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/cart');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Savatcha'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: cartAsync.when(
        loading: () => const _CartSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(cartProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyCartState();

          // Jami narxni hisoblash
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
                  color: AppColors.cream,
                  backgroundColor: AppColors.surfaceHigh,
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    ref.invalidate(cartProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _CartItemCard(item: items[i]),
                  ),
                ),
              ),

              // Pastki panel — jami narx + checkout
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Jami satr
                      Row(
                        children: [
                          const Text(
                            'Jami:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($totalQty ta)',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatPrice(total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
      await ref.read(dioProvider).patch('/cart/${widget.item['id']}',
          queryParameters: {'quantity': next});
      ref.invalidate(cartProvider);
    } catch (_) {
      if (mounted) setState(() => _qty -= delta);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDelete() async {
    HapticFeedback.lightImpact();
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('O\'chirish?'),
            content: const Text(
                'Mahsulotni savatchadan olib tashlamoqchimisiz?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Yo\'q'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O\'chirishda xato. Sahifani yangilang.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      ref.invalidate(cartProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name =
        item['product_name'] as String? ?? 'Mahsulot #${item['product_id']}';
    final priceStr = item['product_price']?.toString();
    final price = priceStr != null ? double.tryParse(priceStr) ?? 0 : 0;
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final lineTotal = price * _qty;

    return Dismissible(
      key: ValueKey('cart_${item['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _delete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 28),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            // Rasm
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: fullImg != null
                    ? AppCachedImage(
                        url: fullImg,
                        width: 76,
                        height: 76,
                        borderRadius: 0,
                      )
                    : Container(
                        color: AppColors.surfaceHigh,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.textSecondary),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Nomi va narx
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(price.toDouble()),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(lineTotal.toDouble()),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Qty stepper
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _QtyButton(
                    icon: Icons.add,
                    onTap: () => _changeQty(1),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '$_qty',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () => _changeQty(-1),
                    enabled: _qty > 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton(
      {required this.icon, required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.cream.withValues(alpha: 0.12)
              : AppColors.surfaceBright.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled
                ? AppColors.cream
                : AppColors.textMuted.withValues(alpha: 0.4)),
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

  Future<void> _checkout() async {
    HapticFeedback.mediumImpact();
    // To'lov usuli tanlash
    final result = await _showPaymentSheet();
    if (result == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post('/orders', data: {
        'payment_method': result['payment_method'],
        if (result['delivery_address'] != null)
          'delivery_address': result['delivery_address'],
      });
      ref.invalidate(cartProvider);
      if (mounted) {
        await _showSuccessDialog(res.data);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _showPaymentSheet() async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _PaymentSheet(),
    );
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> order) async {
    HapticFeedback.heavyImpact();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SuccessCheckmark(),
              const SizedBox(height: 20),
              const Text(
                'Buyurtma qabul qilindi!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buyurtma raqami: #${order['id'] ?? '—'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              if (order['total'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _formatPrice(double.tryParse(
                            order['total'].toString()) ??
                        0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // cart screenni yopish
                  },
                  child: const Text('Davom etish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _loading ? null : _checkout,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.midnightIndigo,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        icon: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.midnightIndigo),
              )
            : const Icon(Icons.shopping_bag),
        label: Text(
          _loading
              ? 'Yuborilmoqda...'
              : 'Buyurtma berish (${widget.itemCount})',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Success checkmark animatsiyasi ──────────────────────────

class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark();

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
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
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check,
                color: Colors.white, size: 48),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppColors.cream.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Savatcha bo\'sh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Marketplace\'dan o\'zingizga\nyoqqan mahsulotni qo\'shing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.storefront),
              label: const Text('Marketplace\'ga o\'tish'),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: const [
            ShimmerBox(width: 76, height: 76, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 90, height: 12),
                  SizedBox(height: 8),
                  ShimmerBox(width: 80, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── To'lov usuli tanlash ────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _method = 'cash';
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'To\'lov usulini tanlang',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),
            _PayMethod(
              value: 'cash',
              selected: _method,
              icon: Icons.payments_outlined,
              title: 'Naqd pul',
              subtitle: 'Kuryerga qo\'lda to\'lash',
              onTap: () => setState(() => _method = 'cash'),
            ),
            const SizedBox(height: 10),
            _PayMethod(
              value: 'card',
              selected: _method,
              icon: Icons.credit_card_outlined,
              title: 'Plastik karta',
              subtitle: 'Kuryerga POS terminal orqali',
              onTap: () => setState(() => _method = 'card'),
            ),
            const SizedBox(height: 10),
            _PayMethod(
              value: 'payme',
              selected: _method,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payme',
              subtitle: 'Tez orada ishga tushadi',
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Yetkazish manzili',
                hintText: 'Ko\'cha, uy, xonadon raqami',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, {
                  'payment_method': _method,
                  if (_addressCtrl.text.trim().isNotEmpty)
                    'delivery_address': _addressCtrl.text.trim(),
                });
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                'Buyurtma berish',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
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
    final isSelected = value == selected && enabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.cream.withValues(alpha: 0.12)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.cream.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: enabled ? onTap : null,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cream.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isSelected
                  ? AppColors.cream
                  : AppColors.textSecondary,
              size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: enabled
                ? AppColors.textPrimary
                : AppColors.textMuted,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: enabled
            ? Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.cream
                        : AppColors.textMuted,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.cream : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        size: 13, color: AppColors.midnightIndigo)
                    : null,
              )
            : const Text(
                'tez orada',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
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
  return '$buf UZS';
}
