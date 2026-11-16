/// Elevation / shadow tokens for widget shadows.
/// All elevation values must come from these tokens — no hardcoded shadows in widgets.
///
/// Constraint per AGENTS.md §6: Token-only — no magic numbers.
class ElevationTokens {
  const ElevationTokens._internal();
  static const ElevationTokens _instance = ElevationTokens._internal();
  factory ElevationTokens() => _instance;

  // Elevation values (in dp)
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 2;
  static const double level3 = 4;
  static const double level4 = 8;
  static const double level5 = 16;
}
