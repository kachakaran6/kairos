import 'package:flutter/material.dart';

/// Elevation / shadow tokens for widget shadows.
/// All elevation values and shadows must come from these tokens — no hardcoded shadows in widgets.
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

  // Shadow and thematic special colors
  static const Color shadowDark = Color(0x33000000);
  static const Color shadowLight = Color(0x0A1A1714);
  static const Color shadowSubtle = Color(0x20000000);
  static const Color navShadowDark = Color(0x40000000);
  static const Color navShadowLight = Color(0x121A1714);
  static const Color goldCelebration = Color(0xFFD4AF37);
  static const Color globeNightDark = Color(0xFF080605);
  static const Color globeNightLight = Color(0xFF1E1A17);
}
