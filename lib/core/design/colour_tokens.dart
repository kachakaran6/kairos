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
    required this.night,
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
  final Color night;
  final bool isDark;

  /// Default canvas: #0C0C0F, warm off-white text: #E8E4DC.
  static const KairosColourTokens dark = KairosColourTokens(
    background: Color(0xFF0C0C0F),
    surface: Color(0xFF141418),
    surfaceElevated: Color(0xFF1B1B20),
    textPrimary: Color(0xFFF5F2EE),
    textSecondary: Color(0xFFA8A4A0),
    textTertiary: Color(0xFF6E6A67),
    border: Color(0xFF2A2A31),
    accent: Color(0xFFE9A97B),
    onAccent: Color(0xFF0C0C0F),
    accentMuted: Color(0xFF3A2A22),
    danger: Color(0xFFC2453C),
    success: Color(0xFF7FB3A3),
    warning: Color(0xFFE9A97B),
    night: Color(0xFF5A6B8C),
    isDark: true,
  );

  /// Paper-like light mode from the Ink theme: #FBFAF7 / #1B1B1E.
  static const KairosColourTokens light = KairosColourTokens(
    background: Color(0xFFFBFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF1EEE8),
    textPrimary: Color(0xFF17171A),
    textSecondary: Color(0xFF5E5A55),
    textTertiary: Color(0xFF8A857E),
    border: Color(0xFFE4E0D8),
    accent: Color(0xFFA9552B),
    onAccent: Color(0xFFFBFAF7),
    accentMuted: Color(0xFFEDE5DD),
    danger: Color(0xFFC2453C),
    success: Color(0xFF7FB3A3),
    warning: Color(0xFFA9552B),
    night: Color(0xFF4A5A7A),
    isDark: false,
  );

  /// Creates a copy with an updated accent color.
  KairosColourTokens withAccent(Color newAccent) {
    return KairosColourTokens(
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      border: border,
      accent: newAccent,
      onAccent: onAccent,
      accentMuted: accentMuted,
      danger: danger,
      success: success,
      warning: warning,
      night: night,
      isDark: isDark,
    );
  }

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
