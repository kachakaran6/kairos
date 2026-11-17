import 'package:flutter/material.dart';

import '../../../core/design/widget_tokens.dart';

/// Predefined curated styling themes for Kairos home screen widgets.
class WidgetLook {
  const WidgetLook({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
    this.isDark = false,
  });

  final String id;
  final String name;
  final String description;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final bool isDark;

  static const List<WidgetLook> all = <WidgetLook>[
    WidgetLook(
      id: 'terracotta_paper',
      name: 'Terracotta Paper',
      description:
          'Warm paper with rich terracotta accent & deep ink typography.',
      backgroundColor: WidgetTokens.terracottaPaperBackground,
      surfaceColor: WidgetTokens.terracottaPaperSurface,
      accentColor: WidgetTokens.terracottaPaperAccent,
      primaryTextColor: WidgetTokens.terracottaPaperPrimaryText,
      secondaryTextColor: WidgetTokens.terracottaPaperSecondaryText,
      borderColor: WidgetTokens.terracottaPaperBorder,
      isDark: false,
    ),
    WidgetLook(
      id: 'midnight_ink',
      name: 'Midnight Ink',
      description: 'True-warm obsidian black with vibrant sunrise terracotta.',
      backgroundColor: WidgetTokens.midnightInkBackground,
      surfaceColor: WidgetTokens.midnightInkSurface,
      accentColor: WidgetTokens.midnightInkAccent,
      primaryTextColor: WidgetTokens.midnightInkPrimaryText,
      secondaryTextColor: WidgetTokens.midnightInkSecondaryText,
      borderColor: WidgetTokens.midnightInkBorder,
      isDark: true,
    ),
    WidgetLook(
      id: 'sakura',
      name: 'Sakura',
      description: 'Delicate blossom rose on gentle porcelain canvas.',
      backgroundColor: WidgetTokens.sakuraBackground,
      surfaceColor: WidgetTokens.sakuraSurface,
      accentColor: WidgetTokens.sakuraAccent,
      primaryTextColor: WidgetTokens.sakuraPrimaryText,
      secondaryTextColor: WidgetTokens.sakuraSecondaryText,
      borderColor: WidgetTokens.sakuraBorder,
      isDark: false,
    ),
    WidgetLook(
      id: 'forest_quiet',
      name: 'Forest Quiet',
      description: 'Deep evergreen shadows and tranquil birch highlights.',
      backgroundColor: WidgetTokens.forestQuietBackground,
      surfaceColor: WidgetTokens.forestQuietSurface,
      accentColor: WidgetTokens.forestQuietAccent,
      primaryTextColor: WidgetTokens.forestQuietPrimaryText,
      secondaryTextColor: WidgetTokens.forestQuietSecondaryText,
      borderColor: WidgetTokens.forestQuietBorder,
      isDark: true,
    ),
    WidgetLook(
      id: 'mono_graphite',
      name: 'Mono Graphite',
      description:
          'Architectural precision in monochrome obsidian & crisp white.',
      backgroundColor: WidgetTokens.monoGraphiteBackground,
      surfaceColor: WidgetTokens.monoGraphiteSurface,
      accentColor: WidgetTokens.monoGraphiteAccent,
      primaryTextColor: WidgetTokens.monoGraphitePrimaryText,
      secondaryTextColor: WidgetTokens.monoGraphiteSecondaryText,
      borderColor: WidgetTokens.monoGraphiteBorder,
      isDark: true,
    ),
    WidgetLook(
      id: 'sunset_glass',
      name: 'Sunset Glass',
      description: 'Translucent warm amber glow over dusk horizon.',
      backgroundColor: WidgetTokens.sunsetGlassBackground,
      surfaceColor: WidgetTokens.sunsetGlassSurface,
      accentColor: WidgetTokens.sunsetGlassAccent,
      primaryTextColor: WidgetTokens.sunsetGlassPrimaryText,
      secondaryTextColor: WidgetTokens.sunsetGlassSecondaryText,
      borderColor: WidgetTokens.sunsetGlassBorder,
      isDark: true,
    ),
  ];
}
