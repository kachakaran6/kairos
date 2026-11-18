import '../../../features/widgets/domain/widget_look.dart';

/// Single source of truth configuration for Kairos home screen widgets.
class WidgetConfig {
  const WidgetConfig({
    this.themeMode = 'dark',
    this.accentHex = '#E8895A',
    this.textColor = '#F4EFE8',
    this.textSecondaryColor = '#9E968D',
    this.backgroundColor = '#0F0D0B',
    this.backgroundOpacity = 1.0,
    this.cornerRadius = 28.0,
    this.fontStyle = 'modern',
    this.lookId = 'midnight_ink',
    this.use24Hour = true,
    this.showSeconds = false,
    this.version = 1,
  });

  final String themeMode;
  final String accentHex;
  final String textColor;
  final String textSecondaryColor;
  final String backgroundColor;
  final double backgroundOpacity;
  final double cornerRadius;
  final String fontStyle;
  final String lookId;
  final bool use24Hour;
  final bool showSeconds;
  final int version;

  factory WidgetConfig.fromLook(
    WidgetLook look, {
    double backgroundOpacity = 1.0,
    double cornerRadius = 28.0,
    String fontStyle = 'modern',
    bool use24Hour = true,
    bool showSeconds = false,
  }) {
    String colorToHex(dynamic c) {
      final val = c.toARGB32();
      return '#${val.toRadixString(16).padLeft(8, '0').substring(2)}';
    }

    return WidgetConfig(
      themeMode: look.isDark ? 'dark' : 'light',
      accentHex: colorToHex(look.accentColor),
      textColor: colorToHex(look.primaryTextColor),
      textSecondaryColor: colorToHex(look.secondaryTextColor),
      backgroundColor: colorToHex(look.backgroundColor),
      backgroundOpacity: backgroundOpacity.clamp(0.05, 1.0),
      cornerRadius: cornerRadius,
      fontStyle: fontStyle,
      lookId: look.id,
      use24Hour: use24Hour,
      showSeconds: showSeconds,
      version: 1,
    );
  }

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      themeMode: json['themeMode'] as String? ?? 'dark',
      accentHex: json['accentHex'] as String? ?? '#E8895A',
      textColor: json['textColor'] as String? ?? '#F4EFE8',
      textSecondaryColor: json['textSecondaryColor'] as String? ?? '#9E968D',
      backgroundColor: json['backgroundColor'] as String? ?? '#0F0D0B',
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 28.0,
      fontStyle: json['fontStyle'] as String? ?? 'modern',
      lookId: json['lookId'] as String? ?? 'midnight_ink',
      use24Hour: json['use24Hour'] as bool? ?? true,
      showSeconds: json['showSeconds'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'accentHex': accentHex,
      'textColor': textColor,
      'textSecondaryColor': textSecondaryColor,
      'backgroundColor': backgroundColor,
      'backgroundOpacity': backgroundOpacity,
      'cornerRadius': cornerRadius,
      'fontStyle': fontStyle,
      'lookId': lookId,
      'use24Hour': use24Hour,
      'showSeconds': showSeconds,
      'version': version,
    };
  }

  WidgetConfig copyWith({
    String? themeMode,
    String? accentHex,
    String? textColor,
    String? textSecondaryColor,
    String? backgroundColor,
    double? backgroundOpacity,
    double? cornerRadius,
    String? fontStyle,
    String? lookId,
    bool? use24Hour,
    bool? showSeconds,
  }) {
    return WidgetConfig(
      themeMode: themeMode ?? this.themeMode,
      accentHex: accentHex ?? this.accentHex,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      fontStyle: fontStyle ?? this.fontStyle,
      lookId: lookId ?? this.lookId,
      use24Hour: use24Hour ?? this.use24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      version: version,
    );
  }
}
