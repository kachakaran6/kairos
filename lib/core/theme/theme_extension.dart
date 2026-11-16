import 'package:flutter/material.dart';

import '../design/colour_tokens.dart';
import '../design/type_scale_tokens.dart';

/// Theme extension that carries Kairos tokens through [Theme.of].
///
/// Widgets read colours and type from here rather than importing token
/// constants, so a theme swap moves every surface at once.
@immutable
class KairosTheme extends ThemeExtension<KairosTheme> {
  const KairosTheme({required this.colours, required this.typeScale});

  final KairosColourTokens colours;
  final KairosTypeScale typeScale;

  static KairosTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<KairosTheme>();
    assert(theme != null, 'KairosTheme is missing from ThemeData.extensions');
    return theme!;
  }

  @override
  KairosTheme copyWith({
    KairosColourTokens? colours,
    KairosTypeScale? typeScale,
  }) {
    return KairosTheme(
      colours: colours ?? this.colours,
      typeScale: typeScale ?? this.typeScale,
    );
  }

  @override
  KairosTheme lerp(KairosTheme? other, double t) {
    if (other == null) return this;
    return KairosTheme(
      colours: _lerpColours(colours, other.colours, t),
      typeScale: t < 0.5 ? typeScale : other.typeScale,
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
      isDark: t < 0.5 ? a.isDark : b.isDark,
    );
  }
}
