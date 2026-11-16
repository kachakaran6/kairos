/// Motion / animation tokens for transitions and timing.
/// All duration and curve values must come from these tokens — no hardcoded durations in code.
///
/// Constraints per AGENTS.md §2: Reduce Motion must be handled.
class MotionTokens {
  const MotionTokens._internal();
  static const MotionTokens _instance = MotionTokens._internal();
  factory MotionTokens() => _instance;

  // Duration tokens (all in milliseconds)
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration veryLong = Duration(milliseconds: 750);

  // Curve tokens (values represent control point for animation curves)
  static const double linear = 1.0;
  static const double easeIn = 0.0;
  static const double easeOut = 1.0;
  static const double easeInOut = 0.5;
  static const double fastOutSlowIn = 0.0;
  static const double bounceInOut = 0.5;

  // Reduce Motion consideration
  static const Duration reduceMotionShort = Duration(milliseconds: 0);
  static const Duration reduceMotionMedium = Duration(milliseconds: 150);
  static const Duration reduceMotionLong = Duration(milliseconds: 300);
}
