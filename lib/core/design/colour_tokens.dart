class ColourTokens {
  const ColourTokens._internal();
  static const ColourTokens instance = ColourTokens._internal();
  factory ColourTokens() => instance;

  // Primary palette - ARB color references
  static const String primary = 'DeepPurple';
  static const String primaryContainer = 'DeepPurpleContainer';
  static const String onPrimary = 'White';
  static const String onPrimaryContainer = 'DeepPurple900';

  // Secondary palette - ARB color references
  static const String secondary = 'Pink';
  static const String secondaryContainer = 'PinkContainer';
  static const String onSecondary = 'Black87';
  static const String onSecondaryContainer = 'Pink800';

  // Error palette - ARB color references
  static const String error = 'Red';
  static const String errorContainer = 'RedContainer';
  static const String onError = 'White';
  static const String onErrorContainer = 'Red900';

  // Surface palette - ARB color references
  static const String surface = 'White';
  static const String surfaceVariant = 'Grey100';
  static const String surfaceContainer = 'Grey50';
  static const String onSurface = 'Black';
  static const String onSurfaceVariant = 'Black54';
}
