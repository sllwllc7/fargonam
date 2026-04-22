import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../main.dart';
import '../auth/auth_providers.dart';
import '../addresses/addresses_screen.dart';
import '../favorites/favorites_screen.dart';
import '../help/help_screen.dart';
import '../legal/legal_screen.dart';
import '../orders/orders_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // FIX: Global _actionBusy o'rniga instance-level busy flag
  bool _avatarBusy = false;

  Future<void> _startAvatarUpload() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      await _pickAndUploadAvatar(context, ref);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    final avatarUrl = user.avatarUrl != null
        ? '${AppConfig.apiBaseUrl}${user.avatarUrl}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar + ism kartochka ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.surfaceHigh],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _avatarBusy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _startAvatarUpload();
                        },
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.cream, AppColors.creamDim],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cream
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? AppCachedImage(
                                  url: avatarUrl,
                                  width: 90,
                                  height: 90,
                                  borderRadius: 0,
                                )
                              : Container(
                                  color: AppColors.surfaceHigh,
                                  alignment: Alignment.center,
                                  child: Text(
                                    () {
                                      final s = user.fullName ?? user.phone;
                                      if (s.isEmpty) return '?';
                                      return String.fromCharCode(s.runes.first).toUpperCase();
                                    }(),
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.bg, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: AppColors.midnightIndigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName ?? 'Foydalanuvchi',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Sozlamalar bo'limi ──
          const _SectionLabel('Buyurtmalar'),
          _MenuItem(
            icon: Icons.receipt_long,
            title: 'Buyurtmalarim',
            iconColor: AppColors.cream,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OrdersScreen()));
            },
          ),
          _MenuItem(
            icon: Icons.favorite_border,
            title: 'Sevimlilar',
            iconColor: AppColors.error,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FavoritesScreen()));
            },
          ),
          _MenuItem(
            icon: Icons.location_on_outlined,
            title: 'Manzillarim',
            iconColor: AppColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddressesScreen()));
            },
          ),
          _MenuItem(
            icon: Icons.local_taxi_outlined,
            title: 'Sayohat tarixim',
            iconColor: AppColors.warning,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _RideHistoryScreen()));
            },
          ),

          const SizedBox(height: 16),
          const _SectionLabel('Hisob'),
          _MenuItem(
            icon: Icons.edit,
            title: 'Ismni o\'zgartirish',
            iconColor: AppColors.info,
            onTap: () {
              HapticFeedback.lightImpact();
              _showEditNameSheet(context, user.fullName);
            },
          ),
          // OTP login ishlatilsa parol yo'q — bu menyu keraksiz
          // Faqat eski parol bilan kirgan foydalanuvchilarga ko'rsatamiz

          const SizedBox(height: 16),
          const _SectionLabel('Sozlamalar'),
          // Dark mode
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: SwitchListTile(
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dark_mode,
                    color: AppColors.cream, size: 22),
              ),
              title: const Text('Tungi rejim',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              activeThumbColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).setDark(v);
              },
            ),
          ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Yordam',
            iconColor: AppColors.info,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()));
            },
          ),
          _MenuItem(
            icon: Icons.description_outlined,
            title: 'Foydalanish shartlari',
            iconColor: AppColors.textMuted,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LegalScreen()));
            },
          ),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Maxfiylik siyosati',
            iconColor: AppColors.textMuted,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LegalScreen(initialTab: 1)));
            },
          ),

          const SizedBox(height: 28),

          // Chiqish
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Chiqish',
              style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Fargonam v0.1.0',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Chiqishni tasdiqlang'),
        content: const Text(
          'Hisobingizdan chiqmoqchimisiz?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _showEditNameSheet(
      BuildContext context, String? currentName) async {
    final ctrl = TextEditingController(text: currentName ?? '');
    bool loading = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ismni o\'zgartirish',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Ismingiz',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final newName = ctrl.text.trim();
                          if (newName.length < 2) {
                            setSheetState(
                                () => error = 'Kamida 2 belgi');
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          setSheetState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            await ref.read(dioProvider).patch(
                                '/auth/me',
                                data: {'full_name': newName});
                            await ref
                                .read(authControllerProvider.notifier)
                                .tryAutoLogin();
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setSheetState(() {
                              error = 'Xato: $e';
                              loading = false;
                            });
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.midnightIndigo),
                        )
                      : const Text('Saqlash',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Menu Item ──

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon,
                    color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textMuted.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Avatar upload
// ══════════════════════════════════════════════════════════════

Future<void> _pickAndUploadAvatar(
    BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.cream),
              ),
              title: const Text('Kamera'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library,
                    color: AppColors.success),
              ),
              title: const Text('Galereya'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
  if (source == null) return;

  final picker = ImagePicker();
  final file = await picker.pickImage(
      source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
  if (file == null) return;

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path, filename: file.name),
  });

  try {
    await ref.read(dioProvider).post('/profile/avatar', data: formData);
    await ref.read(authControllerProvider.notifier).tryAutoLogin();
    HapticFeedback.lightImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Avatar yangilandi!'),
            backgroundColor: AppColors.success),
      );
    }
  } on DioException catch (e) {
    HapticFeedback.heavyImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.error),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════
// Change password
// ══════════════════════════════════════════════════════════════

class _ChangePasswordScreen extends ConsumerStatefulWidget {
  const _ChangePasswordScreen();
  @override
  ConsumerState<_ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<_ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  String? _error;
  bool _success = false;
  double _strength = 0;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  double _calcStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.2;
    if (p.length >= 8) s += 0.15;
    if (p.length >= 12) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[a-z]').hasMatch(p)) s += 0.1;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.1;
    return s.clamp(0.0, 1.0);
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (_oldCtrl.text.isEmpty || _newCtrl.text.length < 6) {
      setState(() => _error = 'Yangi parol kamida 6 belgi');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });
    try {
      await ref.read(dioProvider).post(
        '/auth/change-password',
        data: {
          'old_password': _oldCtrl.text,
          'new_password': _newCtrl.text,
        },
      );
      HapticFeedback.lightImpact();
      setState(() {
        _success = true;
        _oldCtrl.clear();
        _newCtrl.clear();
        _strength = 0;
      });
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
      appBar: AppBar(
        title: const Text('Parolni o\'zgartirish'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _oldCtrl,
            obscureText: _obscureOld,
            decoration: InputDecoration(
              labelText: 'Eski parol',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureOld
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscureOld = !_obscureOld);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newCtrl,
            obscureText: _obscureNew,
            onChanged: (v) =>
                setState(() => _strength = _calcStrength(v)),
            decoration: InputDecoration(
              labelText: 'Yangi parol',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscureNew = !_obscureNew);
                },
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _newCtrl.text.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween:
                                  Tween(begin: 0, end: _strength),
                              duration:
                                  const Duration(milliseconds: 300),
                              builder: (_, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                backgroundColor:
                                    AppColors.surfaceHigh,
                                color: _strength < 0.4
                                    ? AppColors.error
                                    : _strength < 0.7
                                        ? AppColors.warning
                                        : AppColors.success,
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _strength < 0.4
                              ? 'Zaif'
                              : _strength < 0.7
                                  ? 'O\'rtacha'
                                  : 'Kuchli',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _strength < 0.4
                                ? AppColors.error
                                : _strength < 0.7
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: !_success
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.success, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Parol muvaffaqiyatli o\'zgartirildi!',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
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
                  : const Text('O\'zgartirish',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Ride history
// ══════════════════════════════════════════════════════════════

final _rideHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/rides/my');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class _RideHistoryScreen extends ConsumerWidget {
  const _RideHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(_rideHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Sayohat tarixim'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ridesAsync.when(
        loading: () => const _RidesSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(_rideHistoryProvider)),
        data: (rides) {
          if (rides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.local_taxi_outlined,
                          size: 48, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hali sayohat yo\'q',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Birinchi taksingizni chaqiring',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(_rideHistoryProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _RideHistoryCard(ride: rides[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.ride});
  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String;
    final (label, color) = switch (status) {
      'completed' => ('Tugadi', AppColors.success),
      'cancelled' => ('Bekor', AppColors.error),
      'searching' => ('Qidirilmoqda', AppColors.warning),
      'in_progress' => ('Yo\'lda', AppColors.info),
      'accepted' => ('Qabul qilindi', AppColors.info),
      'arrived' => ('Yetib keldi', AppColors.success),
      _ => (status, AppColors.textSecondary),
    };

    final fareStr = ride['fare']?.toString();
    final fare = fareStr != null ? double.tryParse(fareStr) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${ride['id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle),
                  ),
                  Container(
                      width: 1, height: 22, color: AppColors.divider),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride['pickup_address'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 14),
                    Text(ride['destination_address'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          if (fare != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 18, color: AppColors.cream),
                const SizedBox(width: 6),
                Text(
                  _formatPrice(fare),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RidesSkeleton extends StatelessWidget {
  const _RidesSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: 60, height: 14),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 12),
            SizedBox(height: 8),
            ShimmerBox(width: 220, height: 12),
            SizedBox(height: 14),
            ShimmerBox(width: 100, height: 16),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
