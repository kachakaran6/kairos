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

  /// Dark palette: True-warm near-black (#0F0D0B) with surface steps.
  static const KairosColourTokens dark = KairosColourTokens(
    background: Color(0xFF0F0D0B),
    surface: Color(0xFF17140F),
    surfaceElevated: Color(0xFF1F1B16),
    textPrimary: Color(0xFFF4EFE8),
    textSecondary: Color(0xFF9E968D),
    textTertiary: Color(0xFF5C554D),
    border: Color(0x1FFFFFFF), // Hairline border
    accent: Color(0xFFE8895A),
    onAccent: Color(0xFF0F0D0B),
    accentMuted: Color(0x1FE8895A), // 12% tint
    danger: Color(0xFFD9534F),
    success: Color(0xFF5C9E75),
    warning: Color(0xFFE8895A),
    night: Color(0xFF4A5A7A),
    isDark: true,
  );

  /// Light palette: Warm paper background (#FAF7F2), raised surface (#FFFFFF).
  static const KairosColourTokens light = KairosColourTokens(
    background: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF2ECE4),
    textPrimary: Color(0xFF1A1714),
    textSecondary: Color(0xFF6B645C),
    textTertiary: Color(0xFF9C948A),
    border: Color(0x141A1714), // Ink at 8% opacity
    accent: Color(0xFFB5532D),
    onAccent: Color(0xFFFFFFFF),
    accentMuted: Color(0x1FB5532D), // 12% tint
    danger: Color(0xFFBA382E),
    success: Color(0xFF3D7857),
    warning: Color(0xFFB5532D),
    night: Color(0xFF3B4E6B),
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
      onAccent: isDark ? const Color(0xFF0F0D0B) : Colors.white,
      accentMuted: newAccent.withValues(alpha: 0.12),
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
