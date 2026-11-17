import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale tokens for the "Warm precision" luxury editorial aesthetic.
/// Big beautiful numerals with tabular figures so ticking clocks never jitter.
@immutable
class KairosTypeScale {
  const KairosTypeScale({
    required this.display,
    required this.title,
    required this.section,
    required this.body,
    required this.caption,
    required this.micro,
    TextStyle? displayL,
    TextStyle? titleM,
    TextStyle? label,
    TextStyle? serifDisplay,
    TextStyle? serifTitle,
  }) : displayL = displayL ?? display,
       titleM = titleM ?? section,
       label = label ?? micro,
       serifDisplay = serifDisplay ?? display,
       serifTitle = serifTitle ?? title;

  final TextStyle display; // display-xl (clock, 96pt)
  final TextStyle displayL; // display-l (64pt)
  final TextStyle title; // title-l (28pt)
  final TextStyle titleM; // title-m (20pt)
  final TextStyle section; // 17pt
  final TextStyle body; // body (16pt)
  final TextStyle caption; // caption (13pt)
  final TextStyle label; // label (12pt uppercase +1.2 spacing)
  final TextStyle micro; // micro (10pt)
  final TextStyle serifDisplay; // Fraunces display for Zero Moment
  final TextStyle serifTitle; // Fraunces for moments and empty states

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static final KairosTypeScale standard = KairosTypeScale(
    display: GoogleFonts.bricolageGrotesque(
      fontSize: 96,
      height: 92 / 96,
      fontWeight: FontWeight.w200,
      letterSpacing: -2.0,
      fontFeatures: _tabular,
    ),
    displayL: GoogleFonts.bricolageGrotesque(
      fontSize: 64,
      height: 64 / 64,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.0,
      fontFeatures: _tabular,
    ),
    title: GoogleFonts.inter(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    titleM: GoogleFonts.inter(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    section: GoogleFonts.inter(
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    body: GoogleFonts.inter(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
    ),
    caption: GoogleFonts.inter(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular,
    ),
    label: GoogleFonts.inter(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    micro: GoogleFonts.inter(
      fontSize: 10,
      height: 14 / 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      fontFeatures: _tabular,
    ),
    serifDisplay: GoogleFonts.fraunces(
      fontSize: 64,
      height: 68 / 64,
      fontWeight: FontWeight.w400,
      letterSpacing: -1.0,
    ),
    serifTitle: GoogleFonts.fraunces(
      fontSize: 32,
      height: 38 / 32,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.4,
    ),
  );

  KairosTypeScale withFontFamily(String family, [String? serifFamily]) {
    final serif = serifFamily ?? family;
    return KairosTypeScale(
      display: TextStyle(
        fontFamily: family,
        fontSize: 96,
        height: 92 / 96,
        fontWeight: FontWeight.w200,
        letterSpacing: -2.0,
        fontFeatures: _tabular,
      ),
      displayL: TextStyle(
        fontFamily: family,
        fontSize: 64,
        height: 68 / 64,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        fontFeatures: _tabular,
      ),
      title: TextStyle(
        fontFamily: family,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleM: TextStyle(
        fontFamily: family,
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      section: TextStyle(
        fontFamily: family,
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      body: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      ),
      caption: TextStyle(
        fontFamily: family,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
      ),
      label: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      micro: TextStyle(
        fontFamily: family,
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        fontFeatures: _tabular,
      ),
      serifDisplay: TextStyle(
        fontFamily: serif,
        fontSize: 64,
        height: 68 / 64,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.0,
      ),
      serifTitle: TextStyle(
        fontFamily: serif,
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
    );
  }

  /// Converts the scale to a Material [TextTheme] without inventing sizes.
  TextTheme toTextTheme(Color primary, Color secondary, Color tertiary) {
    return TextTheme(
      displayLarge: display.copyWith(color: primary),
      displayMedium: displayL.copyWith(color: primary),
      displaySmall: title.copyWith(color: primary),
      headlineLarge: title.copyWith(color: primary),
      headlineMedium: titleM.copyWith(color: primary),
      headlineSmall: section.copyWith(color: primary),
      titleLarge: titleM.copyWith(color: primary),
      titleMedium: section.copyWith(color: primary),
      titleSmall: body.copyWith(color: primary),
      bodyLarge: body.copyWith(color: primary),
      bodyMedium: body.copyWith(color: secondary),
      bodySmall: caption.copyWith(color: secondary),
      labelLarge: label.copyWith(color: primary),
      labelMedium: caption.copyWith(color: secondary),
      labelSmall: micro.copyWith(color: tertiary),
    );
  }

  KairosTypeScale applyColor(Color primary, Color secondary) {
    return KairosTypeScale(
      display: display.copyWith(color: primary),
      displayL: displayL.copyWith(color: primary),
      title: title.copyWith(color: primary),
      titleM: titleM.copyWith(color: primary),
      section: section.copyWith(color: primary),
      body: body.copyWith(color: secondary),
      caption: caption.copyWith(color: secondary),
      label: label.copyWith(color: secondary),
      micro: micro.copyWith(color: secondary),
      serifDisplay: serifDisplay.copyWith(color: primary),
      serifTitle: serifTitle.copyWith(color: primary),
    );
  }
}
