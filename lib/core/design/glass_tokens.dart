import 'package:flutter/material.dart';

import 'colour_tokens.dart';

enum GlassIntensity { primary, secondary, subtle }

/// Glassmorphism tokens for Kairos.
///
/// Configures background translucency, backdrop blur, subtle borders,
/// inner highlights, and soft ambient shadows for both light and dark themes.
@immutable
class KairosGlassTokens {
  const KairosGlassTokens({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.subtleBackground,
    required this.primaryBorder,
    required this.secondaryBorder,
    required this.subtleBorder,
    required this.innerHighlight,
    required this.primaryBlur,
    required this.secondaryBlur,
    required this.subtleBlur,
    required this.shadow,
    required this.heroShadow,
  });

  final Color primaryBackground;
  final Color secondaryBackground;
  final Color subtleBackground;

  final Color primaryBorder;
  final Color secondaryBorder;
  final Color subtleBorder;

  final Color innerHighlight;

  final double primaryBlur;
  final double secondaryBlur;
  final double subtleBlur;

  final List<BoxShadow> shadow;
  final List<BoxShadow> heroShadow;

  /// Resolves glass styling based on [intensity].
  Color backgroundFor(GlassIntensity intensity) => switch (intensity) {
    GlassIntensity.primary => primaryBackground,
    GlassIntensity.secondary => secondaryBackground,
    GlassIntensity.subtle => subtleBackground,
  };

  Color borderFor(GlassIntensity intensity) => switch (intensity) {
    GlassIntensity.primary => primaryBorder,
    GlassIntensity.secondary => secondaryBorder,
    GlassIntensity.subtle => subtleBorder,
  };

  double blurFor(GlassIntensity intensity) => switch (intensity) {
    GlassIntensity.primary => primaryBlur,
    GlassIntensity.secondary => secondaryBlur,
    GlassIntensity.subtle => subtleBlur,
  };

  /// Constructs glass tokens dynamically from [KairosColourTokens].
  factory KairosGlassTokens.fromColours(KairosColourTokens c) {
    if (c.isDark) {
      return KairosGlassTokens(
        primaryBackground: c.surfaceElevated.withValues(alpha: 0.72),
        secondaryBackground: c.surface.withValues(alpha: 0.54),
        subtleBackground: c.surface.withValues(alpha: 0.32),
        primaryBorder: Colors.white.withValues(alpha: 0.14),
        secondaryBorder: Colors.white.withValues(alpha: 0.08),
        subtleBorder: Colors.white.withValues(alpha: 0.05),
        innerHighlight: Colors.white.withValues(alpha: 0.06),
        primaryBlur: 20.0,
        secondaryBlur: 14.0,
        subtleBlur: 8.0,
        shadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        heroShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: c.accent.withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      );
    } else {
      return KairosGlassTokens(
        primaryBackground: c.surface.withValues(alpha: 0.82),
        secondaryBackground: c.surface.withValues(alpha: 0.65),
        subtleBackground: c.surfaceElevated.withValues(alpha: 0.45),
        primaryBorder: c.border.withValues(alpha: 0.65),
        secondaryBorder: c.border.withValues(alpha: 0.42),
        subtleBorder: c.border.withValues(alpha: 0.25),
        innerHighlight: Colors.white.withValues(alpha: 0.55),
        primaryBlur: 18.0,
        secondaryBlur: 12.0,
        subtleBlur: 6.0,
        shadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        heroShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: c.accent.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }
  }
}
