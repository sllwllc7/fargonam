/// Fargonam umumiy dizayn tizimi — `handoff/Fargonam User App v2.dc.html`
/// (md5 b3bc28ca50648663ea83630fb9de04ae) dan tasdiqlangan.
///
/// `mobile_user` va `mobile_seller` shu paketdan foydalanadi — bitta manba,
/// ikkala ilova bir xil ko'rinishda bo'lishini kafolatlaydi.
library;

export 'src/app_colors.dart';
export 'src/app_gradients.dart';
export 'src/app_motion.dart';
export 'src/app_page_route.dart';
export 'src/app_radius.dart';
export 'src/app_shadows.dart';
export 'src/app_spacing.dart';
export 'src/app_theme.dart';
export 'src/app_typography.dart';
export 'src/widgets/back_circle_button.dart';
export 'src/widgets/cart_fab.dart';
export 'src/widgets/error_retry.dart';
export 'src/widgets/fade_up_item.dart';
export 'src/widgets/favorite_heart_icon.dart';
export 'src/widgets/floating_tab_bar.dart';
export 'src/widgets/format.dart';
export 'src/widgets/guarded_action.dart';
export 'src/widgets/pressable_scale.dart';
export 'src/widgets/screen_fade_in.dart';
export 'src/widgets/shimmer_box.dart';
export 'src/widgets/toast.dart';

// `theme/legacy_tokens.dart` ATAYLAB shu yerdan eksport qilinmaydi — faqat
// mobile_seller va mobile_user'ning bir nechta hali tuzatilmagan fayli
// to'g'ridan-to'g'ri import qiladi (izoh o'sha faylning boshida).
