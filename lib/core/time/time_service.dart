/// Injectable clock for every time-dependent feature.
///
/// Production code takes a [Clock]; tests pass a [FixedClock] and advance it.
/// No testable code calls [DateTime.now] directly.
abstract interface class Clock {
  /// Current instant, always in UTC.
  DateTime nowUtc();
}

/// Real wall clock. The only place that reads the system time.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Test clock whose instant only moves when [advance] is called.
final class FixedClock implements Clock {
  FixedClock(DateTime initial) : _now = initial.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  void set(DateTime instant) {
    _now = instant.toUtc();
  }
}

/// Formats a duration as HH:MM:SS with fixed-width digits.
String formatDuration(Duration duration) {
  final negative = duration.isNegative;
  final value = negative ? -duration : duration;
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  final body = '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  return negative ? '-$body' : body;
}

String _two(int value) => value.toString().padLeft(2, '0');
