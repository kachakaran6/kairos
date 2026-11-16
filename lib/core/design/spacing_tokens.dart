/// Spacing tokens based on the 4pt grid.
/// All layout spacing must come from these tokens — no hardcoded numbers in widgets.
/// Constraint per AGENTS.md §6: 4pt spacing grid, 8pt layout grid.
/// No magic spacing numbers — every px must be a token.
/// Spacing tokens based on the 4pt grid.
/// All layout spacing must come from these tokens — no hardcoded numbers in widgets.
///
/// Constraint per AGENTS.md §6: 4pt spacing grid, 8pt layout grid.
/// No magic spacing numbers — every px must be a token.
class SpacingTokens {
  const SpacingTokens._internal();
  static const SpacingTokens instance = SpacingTokens._internal();
  factory SpacingTokens() => instance;

  // 4pt grid spacing values
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double ml = 20;
  static const double l = 24;
  static const double xl = 28;
  static const double xxl = 32;
  static const double xxxl = 40;

  // Touch target minimums per AGENTS.md §2
  static const double touchTargetMin = 44;
  static const double touchTargetAndroid = 48;

  // 8pt layout grid milestones
  static const double layoutGrid8 = 32;
  static const double layoutGrid8Large = 64;

  // Convenience insets
  static const double contrastRatioMinimum = 4.5;
}
