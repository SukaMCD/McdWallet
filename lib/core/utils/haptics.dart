import 'package:flutter/services.dart';

/// Helper class to trigger haptic feedback conditionally based on the global user setting.
class AppHaptics {
  /// Global state to enable or disable haptic feedback.
  /// Typically synced with the Riverpod `hapticProvider` in the app's root.
  static bool enabled = true;

  static Future<void> lightImpact() async {
    if (enabled) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  static Future<void> mediumImpact() async {
    if (enabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  static Future<void> heavyImpact() async {
    if (enabled) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  static Future<void> selectionClick() async {
    if (enabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  static Future<void> vibrate() async {
    if (enabled) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }
}
