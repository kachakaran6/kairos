/// Spacing tokens. Every value is a multiple of 4; layout gaps use 8.
///
/// Widgets must read from [Space], never from a numeric literal.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 64;

  /// Screen margins: 20 on phone, 32 on tablet.
  static const double phoneMargin = 20;
  static const double tabletMargin = 32;

  /// Minimum touch targets: 44pt iOS, 48dp Android.
  static const double touchTargetIos = 44;
  static const double touchTargetAndroid = 48;

  /// Breakpoint used to pick the tablet margin.
  static const double tabletBreakpoint = 600;

  /// WCAG minimum contrast for body text.
  static const double contrastMinimum = 4.5;
}
