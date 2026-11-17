import 'dart:convert';

import '../../../features/alarm/domain/alarm.dart';
import '../../../features/moments/domain/moment.dart';

/// Comprehensive snapshot containing all data required to render any Kairos widget.
class KairosWidgetDataSnapshot {
  const KairosWidgetDataSnapshot({
    required this.generatedAtUtc,
    required this.isDark,
    required this.accentColorHex,
    required this.use24HourFormat,
    required this.showSeconds,
    required this.firstDayMonday,
    required this.nextMoments,
    required this.pastMoments,
    required this.worldClockCities,
    this.nextAlarm,
    this.focusTodayCount = 0,
    this.focusStreakDays = 0,
    this.activeLook = 'Terracotta Paper',
  });

  final DateTime generatedAtUtc;
  final bool isDark;
  final String accentColorHex;
  final bool use24HourFormat;
  final bool showSeconds;
  final bool firstDayMonday;
  final List<Map<String, dynamic>> nextMoments;
  final List<Map<String, dynamic>> pastMoments;
  final List<Map<String, dynamic>> worldClockCities;
  final Map<String, dynamic>? nextAlarm;
  final int focusTodayCount;
  final int focusStreakDays;
  final String activeLook;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'generatedAtUtc': generatedAtUtc.toIso8601String(),
    'isDark': isDark,
    'accentColorHex': accentColorHex,
    'use24HourFormat': use24HourFormat,
    'showSeconds': showSeconds,
    'firstDayMonday': firstDayMonday,
    'nextMoments': nextMoments,
    'pastMoments': pastMoments,
    'worldClockCities': worldClockCities,
    'nextAlarm': nextAlarm,
    'focusTodayCount': focusTodayCount,
    'focusStreakDays': focusStreakDays,
    'activeLook': activeLook,
  };

  static String encodeMoment(Moment m, DateTime nowUtc) {
    final diff = m.targetUtc.difference(nowUtc);
    final days = diff.inDays.abs();
    final hours = diff.inHours.abs() % 24;
    final isToday =
        m.targetUtc.year == nowUtc.year &&
        m.targetUtc.month == nowUtc.month &&
        m.targetUtc.day == nowUtc.day;

    return jsonEncode(<String, dynamic>{
      'id': m.id,
      'title': m.title,
      'subtitle': m.subtitle ?? '',
      'targetUtc': m.targetUtc.toIso8601String(),
      'category': m.category.name,
      'direction': m.direction.name,
      'days': days,
      'hours': hours,
      'isToday': isToday,
      'isPast': m.targetUtc.isBefore(nowUtc),
      'pinned': m.pinned,
    });
  }

  static String encodeAlarm(Alarm a) {
    return jsonEncode(<String, dynamic>{
      'id': a.id,
      'label': a.label,
      'hour': a.hour,
      'minute': a.minute,
      'repeatDays': a.repeatDays.toList(),
      'enabled': a.enabled,
    });
  }
}
