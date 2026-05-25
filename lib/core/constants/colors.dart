import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ──
  static const Color background = Color(0xFFF4F5F7);       // Elegant Off-white
  static const Color surface = Color(0xFFFFFFFF);           // White (cards)
  static const Color surfaceAlt = Color(0xFFEBEBF0);       // Light gray (layered)
  static const Color bottomNavBg = Color(0xFFFFFFFF);

  // ── Brand / Accent ──
  static const Color primary = Color(0xFF1C1C1E);           // Sleek black/charcoal
  static const Color secondary = Color(0xFF8E8E93);         // Silver/gray
  static const Color accent = Color(0xFF1C1C1E);            // Accent black

  // ── Text ──
  static const Color textPrimary = Color(0xFF1C1C1E);       // Dark gray/black
  static const Color textSecondary = Color(0xFF636366);     // Darker silver/gray for readability
  static const Color textMuted = Color(0xFF8E8E93);         // Silver-gray

  // ── Financial States ──
  static const Color income = Color(0xFF34C759);            // Apple Green
  static const Color expense = Color(0xFFFF3B30);           // Apple Red
  static const Color transfer = Color(0xFF8E8E93);          // Silver

  // ── Status ──
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color danger = Color(0xFFFF3B30);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFE5E5EA);            // Subtle gray border
  static const Color divider = Color(0xFFF2F2F7);

  // ── Gradients ──
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
