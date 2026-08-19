import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/user_name_provider.dart';
import '../addresses/addresses_screen.dart';
import '../auth/auth_providers.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../onboarding/name_screen.dart';
import '../orders/orders_screen.dart';
import 'settings_screen.dart';

const _chevronIconSvg =
    '<svg viewBox="0 0 8 14"><path d="m1 1 6 6-6 6" stroke="#1C1C22" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

/// dc.html `pr` ro'yxati — [label, ikonka SVG path, old plan rangi].
const _rows = <(String, String, Color)>[
  ('Buyurtmalarim', 'M6 3.5h12v17l-2-1.3-2 1.3-2-1.3-2 1.3-2-1.3-2 1.3zM9 8h6M9 11.5h6M9 15h3.5', AppColors.textPrimary),
  ('Savat', 'M5 8h14l-1.2 10.5a2 2 0 0 1-2 1.5H8.2a2 2 0 0 1-2-1.5ZM9 10V6a3 3 0 0 1 6 0v4', AppColors.textPrimary),
  ('Sevimlilar', 'M12 20 4.8 13a4.6 4.6 0 1 1 6.5-6.5l.7.7.7-.7A4.6 4.6 0 1 1 19.2 13Z', AppColors.textMuted),
  ('Manzillarim', 'M12 21c-4-3.8-6-7-6-9.7a6 6 0 1 1 12 0C18 14 16 17.2 12 21ZM9.8 11.2a2.2 2.2 0 1 0 4.4 0a2.2 2.2 0 1 0-4.4 0', AppColors.textPrimary),
  ('Bildirishnomalar', 'M12 3.5a6 6 0 0 0-6 6v3.5L4.5 16h15L18 13V9.5a6 6 0 0 0-6-6ZM9.8 19a2.3 2.3 0 0 0 4.4 0', AppColors.textMuted),
  ('Sozlamalar', 'M4 7h3M11 7h9M4 12h9M17 12h3M4 17h5M13 17h7M7 7a2 2 0 1 0 4 0a2 2 0 1 0-4 0M13 12a2 2 0 1 0 4 0a2 2 0 1 0-4 0M9 17a2 2 0 1 0 4 0a2 2 0 1 0-4 0', AppColors.textMuted),
];

/// Profil — HANDOFF.md 2-bo'lim, 14-band.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    final avatarUrl = user.avatarUrl != null ? '${AppConfig.apiBaseUrl}${user.avatarUrl}' : null;
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final displayName = ref.watch(userNameProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Profil', style: AppTypography.h1),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _avatarBusy ? null : () {
                        HapticFeedback.lightImpact();
                        _startAvatarUpload();
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? Image.network(avatarUrl, fit: BoxFit.cover, width: 54, height: 54)
                              : Center(
                                  child: Text(
                                    (displayName == null || displayName.isEmpty) ? '?' : String.fromCharCode(displayName.runes.first).toUpperCase(),
                                    style: AppTypography.cardTitle.copyWith(fontSize: 20, letterSpacing: 0, color: AppColors.textPrimary),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          pushAppRoute(context, (_) => NameScreen(initialName: displayName, onDone: () => Navigator.pop(context)));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName ?? '', style: AppTypography.cardTitle),
                            const SizedBox(height: 2),
                            Text('Ismni tahrirlash', style: AppTypography.caption.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _Row(icon: _rows[0].$2, fg: _rows[0].$3, label: _rows[0].$1, onTap: () => _go(context, const OrdersScreen())),
                    _Row(icon: _rows[1].$2, fg: _rows[1].$3, label: _rows[1].$1, onTap: () => _go(context, const CartScreen())),
                    _Row(icon: _rows[2].$2, fg: _rows[2].$3, label: _rows[2].$1, onTap: () => _go(context, const FavoritesScreen())),
                    _Row(icon: _rows[3].$2, fg: _rows[3].$3, label: _rows[3].$1, onTap: () => _go(context, const AddressesScreen())),
                    _Row(
                      icon: _rows[4].$2,
                      fg: _rows[4].$3,
                      label: _rows[4].$1,
                      badge: unread > 0 ? unread : null,
                      onTap: () => _go(context, const NotificationsScreen()),
                    ),
                    _Row(icon: _rows[5].$2, fg: _rows[5].$3, label: _rows[5].$1, isLast: true, onTap: () => _go(context, const SettingsScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) => Text(
                    'Fargonam v${snap.data?.version ?? '1.0'} · Farg\'ona vodiysi uchun',
                    style: AppTypography.caption.copyWith(height: null, color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    pushAppRoute(context, (_) => screen);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.fg, required this.label, required this.onTap, this.badge, this.isLast = false});
  final String icon;
  final Color fg;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.input)),
              alignment: Alignment.center,
              child: SvgPicture.string(
                '<svg viewBox="0 0 24 24"><path d="$icon" stroke="#000" stroke-width="1.7" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>',
                width: 19,
                height: 19,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.rowTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w600))),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: Text('$badge', style: AppTypography.small.copyWith(color: Colors.white, fontSize: 10.5)),
              ),
            SvgPicture.string(_chevronIconSvg, width: 8, height: 14),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryDark),
              title: const Text('Kamera'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.success),
              title: const Text('Galereya'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  if (source == null) return;
  final img = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800);
  if (img == null) return;
  try {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(img.path)});
    await ref.read(dioProvider).post('/profile/avatar', data: form);
    await ref.read(authControllerProvider.notifier).refreshMe();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rasm yuklashda xato'), backgroundColor: AppColors.danger),
      );
    }
  }
}
