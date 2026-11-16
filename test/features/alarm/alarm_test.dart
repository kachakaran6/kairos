import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/alarm/domain/alarm.dart';

Alarm _alarm({
  int hour = 7,
  int minute = 30,
  Set<int> repeatDays = const <int>{},
  bool enabled = true,
  bool skipNext = false,
}) {
  return Alarm(
    id: 'a1',
    label: 'Wake up',
    hour: hour,
    minute: minute,
    repeatDays: repeatDays,
    enabled: enabled,
    skipNext: skipNext,
    createdAtUtc: DateTime.utc(2026, 11, 16),
  );
}

void main() {
  group('nextOccurrence', () {
    test('a one-off alarm later today rings today', () {
      final now = DateTime(2026, 11, 16, 6);
      expect(_alarm().nextOccurrence(now), DateTime(2026, 11, 16, 7, 30));
    });

    test('a one-off alarm earlier today rings tomorrow', () {
      final now = DateTime(2026, 11, 16, 8);
      expect(_alarm().nextOccurrence(now), DateTime(2026, 11, 17, 7, 30));
    });

    test('a weekday alarm skips the weekend', () {
      final monday = DateTime(2026, 11, 16, 8);
      final alarm = _alarm(repeatDays: <int>{DateTime.monday});
      expect(alarm.nextOccurrence(monday), DateTime(2026, 11, 23, 7, 30));
    });

    test('a weekend alarm from Monday rings on Saturday', () {
      final monday = DateTime(2026, 11, 16, 8);
      final alarm = _alarm(
        repeatDays: <int>{DateTime.saturday, DateTime.sunday},
      );
      expect(alarm.nextOccurrence(monday), DateTime(2026, 11, 21, 7, 30));
    });

    test('skipNext moves to the following occurrence', () {
      final monday = DateTime(2026, 11, 16, 8);
      final alarm = _alarm(repeatDays: <int>{DateTime.monday}, skipNext: true);
      expect(alarm.nextOccurrence(monday), DateTime(2026, 11, 30, 7, 30));
    });

    test('a disabled alarm has no next occurrence', () {
      expect(
        _alarm(enabled: false).nextOccurrence(DateTime(2026, 11, 16, 6)),
        isNull,
      );
    });

    test('an alarm due this minute still counts', () {
      final now = DateTime(2026, 11, 16, 7, 30);
      expect(_alarm().nextOccurrence(now), DateTime(2026, 11, 16, 7, 30));
    });
  });

  group('repeatLabel', () {
    test('names common patterns', () {
      expect(_alarm().repeatLabel, 'Once');
      expect(
        _alarm(repeatDays: <int>{1, 2, 3, 4, 5, 6, 7}).repeatLabel,
        'Every day',
      );
      expect(_alarm(repeatDays: <int>{1, 2, 3, 4, 5}).repeatLabel, 'Weekdays');
      expect(_alarm(repeatDays: <int>{6, 7}).repeatLabel, 'Weekends');
      expect(_alarm(repeatDays: <int>{1, 3, 5}).repeatLabel, 'Mon, Wed, Fri');
    });
  });

  test('an alarm round-trips through JSON', () {
    final alarm =
        _alarm(
          repeatDays: <int>{DateTime.tuesday, DateTime.thursday},
          skipNext: true,
        ).copyWith(
          wakeWindowMinutes: 30,
          volumeRampMinutes: 5,
          dismissal: AlarmDismissal.shake,
        );

    final decoded = Alarm.fromJson(alarm.toJson());

    expect(decoded.id, alarm.id);
    expect(decoded.label, alarm.label);
    expect(decoded.timeLabel, '07:30');
    expect(decoded.repeatDays, alarm.repeatDays);
    expect(decoded.wakeWindowMinutes, 30);
    expect(decoded.volumeRampMinutes, 5);
    expect(decoded.dismissal, AlarmDismissal.shake);
    expect(decoded.skipNext, isTrue);
  });
}
