/// Corner radius tokens for widget corners.
/// All radii must come from these tokens — no hardcoded radii in widgets.
///
/// Constraint per AGENTS.md §6: Token-only — no magic numbers.
class RadiusTokens {
  const RadiusTokens._internal();
  static const RadiusTokens _instance = RadiusTokens._internal();
  factory RadiusTokens() => _instance;

  // Radii values (all multiples of 4pt grid)
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double circle = 9999; // effectively infinite for pills/avatars
}
