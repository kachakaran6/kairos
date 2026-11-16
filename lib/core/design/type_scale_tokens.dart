import 'package:flutter/material.dart';

/// Type scale tokens from the product specification, section 4.
/// One hero number per screen: only [display] may be used at display size.
/// Every numeric style carries tabular figures so a ticking countdown never
/// reflows.
@immutable
class KairosTypeScale {
  const KairosTypeScale({
    required this.display,
    required this.title,
    required this.section,
    required this.body,
    required this.caption,
    required this.micro,
  });

  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle micro;

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const KairosTypeScale standard = KairosTypeScale(
    display: TextStyle(
      fontSize: 96,
      height: 92 / 96,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      fontFeatures: _tabular,
    ),
    title: TextStyle(
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    section: TextStyle(
      fontSize: 17,
      height: 21 / 17,
      fontWeight: FontWeight.w600,
    ),
    body: TextStyle(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400),
    caption: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular,
    ),
    micro: TextStyle(
      fontSize: 10,
      height: 13 / 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      fontFeatures: _tabular,
    ),
  );

  /// Converts the scale to a Material [TextTheme] without inventing sizes.
  TextTheme toTextTheme(Color primary, Color secondary, Color tertiary) {
    return TextTheme(
      displayLarge: display.copyWith(color: primary),
      displayMedium: display.copyWith(color: primary),
      displaySmall: display.copyWith(color: primary),
      headlineLarge: title.copyWith(color: primary),
      headlineMedium: title.copyWith(color: primary),
      headlineSmall: section.copyWith(color: primary),
      titleLarge: section.copyWith(color: primary),
      titleMedium: section.copyWith(color: primary),
      bodyLarge: body.copyWith(color: primary),
      bodyMedium: body.copyWith(color: secondary),
      bodySmall: caption.copyWith(color: secondary),
      labelLarge: section.copyWith(color: primary),
      labelMedium: caption.copyWith(color: secondary),
      labelSmall: micro.copyWith(color: tertiary),
    );
  }

  KairosTypeScale applyColor(Color primary, Color secondary) {
    return KairosTypeScale(
      display: display.copyWith(color: primary),
      title: title.copyWith(color: primary),
      section: section.copyWith(color: primary),
      body: body.copyWith(color: secondary),
      caption: caption.copyWith(color: secondary),
      micro: micro.copyWith(color: secondary),
    );
  }
}
