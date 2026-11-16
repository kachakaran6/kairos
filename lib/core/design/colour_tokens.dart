import 'package:flutter/material.dart';

/// Colour tokens for Kairos.
///
/// Dark is the default canvas. Light is a designed parallel palette, not an
/// inversion. Values come from the product specification, section 4 and 9.
@immutable
class KairosColourTokens {
  const KairosColourTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.accentMuted,
    required this.danger,
    required this.success,
    required this.warning,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color accentMuted;
  final Color danger;
  final Color success;
  final Color warning;
  final bool isDark;

  /// Default canvas: #0C0C0F, warm off-white text: #E8E4DC.
  static const KairosColourTokens dark = KairosColourTokens(
    background: Color(0xFF0C0C0F),
    surface: Color(0xFF141419),
    surfaceElevated: Color(0xFF1C1C23),
    textPrimary: Color(0xFFE8E4DC),
    textSecondary: Color(0xFFA8A49C),
    textTertiary: Color(0xFF6F6B65),
    border: Color(0xFF2A2A31),
    accent: Color(0xFFE8E4DC),
    onAccent: Color(0xFF0C0C0F),
    accentMuted: Color(0xFF3A3A42),
    danger: Color(0xFFE05B52),
    success: Color(0xFF6FCF97),
    warning: Color(0xFFE9A97B),
    isDark: true,
  );

  /// Paper-like light mode from the Ink theme: #FBFAF7 / #1B1B1E.
  static const KairosColourTokens light = KairosColourTokens(
    background: Color(0xFFFBFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF3EFE7),
    textPrimary: Color(0xFF1B1B1E),
    textSecondary: Color(0xFF5C5A56),
    textTertiary: Color(0xFF8A8782),
    border: Color(0xFFDDD8CE),
    accent: Color(0xFF1B1B1E),
    onAccent: Color(0xFFFBFAF7),
    accentMuted: Color(0xFFE7E2D8),
    danger: Color(0xFFB3261E),
    success: Color(0xFF1E7A4A),
    warning: Color(0xFF8A5A1F),
    isDark: false,
  );

  /// Contrast ratio of [foreground] on [background] per WCAG 2.1.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Body text contrast for this palette.
  double get bodyContrast => contrastRatio(textPrimary, background);

  /// Secondary text contrast for this palette.
  double get secondaryContrast => contrastRatio(textSecondary, background);

  /// Accent contrast for this palette.
  double get accentContrast => contrastRatio(accent, background);
}
