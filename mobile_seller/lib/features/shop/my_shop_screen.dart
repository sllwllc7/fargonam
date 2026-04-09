import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../orders/seller_orders_screen.dart';
import '../products/products_screen.dart';
import 'shop_providers.dart';

class MyShopScreen extends ConsumerWidget {
  const MyShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final shopAsync = ref.watch(myShopProvider);

    return shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (shop) {
          if (shop == null) return _CreateShopForm(user: user);
          return _ShopView(shop: shop);
        },
      );
  }
}

class _ShopView extends StatelessWidget {
  const _ShopView({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  if (shop.description != null) Text(shop.description!),
                  const SizedBox(height: 6),
                  Text('ID: #${shop.id}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.inventory_2),
            label: const Text('Mahsulotlar'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductsScreen(shopId: shop.id)),
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Kelgan buyurtmalar'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateShopForm extends ConsumerStatefulWidget {
  const _CreateShopForm({required this.user});
  final CurrentUser? user;

  @override
  ConsumerState<_CreateShopForm> createState() => _CreateShopFormState();
}

class _CreateShopFormState extends ConsumerState<_CreateShopForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await createShop(ref, name: _nameCtrl.text.trim(), description: _descCtrl.text.trim());
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = widget.user?.role == 'seller' || widget.user?.role == 'admin';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sizda hali do\'kon yo\'q. Yangi yarating:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Do\'kon nomi', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Tavsifi (ixtiyoriy)', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          if (!isSeller) ...[
            const SizedBox(height: 12),
            const Text(
              'Diqqat: sizning rolingiz "seller" emas. Admin orqali rolni o\'zgartirishni so\'rang.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Do\'kon yaratish'),
            ),
          ),
        ],
      ),
    );
  }
}
