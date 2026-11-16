import 'package:flutter/animation.dart';

/// Motion tokens. Springs run 0.3 to 0.5 seconds; linear easing is banned.
abstract final class MotionTokens {
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 500);

  /// Reduce Motion collapses movement to an instant state change.
  static const Duration reduceMotion = Duration.zero;

  /// Decelerating curve used for entrances and number rolls.
  static const Curve enter = Curves.easeOutCubic;

  /// Decelerating curve with no perceptible overshoot.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Symmetric curve used when a surface moves both in and out.
  static const Curve move = Curves.easeInOutCubic;
}
