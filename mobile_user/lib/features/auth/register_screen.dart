import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
          _phoneCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    final user = ref.read(authControllerProvider).user;
    if (user != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Yangi hisob', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text('Fargonam\'ga qo\'shiling', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Ismingiz', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon raqam', hintText: '+998...', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 9) ? 'Telefon kiriting' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'Parol',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) => (v == null || v.length < 6) ? 'Kamida 6 belgi' : null,
              ),

              if (state.error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(state.error!, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),

              FilledButton(
                onPressed: state.loading ? null : _submit,
                child: state.loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Ro\'yxatdan o\'tish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
