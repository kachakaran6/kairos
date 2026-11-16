/// Type scale tokens for typography.
/// "One hero number per screen" — only one prominent numerical display per screen.
/// Tabular figures for every digit that changes. A countdown must not reflow as it ticks.
///
/// Constraints per AGENTS.md §2: Tabular figures for every digit that changes.
class TypeScaleTokens {
  const TypeScaleTokens._internal();
  static const TypeScaleTokens _instance = TypeScaleTokens._internal();
  factory TypeScaleTokens() => _instance;

  // Type scale steps (increasing size)
  static const double display1 = 96.0;
  static const double display2 = 60.0;
  static const double display3 = 48.0; // hero number size
  static const double display4 = 34.0;
  static const double display5 = 24.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 13.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  // Numerical display - for countdowns, timers, values (tabular figures)
  static const double numericalDisplay = 48.0;
  static const double numericalSmall = 24.0;
}
