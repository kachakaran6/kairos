import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_settings.dart';

class SettingsController extends Notifier<UserSettings> {
  static const _themeModeKey = 'kairos_setting_theme_mode';
  static const _paletteKey = 'kairos_setting_palette';
  static const _24HourKey = 'kairos_setting_24hour';
  static const _showSecondsKey = 'kairos_setting_show_seconds';
  static const _mondayFirstKey = 'kairos_setting_monday_first';
  static const _reduceMotionKey = 'kairos_setting_reduce_motion';
  static const _highContrastKey = 'kairos_setting_high_contrast';
  static const _notificationsKey = 'kairos_setting_notifications';

  @override
  UserSettings build() {
    _loadFromPrefs();
    return const UserSettings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeModeKey);
    final themeMode = themeStr == 'dark'
        ? ThemeMode.dark
        : (themeStr == 'light' ? ThemeMode.light : ThemeMode.system);

    final paletteStr = prefs.getString(_paletteKey);
    final palette = AccentPalette.values.firstWhere(
      (p) => p.name == paletteStr,
      orElse: () => AccentPalette.terracotta,
    );

    final use24Hour = prefs.getBool(_24HourKey) ?? true;
    final showSeconds = prefs.getBool(_showSecondsKey) ?? true;
    final mondayFirst = prefs.getBool(_mondayFirstKey) ?? true;
    final reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    final highContrast = prefs.getBool(_highContrastKey) ?? false;
    final notifications = prefs.getBool(_notificationsKey) ?? true;

    state = UserSettings(
      themeMode: themeMode,
      accentPalette: palette,
      use24HourFormat: use24Hour,
      showSeconds: showSeconds,
      firstDayMonday: mondayFirst,
      reduceMotion: reduceMotion,
      highContrast: highContrast,
      notificationsEnabled: notifications,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system');
    await prefs.setString(_themeModeKey, modeStr);
  }

  Future<void> setAccentPalette(AccentPalette palette) async {
    state = state.copyWith(accentPalette: palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, palette.name);
  }

  Future<void> set24HourFormat(bool enabled) async {
    state = state.copyWith(use24HourFormat: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_24HourKey, enabled);
  }

  Future<void> setShowSeconds(bool show) async {
    state = state.copyWith(showSeconds: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSecondsKey, show);
  }

  Future<void> setFirstDayMonday(bool monday) async {
    state = state.copyWith(firstDayMonday: monday);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mondayFirstKey, monday);
  }

  Future<void> setReduceMotion(bool reduce) async {
    state = state.copyWith(reduceMotion: reduce);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, reduce);
  }

  Future<void> setHighContrast(bool contrast) async {
    state = state.copyWith(highContrast: contrast);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, contrast);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(() {
  return SettingsController();
});
