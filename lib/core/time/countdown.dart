import 'dart:math' as math;

/// How a moment reads its distance from now.
enum CountingMode {
  days,
  sleeps,
  hours,
  minutes,
  seconds,
  continuous,
  weeks,
  months,
  years,
  percent,
  xOfY,
  weekdays,
}

/// A formatted countdown value and its unit.
class CountdownText {
  const CountdownText(this.value, this.unit);

  final String value;
  final String unit;

  @override
  String toString() => '$value $unit';
}

/// Pure time arithmetic for moments. Every input is UTC; local time is applied
/// only at the render boundary by the caller.
abstract final class Countdown {
  /// Calendar days between two UTC instants, ignoring the time of day.
  static int calendarDaysBetween(DateTime fromUtc, DateTime toUtc) {
    final from = DateTime.utc(fromUtc.year, fromUtc.month, fromUtc.day);
    final to = DateTime.utc(toUtc.year, toUtc.month, toUtc.day);
    return to.difference(from).inDays;
  }

  /// Sleeps are calendar nights, which is what a child counts.
  static int sleepsBetween(DateTime fromUtc, DateTime toUtc) =>
      calendarDaysBetween(fromUtc, toUtc);

  /// Absolute distance between the two instants.
  static Duration distance(DateTime fromUtc, DateTime toUtc) {
    final delta = toUtc.difference(fromUtc);
    return delta.isNegative ? -delta : delta;
  }

  /// Formats a moment as the largest useful unit. Before the moment it reads
  /// down; after it reads up. At the exact zero instant it returns `0 days`.
  static CountdownText format(
    DateTime nowUtc,
    DateTime targetUtc, {
    CountingMode mode = CountingMode.days,
  }) {
    final future = targetUtc.isAfter(nowUtc);
    final delta = distance(nowUtc, targetUtc);
    final days = calendarDaysBetween(nowUtc, targetUtc).abs();

    switch (mode) {
      case CountingMode.sleeps:
        return CountdownText(_group(days), days == 1 ? 'sleep' : 'sleeps');
      case CountingMode.weekdays:
        return CountdownText(
          _group(_weekdaysBetween(nowUtc, targetUtc)),
          'weekdays',
        );
      case CountingMode.hours:
        return CountdownText(
          _group(delta.inHours),
          delta.inHours == 1 ? 'hour' : 'hours',
        );
      case CountingMode.minutes:
        return CountdownText(
          _group(delta.inMinutes),
          delta.inMinutes == 1 ? 'minute' : 'minutes',
        );
      case CountingMode.seconds:
        return CountdownText(
          _group(delta.inSeconds),
          delta.inSeconds == 1 ? 'second' : 'seconds',
        );
      case CountingMode.continuous:
        final d = delta.inDays;
        final h = delta.inHours % 24;
        final m = delta.inMinutes % 60;
        final s = delta.inSeconds % 60;
        final valueStr = d > 0
            ? '${_group(d)}d ${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m'
            : (h > 0
                  ? '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m'
                  : '${m.toString().padLeft(2, '0')}m');
        final unitStr = '${s.toString().padLeft(2, '0')}s';
        return CountdownText(valueStr, unitStr);
      case CountingMode.weeks:
        final weeks = delta.inDays ~/ 7;
        return CountdownText(_group(weeks), weeks == 1 ? 'week' : 'weeks');
      case CountingMode.months:
        final months = _monthsBetween(nowUtc, targetUtc);
        return CountdownText(_group(months), months == 1 ? 'month' : 'months');
      case CountingMode.years:
        final years = delta.inDays ~/ 365;
        return CountdownText(_group(years), years == 1 ? 'year' : 'years');
      case CountingMode.percent:
        // Percentage needs a start and an end; callers use percentageComplete.
        return CountdownText('0', '%');
      case CountingMode.xOfY:
        return CountdownText('0', 'of 0');
      case CountingMode.days:
        if (!future && days == 0) return const CountdownText('0', 'days');
        if (future && delta.inHours < 1) {
          final minutes = math.max(delta.inMinutes, 1);
          return CountdownText(
            _group(minutes),
            minutes == 1 ? 'minute' : 'minutes',
          );
        }
        return CountdownText(_group(days), days == 1 ? 'day' : 'days');
    }
  }

  /// Continuous time breakdown: days, hours, minutes, seconds.
  static ({int days, int hours, int minutes, int seconds}) continuousParts(
    DateTime nowUtc,
    DateTime targetUtc,
  ) {
    final delta = distance(nowUtc, targetUtc);
    return (
      days: delta.inDays,
      hours: delta.inHours % 24,
      minutes: delta.inMinutes % 60,
      seconds: delta.inSeconds % 60,
    );
  }

  /// Progress between [startUtc] and [endUtc], clamped to 0..1.
  static double fractionComplete(
    DateTime startUtc,
    DateTime endUtc,
    DateTime nowUtc,
  ) {
    final total = endUtc.difference(startUtc).inMilliseconds;
    if (total <= 0) return 1;
    final elapsed = nowUtc.difference(startUtc).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Percentage complete rounded down, 0 to 100.
  static int percentageComplete(
    DateTime startUtc,
    DateTime endUtc,
    DateTime nowUtc,
  ) => (fractionComplete(startUtc, endUtc, nowUtc) * 100).floor();

  /// `12 of 30` for countable journeys.
  static String xOfY(int done, int total) =>
      '${_group(done)} of ${_group(total)}';

  /// Weekdays (Monday to Friday) between two UTC dates, excluding the start
  /// date and including the end date. A Friday deadline read on Monday is 5,
  /// not 7.
  static int _weekdaysBetween(DateTime fromUtc, DateTime toUtc) {
    final forward = !toUtc.isBefore(fromUtc);
    final start = forward ? fromUtc : toUtc;
    final end = forward ? toUtc : fromUtc;
    var days = 0;
    var cursor = DateTime.utc(start.year, start.month, start.day);
    final last = DateTime.utc(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      if (cursor.weekday <= DateTime.friday) days += 1;
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  static int _monthsBetween(DateTime fromUtc, DateTime toUtc) {
    final months =
        (toUtc.year - fromUtc.year) * 12 + (toUtc.month - fromUtc.month);
    return months.abs();
  }

  static String _group(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}
