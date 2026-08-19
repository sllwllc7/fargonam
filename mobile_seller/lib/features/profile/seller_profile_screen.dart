import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              AppSizes.tabBarHeight + AppSizes.tabBarBottomInset,
            ),
            children: [
              Text('Profil', style: AppTypography.h1.copyWith(color: AppColors.primaryDark, fontSize: 28)),
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
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: Center(
                        child: Text(initial, style: AppTypography.h2.copyWith(color: AppColors.textPrimary, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'Sotuvchi', style: AppTypography.cardTitle.copyWith(fontSize: 16.5)),
                          const SizedBox(height: 2),
                          Text(user?.phone ?? '', style: AppTypography.caption.copyWith(fontSize: 13)),
                        ],
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
                child: Column(
                  children: [
                    shopAsync.when(
                      data: (shop) => _Row(
                        icon: Icons.storefront_outlined,
                        label: shop?.name ?? 'Do\'konim',
                        onTap: () => pushAppRoute(context, (_) => const MyShopScreen()),
                      ),
                      loading: () => _Row(icon: Icons.storefront_outlined, label: 'Do\'konim', onTap: () {}),
                      error: (_, _) => _Row(icon: Icons.storefront_outlined, label: 'Do\'konim', onTap: () {}),
                    ),
                    _divider,
                    _Row(
                      icon: Icons.class_outlined,
                      label: 'Sinf to\'plamlari',
                      onTap: () => pushAppRoute(context, (_) => const KitManagementScreen()),
                    ),
                    _divider,
                    _Row(
                      icon: Icons.campaign_outlined,
                      label: 'Yangiliklar',
                      onTap: () => pushAppRoute(context, (_) => const SellerNewsScreen()),
                    ),
                    _divider,
                    _Row(
                      icon: Icons.description_outlined,
                      label: 'Foydalanish shartlari',
                      onTap: () => pushAppRoute(context, (_) => const LegalScreen()),
                    ),
                    _divider,
                    _Row(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Maxfiylik siyosati',
                      onTap: () => pushAppRoute(context, (_) => const LegalScreen(initialTab: 1)),
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
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onLogout();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('Chiqish', style: AppTypography.cardTitleSm.copyWith(color: AppColors.danger)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) => Text(
                    'Fargonam Biznes v${snap.data?.version ?? '1.0'}',
                    style: AppTypography.small.copyWith(color: AppColors.textSecondary),
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

const _divider = Divider(height: 1, color: AppColors.border);

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.cardTitleSm)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
