import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../features/alarm/presentation/alarm_controller.dart';
import '../../../features/moments/presentation/moment_controller.dart';
import '../../../features/settings/presentation/settings_controller.dart';
import 'widget_artwork_renderer.dart';
import 'widget_data_snapshot.dart';

class WidgetSyncService {
  const WidgetSyncService(this._ref);

  final Ref _ref;

  static const String appGroupId = 'group.com.samyukt.kairos';

  Future<void> syncAllWidgets() async {
    final nowUtc = DateTime.now().toUtc();
    final moments = _ref.read(momentListProvider).value ?? const [];
    final alarms = _ref.read(alarmListProvider).value ?? const [];
    final settings = _ref.read(settingsProvider);

    // 1. Filter Next (upcoming) and Then (past) moments
    final nextMoments =
        moments
            .where((m) => m.targetUtc.isAfter(nowUtc))
            .toList(growable: false)
          ..sort((a, b) => a.targetUtc.compareTo(b.targetUtc));

    final pastMoments =
        moments
            .where((m) => m.targetUtc.isBefore(nowUtc))
            .toList(growable: false)
          ..sort((a, b) => b.targetUtc.compareTo(a.targetUtc));

    // 2. Next enabled alarm
    final enabledAlarms = alarms
        .where((a) => a.enabled)
        .toList(growable: false);
    final nextAlarm = enabledAlarms.isNotEmpty ? enabledAlarms.first : null;

    // 3. World clock cities (default curated list)
    const cities = <Map<String, dynamic>>[
      {'name': 'Mumbai', 'offset': 330},
      {'name': 'London', 'offset': 0},
      {'name': 'New York', 'offset': -300},
      {'name': 'Tokyo', 'offset': 540},
    ];

    final isDark = settings.themeMode == ThemeMode.dark;
    final accentColor = isDark
        ? settings.accentPalette.darkColor
        : settings.accentPalette.lightColor;
    final accentHex =
        '#${accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    // 4. Save individual top-level keys for native RemoteViews to read instantly
    await HomeWidget.saveWidgetData<bool>('is_dark', isDark);
    await HomeWidget.saveWidgetData<String>('accent_hex', accentHex);
    await HomeWidget.saveWidgetData<bool>('use_24h', settings.use24HourFormat);
    await HomeWidget.saveWidgetData<bool>('show_seconds', settings.showSeconds);

    if (nextMoments.isNotEmpty) {
      final m = nextMoments.first;
      final diff = m.targetUtc.difference(nowUtc);
      final days = diff.inDays;
      final isToday = diff.inHours < 24 && m.targetUtc.day == nowUtc.day;

      await HomeWidget.saveWidgetData<String>('next_moment_title', m.title);
      await HomeWidget.saveWidgetData<String>(
        'next_moment_subtitle',
        m.subtitle ?? '',
      );
      await HomeWidget.saveWidgetData<int>('next_moment_days', days);
      await HomeWidget.saveWidgetData<String>(
        'next_moment_category',
        m.category.name,
      );
      await HomeWidget.saveWidgetData<bool>('next_moment_is_today', isToday);

      // Render Hero progress ring artwork (e.g. 70% completed toward target)
      try {
        await HomeWidget.renderFlutterWidget(
          WidgetProgressRing(
            progress: 0.72,
            accentColor: accentColor,
            size: 160,
            strokeWidth: 10,
          ),
          key: 'next_moment_ring',
          logicalSize: const Size(160, 160),
          pixelRatio: 3.0,
        );
      } catch (_) {
        // Safe fallback in environments without Flutter render engine
      }
    } else {
      await HomeWidget.saveWidgetData<String>(
        'next_moment_title',
        'Nothing ahead yet',
      );
      await HomeWidget.saveWidgetData<int>('next_moment_days', 0);
      await HomeWidget.saveWidgetData<bool>('next_moment_is_today', false);
    }

    if (pastMoments.isNotEmpty) {
      final p = pastMoments.first;
      final diff = nowUtc.difference(p.targetUtc);
      await HomeWidget.saveWidgetData<String>('then_moment_title', p.title);
      await HomeWidget.saveWidgetData<int>('then_moment_days', diff.inDays);
    }

    if (nextAlarm != null) {
      final timeStr =
          '${nextAlarm.hour.toString().padLeft(2, '0')}:${nextAlarm.minute.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('next_alarm_time', timeStr);
      await HomeWidget.saveWidgetData<String>(
        'next_alarm_label',
        nextAlarm.label,
      );
      await HomeWidget.saveWidgetData<bool>('next_alarm_enabled', true);
    } else {
      await HomeWidget.saveWidgetData<String>('next_alarm_time', '--:--');
      await HomeWidget.saveWidgetData<String>(
        'next_alarm_label',
        'No alarms set',
      );
      await HomeWidget.saveWidgetData<bool>('next_alarm_enabled', false);
    }

    // 5. Render Focus 7-day streak bars
    try {
      await HomeWidget.renderFlutterWidget(
        WidgetStreakBars(
          activeDays: const [true, true, true, true, false, true, true],
          accentColor: accentColor,
        ),
        key: 'focus_streak_bars',
        logicalSize: const Size(140, 32),
        pixelRatio: 3.0,
      );
    } catch (_) {}

    // 6. Render Life Progress concentric rings
    try {
      final dayPct = (nowUtc.hour * 60 + nowUtc.minute) / (24 * 60);
      final weekPct = (nowUtc.weekday) / 7.0;
      final monthPct = (nowUtc.day) / 30.0;
      final yearPct = (nowUtc.month) / 12.0;

      await HomeWidget.renderFlutterWidget(
        WidgetLifeProgressRings(
          dayProgress: dayPct,
          weekProgress: weekPct,
          monthProgress: monthPct,
          yearProgress: yearPct,
          accentColor: accentColor,
          size: 180,
        ),
        key: 'life_progress_rings',
        logicalSize: const Size(180, 180),
        pixelRatio: 3.0,
      );
    } catch (_) {}

    // 7. Save full snapshot JSON payload
    final snapshot = KairosWidgetDataSnapshot(
      generatedAtUtc: nowUtc,
      isDark: isDark,
      accentColorHex: accentHex,
      use24HourFormat: settings.use24HourFormat,
      showSeconds: settings.showSeconds,
      firstDayMonday: settings.firstDayMonday,
      nextMoments: nextMoments
          .map(
            (m) =>
                jsonDecode(KairosWidgetDataSnapshot.encodeMoment(m, nowUtc))
                    as Map<String, dynamic>,
          )
          .toList(),
      pastMoments: pastMoments
          .map(
            (m) =>
                jsonDecode(KairosWidgetDataSnapshot.encodeMoment(m, nowUtc))
                    as Map<String, dynamic>,
          )
          .toList(),
      worldClockCities: cities,
      nextAlarm: nextAlarm != null
          ? jsonDecode(KairosWidgetDataSnapshot.encodeAlarm(nextAlarm))
                as Map<String, dynamic>
          : null,
      focusTodayCount: 3,
      focusStreakDays: 5,
    );

    await HomeWidget.saveWidgetData<String>(
      'kairos_widget_snapshot_json',
      jsonEncode(snapshot.toJson()),
    );

    // 8. Request Android native widget updates across all 6 widget families
    final providers = [
      'ClockWidgetProvider',
      'WorldClockWidgetProvider',
      'NextMomentWidgetProvider',
      'ThenMomentWidgetProvider',
      'InteractiveWidgetProvider',
      'ComboWidgetProvider',
    ];

    for (final p in providers) {
      try {
        await HomeWidget.updateWidget(name: p, androidName: p);
      } catch (_) {}
    }
  }
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService(ref);
});
