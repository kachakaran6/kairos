import 'package:flutter/material.dart';

import '../design/colour_tokens.dart';
import '../design/glass_tokens.dart';
import '../design/type_scale_tokens.dart';

/// Theme extension that carries Kairos tokens through [Theme.of].
///
/// Widgets read colours, glass, and type from here rather than importing token
/// constants, so a theme swap moves every surface at once.
@immutable
class KairosTheme extends ThemeExtension<KairosTheme> {
  KairosTheme({
    required this.colours,
    required this.typeScale,
    KairosGlassTokens? glass,
  }) : glass = glass ?? KairosGlassTokens.fromColours(colours);

  final KairosColourTokens colours;
  final KairosTypeScale typeScale;
  final KairosGlassTokens glass;

  static KairosTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<KairosTheme>();
    assert(theme != null, 'KairosTheme is missing from ThemeData.extensions');
    return theme!;
  }

  @override
  KairosTheme copyWith({
    KairosColourTokens? colours,
    KairosTypeScale? typeScale,
    KairosGlassTokens? glass,
  }) {
    final newColours = colours ?? this.colours;
    return KairosTheme(
      colours: newColours,
      typeScale: typeScale ?? this.typeScale,
      glass:
          glass ??
          (colours != null
              ? KairosGlassTokens.fromColours(newColours)
              : this.glass),
    );
  }

  @override
  KairosTheme lerp(KairosTheme? other, double t) {
    if (other == null) return this;
    final lerpedColours = _lerpColours(colours, other.colours, t);
    return KairosTheme(
      colours: lerpedColours,
      typeScale: t < 0.5 ? typeScale : other.typeScale,
      glass: KairosGlassTokens.fromColours(lerpedColours),
    );
  }

  static KairosColourTokens _lerpColours(
    KairosColourTokens a,
    KairosColourTokens b,
    double t,
  ) {
    Color mix(Color x, Color y) => Color.lerp(x, y, t)!;
    return KairosColourTokens(
      background: mix(a.background, b.background),
      surface: mix(a.surface, b.surface),
      surfaceElevated: mix(a.surfaceElevated, b.surfaceElevated),
      textPrimary: mix(a.textPrimary, b.textPrimary),
      textSecondary: mix(a.textSecondary, b.textSecondary),
      textTertiary: mix(a.textTertiary, b.textTertiary),
      border: mix(a.border, b.border),
      accent: mix(a.accent, b.accent),
      onAccent: mix(a.onAccent, b.onAccent),
      accentMuted: mix(a.accentMuted, b.accentMuted),
      danger: mix(a.danger, b.danger),
      success: mix(a.success, b.success),
      warning: mix(a.warning, b.warning),
      night: mix(a.night, b.night),
      isDark: t < 0.5 ? a.isDark : b.isDark,
    );
  }
}
