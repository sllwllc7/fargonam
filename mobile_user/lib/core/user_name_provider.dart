import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUserNameKey = 'user_display_name';

/// Foydalanuvchi kiritgan ism — faqat lokal (`shared_preferences`).
/// Backend'da hali profil-tahrirlash endpoint'i yo'q (5-bosqichda OTP bilan
/// birga qo'shiladi) — shuning uchun bu qadam qurilma darajasida saqlanadi.
class UserNameNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kUserNameKey);
    return (name == null || name.trim().isEmpty) ? null : name.trim();
  }

  Future<void> save(String name) async {
    final trimmed = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserNameKey, trimmed);
    state = AsyncData(trimmed);
  }
}

final userNameProvider = AsyncNotifierProvider<UserNameNotifier, String?>(UserNameNotifier.new);
