import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final privacyProvider = StateNotifierProvider<PrivacyNotifier, bool>((ref) {
  return PrivacyNotifier();
});

class PrivacyNotifier extends StateNotifier<bool> {
  PrivacyNotifier() : super(false) {
    _loadState();
  }

  static const _key = 'hide_balance';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  Future<void> toggleHideBalance() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, state);
    } catch (_) {}
  }
}
