/// How an alarm asks to be dismissed.
enum AlarmDismissal { tap, math, phrase, shake }

/// One alarm. Times are stored as local wall-clock values because an alarm is a
/// civil-time promise, not an instant; [nextOccurrence] resolves it against a
/// local clock and daylight saving is handled by [DateTime] at render time.
class Alarm {
  const Alarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.repeatDays = const <int>{},
    this.enabled = true,
    this.wakeWindowMinutes = 0,
    this.dismissal = AlarmDismissal.tap,
    this.skipNext = false,
    required this.createdAtUtc,
  });

  final String id;
  final String label;
  final int hour;
  final int minute;

  /// Weekdays from [DateTime.monday] to [DateTime.sunday]. Empty means once.
  final Set<int> repeatDays;
  final bool enabled;

  /// 0, 15 or 30 minutes. The alarm may ring anywhere inside the window.
  final int wakeWindowMinutes;
  final AlarmDismissal dismissal;

  /// Skips the next occurrence without deleting the alarm.
  final bool skipNext;
  final DateTime createdAtUtc;

  bool get repeats => repeatDays.isNotEmpty;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    const weekdays = <int>{
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    };
    if (repeatDays.length == 5 && repeatDays.containsAll(weekdays)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(DateTime.saturday) &&
        repeatDays.contains(DateTime.sunday)) {
      return 'Weekends';
    }
    const names = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    final sorted = repeatDays.toList()..sort();
    return sorted.map((day) => names[day] ?? '').join(', ');
  }

  /// The next local instant this alarm rings, strictly after [fromLocal].
  DateTime? nextOccurrence(DateTime fromLocal) {
    if (!enabled) return null;
    var searchFrom = fromLocal;
    if (skipNext) {
      // Move past the occurrence that would otherwise be next.
      searchFrom =
          _firstOccurrence(fromLocal)?.add(const Duration(minutes: 1)) ??
          fromLocal.add(const Duration(minutes: 1));
    }
    return _firstOccurrence(searchFrom);
  }

  DateTime? _firstOccurrence(DateTime fromLocal) {
    for (var offset = 0; offset <= 7; offset++) {
      final day = fromLocal.add(Duration(days: offset));
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      if (candidate.isBefore(fromLocal)) continue;
      if (repeatDays.isEmpty || repeatDays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return null;
  }

  Alarm copyWith({
    String? label,
    int? hour,
    int? minute,
    Set<int>? repeatDays,
    bool? enabled,
    int? wakeWindowMinutes,
    AlarmDismissal? dismissal,
    bool? skipNext,
  }) {
    return Alarm(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      wakeWindowMinutes: wakeWindowMinutes ?? this.wakeWindowMinutes,
      dismissal: dismissal ?? this.dismissal,
      skipNext: skipNext ?? this.skipNext,
      createdAtUtc: createdAtUtc,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    'hour': hour,
    'minute': minute,
    'repeatDays': repeatDays.toList()..sort(),
    'enabled': enabled,
    'wakeWindowMinutes': wakeWindowMinutes,
    'dismissal': dismissal.name,
    'skipNext': skipNext,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
  };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Alarm',
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      repeatDays: (json['repeatDays'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<int>()
          .toSet(),
      enabled: json['enabled'] as bool? ?? true,
      wakeWindowMinutes: json['wakeWindowMinutes'] as int? ?? 0,
      dismissal: AlarmDismissal.values.firstWhere(
        (value) => value.name == json['dismissal'],
        orElse: () => AlarmDismissal.tap,
      ),
      skipNext: json['skipNext'] as bool? ?? false,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
    );
  }
}
