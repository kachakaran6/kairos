import 'package:flutter/widgets.dart';

/// Design tokens for the Kairos 3D Earth Globe ("Obsidian & Ember").
/// Complies with AGENTS.md §2: Tokens only, no hardcoded hex in presentation code.
abstract final class GlobeTokens {
  // Dark Mode Palette ("Obsidian & Ember")
  static const Color darkOceanTop = Color(0xFF1E1A17);
  static const Color darkOceanMid = Color(0xFF110F0E);
  static const Color darkOceanDeep = Color(0xFF090807);
  static const Color darkNightLandDots = Color(0xFF38322E);
  static const Color defaultAccentTerracotta = Color(0xFFE8895A);

  // Light Mode Palette ("Editorial Ink on Linen")
  static const Color lightOceanTop = Color(0xFFFCFAF6);
  static const Color lightOceanMid = Color(0xFFF3EEE7);
  static const Color lightOceanDeep = Color(0xFFE5DFD7);
  static const Color lightNightLandDots = Color(0xFF756C64);
  static const Color lightDayLandDots = Color(0xFF2E2824);

  // Celestial Accents & UI Elements
  static const Color starTwinkle = Color(0xFFF4EFE8);
  static const Color cityLightsAmber = Color(0xFFFFD166);
  static const Color chipTextDark = Color(0xFFF4EFE8);
  static const Color chipTextLight = Color(0xFF14120E);
  static const Color chipBackgroundDark = Color(0xFF181513);
  static const Color pillBackgroundDark = Color(0xFF1E1C1A);
}
