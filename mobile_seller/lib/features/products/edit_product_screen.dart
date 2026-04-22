import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import 'products_providers.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() =>
      _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  XFile? _newImage;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl =
        TextEditingController(text: widget.product.description ?? '');
    _priceCtrl = TextEditingController(text: widget.product.price);
    _stockCtrl =
        TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _newImage = img);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(dioProvider)
          .patch('/products/${widget.product.id}', data: {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'stock': int.parse(_stockCtrl.text.trim()),
      });
      if (_newImage != null) {
        await uploadProductImage(ref,
            productId: widget.product.id, filePath: _newImage!.path);
      }
      ref.invalidate(shopProductsProvider(widget.product.shopId));
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error =
          e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tahrirlash')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rasm tanlash
            GestureDetector(
              onTap: _loading ? null : _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_newImage != null)
                      Image.file(File(_newImage!.path), fit: BoxFit.cover)
                    else if (widget.product.imageUrl != null)
                      Image.network(
                        '${AppConfig.apiBaseUrl}${widget.product.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: AppColors.textMuted),
                      )
                    else
                      const Icon(Icons.image_outlined,
                          size: 48, color: AppColors.textMuted),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Rasmni o\'zgartirish',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nomi',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nom kiritish shart';
                if (v.trim().length < 2) return 'Kamida 2 ta belgi';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Tavsif (ixtiyoriy)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Narx (so\'m)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Narx > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Soni',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return '≥ 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.midnightIndigo),
                      )
                    : const Text(
                        'Saqlash',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
