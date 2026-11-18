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
    this.backgroundType = 'warm_paper',
    this.cornerRadius = 28.0,
    this.borderEnabled = true,
    this.borderWidthDp = 1.0,
    this.fontStyle = 'modern',
    this.lookId = 'terracotta_paper',
    this.use24Hour = true,
    this.showSeconds = false,
    this.showAmPm = false,
    this.showDate = true,
    this.showAlarm = true,
    this.timeLayout = 'inline',
    this.timeSeparator = 'colon',
    this.secondsStyle = 'hidden',
    this.customFormat = '',
    this.scaleFactor = 1.0,
    this.photoPath,
    this.momentVisual = 'ring',
    this.momentUnit = 'days',
    this.leadingZero = true,
    this.batterySafeMode = true,
    this.secondsScreenOnOnly = true,
    this.showHours = true,
    this.showMinutes = true,
    this.showDayName = true,
    this.showMonth = true,
    this.showYear = false,
    this.showWeekNumber = false,
    this.showDayOfYear = false,
    this.showTimeZone = false,
    this.momentDirection = 'auto',
    this.showMomentTitle = true,
    this.showMomentCategory = true,
    this.showMomentDate = true,
    this.showMomentProgress = true,
    this.showMomentNote = false,
    this.selectedMomentId,
    this.alignment = 'center',
    this.version = 2,
  });

  final String themeMode;
  final String accentHex;
  final String textColor;
  final String textSecondaryColor;
  final String backgroundColor;
  final double backgroundOpacity;
  final String backgroundType;
  final double cornerRadius;
  final bool borderEnabled;
  final double borderWidthDp;
  final String fontStyle;
  final String lookId;
  final bool use24Hour;
  final bool showSeconds;
  final bool showAmPm;
  final bool showDate;
  final bool showAlarm;
  final String timeLayout;
  final String timeSeparator;
  final String secondsStyle;
  final String customFormat;
  final double scaleFactor;
  final String? photoPath;
  final String momentVisual;
  final String momentUnit;
  final bool leadingZero;
  final bool batterySafeMode;
  final bool secondsScreenOnOnly;
  final bool showHours;
  final bool showMinutes;
  final bool showDayName;
  final bool showMonth;
  final bool showYear;
  final bool showWeekNumber;
  final bool showDayOfYear;
  final bool showTimeZone;
  final String momentDirection;
  final bool showMomentTitle;
  final bool showMomentCategory;
  final bool showMomentDate;
  final bool showMomentProgress;
  final bool showMomentNote;
  final String? selectedMomentId;
  final String alignment;
  final int version;

  factory WidgetConfig.fromLook(
    WidgetLook look, {
    double backgroundOpacity = 1.0,
    String? backgroundType,
    double cornerRadius = 28.0,
    bool borderEnabled = true,
    double borderWidthDp = 1.0,
    String fontStyle = 'modern',
    bool use24Hour = true,
    bool showSeconds = false,
    bool showAmPm = false,
    bool showDate = true,
    bool showAlarm = true,
    String timeLayout = 'inline',
    String timeSeparator = 'colon',
    String secondsStyle = 'hidden',
    String customFormat = '',
    double scaleFactor = 1.0,
    String? photoPath,
    String momentVisual = 'ring',
    String momentUnit = 'days',
    bool leadingZero = true,
    bool batterySafeMode = true,
    bool secondsScreenOnOnly = true,
    bool showHours = true,
    bool showMinutes = true,
    bool showDayName = true,
    bool showMonth = true,
    bool showYear = false,
    bool showWeekNumber = false,
    bool showDayOfYear = false,
    bool showTimeZone = false,
    String momentDirection = 'auto',
    bool showMomentTitle = true,
    bool showMomentCategory = true,
    bool showMomentDate = true,
    bool showMomentProgress = true,
    bool showMomentNote = false,
    String? selectedMomentId,
    String alignment = 'center',
  }) {
    String colorToHex(dynamic c) {
      final val = c.toARGB32();
      return '#${val.toRadixString(16).padLeft(8, '0').substring(2)}';
    }

    final defaultBg = switch (look.id) {
      'midnight_ink' ||
      'mono_graphite' ||
      'neon_dial' ||
      'minimal_dots' => 'dark_ink',
      'terracotta_paper' || 'poster' => 'terracotta',
      'sunset_glass' => 'glass',
      _ => 'warm_paper',
    };

    return WidgetConfig(
      themeMode: look.isDark ? 'dark' : 'light',
      accentHex: colorToHex(look.accentColor),
      textColor: colorToHex(look.primaryTextColor),
      textSecondaryColor: colorToHex(look.secondaryTextColor),
      backgroundColor: colorToHex(look.backgroundColor),
      backgroundOpacity: backgroundOpacity.clamp(0.05, 1.0),
      backgroundType: backgroundType ?? defaultBg,
      cornerRadius: cornerRadius.clamp(0.0, 40.0),
      borderEnabled: borderEnabled,
      borderWidthDp: borderWidthDp,
      fontStyle: fontStyle,
      lookId: look.id,
      use24Hour: use24Hour,
      showSeconds: showSeconds,
      showAmPm: showAmPm,
      showDate: showDate,
      showAlarm: showAlarm,
      timeLayout: timeLayout,
      timeSeparator: timeSeparator,
      secondsStyle: secondsStyle,
      customFormat: customFormat,
      scaleFactor: scaleFactor,
      photoPath: photoPath,
      momentVisual: momentVisual,
      momentUnit: momentUnit,
      leadingZero: leadingZero,
      batterySafeMode: batterySafeMode,
      secondsScreenOnOnly: secondsScreenOnOnly,
      showHours: showHours,
      showMinutes: showMinutes,
      showDayName: showDayName,
      showMonth: showMonth,
      showYear: showYear,
      showWeekNumber: showWeekNumber,
      showDayOfYear: showDayOfYear,
      showTimeZone: showTimeZone,
      momentDirection: momentDirection,
      showMomentTitle: showMomentTitle,
      showMomentCategory: showMomentCategory,
      showMomentDate: showMomentDate,
      showMomentProgress: showMomentProgress,
      showMomentNote: showMomentNote,
      selectedMomentId: selectedMomentId,
      alignment: alignment,
      version: 2,
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
      backgroundType: json['backgroundType'] as String? ?? 'warm_paper',
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 28.0,
      borderEnabled: json['borderEnabled'] as bool? ?? true,
      borderWidthDp: (json['borderWidthDp'] as num?)?.toDouble() ?? 1.0,
      fontStyle: json['fontStyle'] as String? ?? 'modern',
      lookId: json['lookId'] as String? ?? 'terracotta_paper',
      use24Hour: json['use24Hour'] as bool? ?? true,
      showSeconds: json['showSeconds'] as bool? ?? false,
      showAmPm: json['showAmPm'] as bool? ?? false,
      showDate: json['showDate'] as bool? ?? true,
      showAlarm: json['showAlarm'] as bool? ?? true,
      timeLayout: json['timeLayout'] as String? ?? 'inline',
      timeSeparator: json['timeSeparator'] as String? ?? 'colon',
      secondsStyle: json['secondsStyle'] as String? ?? 'hidden',
      customFormat: json['customFormat'] as String? ?? '',
      scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 1.0,
      photoPath: json['photoPath'] as String?,
      momentVisual: json['momentVisual'] as String? ?? 'ring',
      momentUnit: json['momentUnit'] as String? ?? 'days',
      leadingZero: json['leadingZero'] as bool? ?? true,
      batterySafeMode: json['batterySafeMode'] as bool? ?? true,
      secondsScreenOnOnly: json['secondsScreenOnOnly'] as bool? ?? true,
      showHours: json['showHours'] as bool? ?? true,
      showMinutes: json['showMinutes'] as bool? ?? true,
      showDayName: json['showDayName'] as bool? ?? true,
      showMonth: json['showMonth'] as bool? ?? true,
      showYear: json['showYear'] as bool? ?? false,
      showWeekNumber: json['showWeekNumber'] as bool? ?? false,
      showDayOfYear: json['showDayOfYear'] as bool? ?? false,
      showTimeZone: json['showTimeZone'] as bool? ?? false,
      momentDirection: json['momentDirection'] as String? ?? 'auto',
      showMomentTitle: json['showMomentTitle'] as bool? ?? true,
      showMomentCategory: json['showMomentCategory'] as bool? ?? true,
      showMomentDate: json['showMomentDate'] as bool? ?? true,
      showMomentProgress: json['showMomentProgress'] as bool? ?? true,
      showMomentNote: json['showMomentNote'] as bool? ?? false,
      selectedMomentId: json['selectedMomentId'] as String?,
      alignment: json['alignment'] as String? ?? 'center',
      version: json['version'] as int? ?? 2,
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
      'backgroundType': backgroundType,
      'cornerRadius': cornerRadius,
      'borderEnabled': borderEnabled,
      'borderWidthDp': borderWidthDp,
      'fontStyle': fontStyle,
      'lookId': lookId,
      'use24Hour': use24Hour,
      'showSeconds': showSeconds,
      'showAmPm': showAmPm,
      'showDate': showDate,
      'showAlarm': showAlarm,
      'timeLayout': timeLayout,
      'timeSeparator': timeSeparator,
      'secondsStyle': secondsStyle,
      'customFormat': customFormat,
      'scaleFactor': scaleFactor,
      'photoPath': photoPath,
      'momentVisual': momentVisual,
      'momentUnit': momentUnit,
      'leadingZero': leadingZero,
      'batterySafeMode': batterySafeMode,
      'secondsScreenOnOnly': secondsScreenOnOnly,
      'showHours': showHours,
      'showMinutes': showMinutes,
      'showDayName': showDayName,
      'showMonth': showMonth,
      'showYear': showYear,
      'showWeekNumber': showWeekNumber,
      'showDayOfYear': showDayOfYear,
      'showTimeZone': showTimeZone,
      'momentDirection': momentDirection,
      'showMomentTitle': showMomentTitle,
      'showMomentCategory': showMomentCategory,
      'showMomentDate': showMomentDate,
      'showMomentProgress': showMomentProgress,
      'showMomentNote': showMomentNote,
      'selectedMomentId': selectedMomentId,
      'alignment': alignment,
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
    String? backgroundType,
    double? cornerRadius,
    bool? borderEnabled,
    double? borderWidthDp,
    String? fontStyle,
    String? lookId,
    bool? use24Hour,
    bool? showSeconds,
    bool? showAmPm,
    bool? showDate,
    bool? showAlarm,
    String? timeLayout,
    String? timeSeparator,
    String? secondsStyle,
    String? customFormat,
    double? scaleFactor,
    String? photoPath,
    String? momentVisual,
    String? momentUnit,
    bool? leadingZero,
    bool? batterySafeMode,
    bool? secondsScreenOnOnly,
    bool? showHours,
    bool? showMinutes,
    bool? showDayName,
    bool? showMonth,
    bool? showYear,
    bool? showWeekNumber,
    bool? showDayOfYear,
    bool? showTimeZone,
    String? momentDirection,
    bool? showMomentTitle,
    bool? showMomentCategory,
    bool? showMomentDate,
    bool? showMomentProgress,
    bool? showMomentNote,
    String? selectedMomentId,
    String? alignment,
  }) {
    return WidgetConfig(
      themeMode: themeMode ?? this.themeMode,
      accentHex: accentHex ?? this.accentHex,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundType: backgroundType ?? this.backgroundType,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderEnabled: borderEnabled ?? this.borderEnabled,
      borderWidthDp: borderWidthDp ?? this.borderWidthDp,
      fontStyle: fontStyle ?? this.fontStyle,
      lookId: lookId ?? this.lookId,
      use24Hour: use24Hour ?? this.use24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      showAmPm: showAmPm ?? this.showAmPm,
      showDate: showDate ?? this.showDate,
      showAlarm: showAlarm ?? this.showAlarm,
      timeLayout: timeLayout ?? this.timeLayout,
      timeSeparator: timeSeparator ?? this.timeSeparator,
      secondsStyle: secondsStyle ?? this.secondsStyle,
      customFormat: customFormat ?? this.customFormat,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      photoPath: photoPath ?? this.photoPath,
      momentVisual: momentVisual ?? this.momentVisual,
      momentUnit: momentUnit ?? this.momentUnit,
      leadingZero: leadingZero ?? this.leadingZero,
      batterySafeMode: batterySafeMode ?? this.batterySafeMode,
      secondsScreenOnOnly: secondsScreenOnOnly ?? this.secondsScreenOnOnly,
      showHours: showHours ?? this.showHours,
      showMinutes: showMinutes ?? this.showMinutes,
      showDayName: showDayName ?? this.showDayName,
      showMonth: showMonth ?? this.showMonth,
      showYear: showYear ?? this.showYear,
      showWeekNumber: showWeekNumber ?? this.showWeekNumber,
      showDayOfYear: showDayOfYear ?? this.showDayOfYear,
      showTimeZone: showTimeZone ?? this.showTimeZone,
      momentDirection: momentDirection ?? this.momentDirection,
      showMomentTitle: showMomentTitle ?? this.showMomentTitle,
      showMomentCategory: showMomentCategory ?? this.showMomentCategory,
      showMomentDate: showMomentDate ?? this.showMomentDate,
      showMomentProgress: showMomentProgress ?? this.showMomentProgress,
      showMomentNote: showMomentNote ?? this.showMomentNote,
      selectedMomentId: selectedMomentId ?? this.selectedMomentId,
      alignment: alignment ?? this.alignment,
      version: version,
    );
  }
}
