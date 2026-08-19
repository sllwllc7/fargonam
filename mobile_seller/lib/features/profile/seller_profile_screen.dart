import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:fargonam_ui/theme/legacy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../auth/auth_providers.dart';
import '../kits/kit_management_screen.dart';
import '../legal/legal_screen.dart';
import '../news/seller_news_screen.dart';
import '../shop/my_shop_screen.dart';
import '../shop/shop_providers.dart';

/// Seller App "Profil" — HANDOFF.md 4-bo'lim: do'kon nomi, sozlamalar, chiqish.
/// User App profile_screen.dart bilan bir xil uslub (avatar karta + qator menyu).
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final shopAsync = ref.watch(myShopProvider);
    final initial = (user?.fullName?.isNotEmpty == true ? user!.fullName![0] : 'S').toUpperCase();

    return Scaffold(
      backgroundColor: LegacyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          children: [
            Text('Profil', style: LegacyTextStyles.h1.copyWith(color: LegacyColors.primaryDark, fontSize: 28)),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: LegacyColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: LegacyColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                    child: Center(
                      child: Text(initial,
                          style: LegacyTextStyles.h2.copyWith(color: LegacyColors.text, fontSize: 20)),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Sotuvchi', style: LegacyTextStyles.cardTitle.copyWith(fontSize: 16.5)),
                        SizedBox(height: 2.h),
                        Text(user?.phone ?? '', style: LegacyTextStyles.caption.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: LegacyColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: LegacyColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  shopAsync.when(
                    data: (shop) => _Row(
                      icon: Icons.storefront_outlined,
                      label: shop?.name ?? 'Do\'konim',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyShopScreen())),
                    ),
                    loading: () => _Row(icon: Icons.storefront_outlined, label: 'Do\'konim', onTap: () {}),
                    error: (_, _) => _Row(icon: Icons.storefront_outlined, label: 'Do\'konim', onTap: () {}),
                  ),
                  _divider,
                  _Row(
                    icon: Icons.class_outlined,
                    label: 'Sinf to\'plamlari',
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KitManagementScreen())),
                  ),
                  _divider,
                  _Row(
                    icon: Icons.campaign_outlined,
                    label: 'Yangiliklar',
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerNewsScreen())),
                  ),
                  _divider,
                  _Row(
                    icon: Icons.description_outlined,
                    label: 'Foydalanish shartlari',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                  ),
                  _divider,
                  _Row(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Maxfiylik siyosati',
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LegalScreen(initialTab: 1))),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: LegacyColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: LegacyColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onLogout();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Center(
                    child: Text('Chiqish', style: LegacyTextStyles.cardTitleSm.copyWith(color: LegacyColors.danger)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) => Text(
                  'Fargonam Biznes v${snap.data?.version ?? '1.0'}',
                  style: LegacyTextStyles.small.copyWith(color: LegacyColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _divider = Divider(height: 1, color: LegacyColors.border);

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: LegacyColors.text, size: 19.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: LegacyTextStyles.cardTitleSm)),
            Icon(Icons.chevron_right, size: 18.sp, color: LegacyColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
