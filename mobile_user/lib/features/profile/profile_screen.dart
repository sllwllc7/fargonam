import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../addresses/addresses_screen.dart';
import '../auth/auth_providers.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import 'settings_screen.dart';

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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          children: [
            Text('Profil', style: AppTextStyles.h1.copyWith(fontSize: 28)),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
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
                      width: 54.w,
                      height: 54.w,
                      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? Image.network(avatarUrl, fit: BoxFit.cover, width: 54.w, height: 54.w)
                            : Center(
                                child: Text(
                                  (() {
                                    final s = user.fullName ?? user.phone ?? '';
                                    return s.isEmpty ? '?' : String.fromCharCode(s.runes.first).toUpperCase();
                                  })(),
                                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 20),
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName ?? 'Foydalanuvchi', style: AppTextStyles.cardTitle.copyWith(fontSize: 16.5)),
                        SizedBox(height: 2.h),
                        Text(user.phone ?? '', style: AppTextStyles.caption.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _Row(icon: Icons.receipt_long_outlined, label: 'Buyurtmalarim', onTap: () => _go(context, const OrdersScreen())),
                  _divider,
                  _Row(icon: Icons.shopping_bag_outlined, label: 'Savat', onTap: () => _go(context, const CartScreen())),
                  _divider,
                  _Row(icon: Icons.favorite_outline, label: 'Sevimlilar', onTap: () => _go(context, const FavoritesScreen())),
                  _divider,
                  _Row(icon: Icons.location_on_outlined, label: 'Manzillarim', onTap: () => _go(context, const AddressesScreen())),
                  _divider,
                  _Row(
                    icon: Icons.notifications_outlined,
                    label: 'Bildirishnomalar',
                    badge: unread > 0 ? unread : null,
                    onTap: () => _go(context, const NotificationsScreen()),
                  ),
                  _divider,
                  _Row(icon: Icons.settings_outlined, label: 'Sozlamalar', onTap: () => _go(context, const SettingsScreen())),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) => Text(
                  'Fargonam v${snap.data?.version ?? '1.0'} · Farg\'ona vodiysi uchun',
                  style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

const _divider = Divider(height: 1, color: AppColors.border);

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.badge});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: AppColors.primaryDark, size: 19.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 15))),
            if (badge != null)
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999.r)),
                child: Text('$badge', style: AppTextStyles.small.copyWith(color: Colors.white, fontSize: 10.5)),
              ),
            Icon(Icons.chevron_right, size: 18.sp, color: AppColors.textSecondary),
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
            SizedBox(height: 12.h),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryDark),
              title: const Text('Kamera'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.success),
              title: const Text('Galereya'),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, ImageSource.gallery);
              },
            ),
            SizedBox(height: 8.h),
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
