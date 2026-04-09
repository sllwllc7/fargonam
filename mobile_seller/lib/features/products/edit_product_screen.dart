import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'products_providers.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description ?? '');
    _priceCtrl = TextEditingController(text: widget.product.price);
    _stockCtrl = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioProvider).patch('/products/${widget.product.id}', data: {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'stock': int.parse(_stockCtrl.text.trim()),
      });
      ref.invalidate(shopProductsProvider(widget.product.shopId));
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mahsulotni tahrirlash')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nomi', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Tavsif', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Narx', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: TextField(controller: _stockCtrl, decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
