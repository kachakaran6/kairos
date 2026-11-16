import 'package:flutter/material.dart';

import '../../../core/design/palette_tokens.dart';

enum AccentPalette {
  terracotta('Terracotta', KairosAccentPalettes.terracottaLight, KairosAccentPalettes.terracottaDark),
  oceanBlue('Ocean Blue', KairosAccentPalettes.oceanBlueLight, KairosAccentPalettes.oceanBlueDark),
  forestGreen('Forest Green', KairosAccentPalettes.forestGreenLight, KairosAccentPalettes.forestGreenDark),
  lavender('Lavender', KairosAccentPalettes.lavenderLight, KairosAccentPalettes.lavenderDark),
  graphite('Graphite', KairosAccentPalettes.graphiteLight, KairosAccentPalettes.graphiteDark);

  const AccentPalette(this.label, this.lightColor, this.darkColor);

  final String label;
  final Color lightColor;
  final Color darkColor;
}

class UserSettings {
  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.accentPalette = AccentPalette.terracotta,
    this.use24HourFormat = true,
    this.showSeconds = true,
    this.firstDayMonday = true,
    this.reduceMotion = false,
    this.highContrast = false,
    this.notificationsEnabled = true,
    this.defaultCategory = 'Custom',
    this.defaultAllDay = true,
  });

  final ThemeMode themeMode;
  final AccentPalette accentPalette;
  final bool use24HourFormat;
  final bool showSeconds;
  final bool firstDayMonday;
  final bool reduceMotion;
  final bool highContrast;
  final bool notificationsEnabled;
  final String defaultCategory;
  final bool defaultAllDay;

  UserSettings copyWith({
    ThemeMode? themeMode,
    AccentPalette? accentPalette,
    bool? use24HourFormat,
    bool? showSeconds,
    bool? firstDayMonday,
    bool? reduceMotion,
    bool? highContrast,
    bool? notificationsEnabled,
    String? defaultCategory,
    bool? defaultAllDay,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      accentPalette: accentPalette ?? this.accentPalette,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      showSeconds: showSeconds ?? this.showSeconds,
      firstDayMonday: firstDayMonday ?? this.firstDayMonday,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultAllDay: defaultAllDay ?? this.defaultAllDay,
    );
  }
}
