import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hapticProvider = StateNotifierProvider<HapticNotifier, bool>((ref) {
  return HapticNotifier();
});

class HapticNotifier extends StateNotifier<bool> {
  HapticNotifier() : super(true) {
    _loadState();
  }

  static const _key = 'haptic_enabled';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (_) {}
  }

  Future<void> toggleHaptic() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, state);
    } catch (_) {}
  }
}
