/// Haptic feedback tokens for vibration intensity and duration.
/// All haptic feedback values must come from these tokens — no hardcoded vibration patterns.
class HapticsTokens {
  const HapticsTokens._internal();
  static const HapticsTokens _instance = HapticsTokens._internal();
  factory HapticsTokens() => _instance;

  // Feedback intensity values
  static const double lightIntensity = 0.5;
  static const double mediumIntensity = 1.0;
  static const double heavyIntensity = 1.5;
  static const double selectionIntensity = 0.75;

  // Duration tokens (in milliseconds)
  static const int lightDuration = 50;
  static const int mediumDuration = 100;
  static const int heavyDuration = 150;
  static const int selectionDuration = 30;
}
