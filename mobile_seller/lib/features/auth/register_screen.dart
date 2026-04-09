import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'auth_providers.dart';

class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});
  @override
  ConsumerState<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends ConsumerState<SellerRegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/auth/register', data: {
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'full_name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'role': 'seller',
      });
      final token = res.data['access_token'] as String;
      await ref.read(secureStorageProvider).write(key: 'access_token', value: token);
      // Auth controller'ga xabar berish
      await ref.read(authControllerProvider.notifier).tryAutoLogin();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sotuvchi ro\'yxatdan o\'tish')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'To\'liq ism', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon', hintText: '+998...', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 9) ? 'Telefon kiriting' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Parol', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Kamida 6 belgi' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Ro\'yxatdan o\'tish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
