import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola pengaturan ambang batas peringatan anggaran (budget warning thresholds).
/// Menampung Set berisi persentase peringatan aktif (50, 70, 90).
final budgetSettingsProvider = StateNotifierProvider<BudgetSettingsNotifier, Set<int>>((ref) {
  return BudgetSettingsNotifier();
});

class BudgetSettingsNotifier extends StateNotifier<Set<int>> {
  BudgetSettingsNotifier() : super({50, 70, 90}) {
    _loadState();
  }

  static const _key = 'budget_thresholds';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      if (list != null) {
        state = list.map((e) => int.parse(e)).toSet();
      }
    } catch (_) {
      // Fallback ke default jika terjadi kegagalan
      state = {50, 70, 90};
    }
  }

  /// Menyalakan/mematikan salah satu ambang batas peringatan
  Future<void> toggleThreshold(int threshold) async {
    final updated = Set<int>.from(state);
    if (updated.contains(threshold)) {
      updated.remove(threshold);
    } else {
      updated.add(threshold);
    }
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, updated.map((e) => e.toString()).toList());
    } catch (_) {}
  }
}
