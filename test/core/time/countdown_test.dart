import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/time/countdown.dart';

void main() {
  group('Countdown.format', () {
    test('the exact zero instant reads 0 days', () {
      final now = DateTime.utc(2026, 11, 16, 12);
      final text = Countdown.format(now, now);
      expect(text.value, '0');
      expect(text.unit, 'days');
    });

    test('counts calendar days before a moment', () {
      final now = DateTime.utc(2026, 11, 16, 23, 59);
      final target = DateTime.utc(2026, 11, 27, 0, 1);
      final text = Countdown.format(now, target);
      expect(text.value, '11');
      expect(text.unit, 'days');
    });

    test('counts up after a moment', () {
      final now = DateTime.utc(2026, 11, 16);
      final target = DateTime.utc(2023, 5, 12);
      final text = Countdown.format(now, target);
      expect(text.value, '1,284');
      expect(text.unit, 'days');
    });

    test('a moment less than an hour ahead reads minutes', () {
      final now = DateTime.utc(2026, 11, 16, 12);
      final target = now.add(const Duration(minutes: 20));
      final text = Countdown.format(now, target);
      expect(text.value, '20');
      expect(text.unit, 'minutes');
    });

    test('sleeps are calendar nights', () {
      final now = DateTime.utc(2026, 11, 16, 22);
      final target = DateTime.utc(2026, 11, 27, 7);
      final text = Countdown.format(now, target, mode: CountingMode.sleeps);
      expect(text.value, '11');
      expect(text.unit, 'sleeps');
    });

    test('crosses a DST change without losing a day', () {
      // US DST ends 2026-11-01. 48 UTC hours span 2 calendar days.
      final now = DateTime.utc(2026, 10, 31, 12);
      final target = DateTime.utc(2026, 11, 2, 12);
      expect(Countdown.calendarDaysBetween(now, target), 2);
    });

    test('crosses the spring DST change without gaining a day', () {
      // US DST starts 2026-03-08.
      final now = DateTime.utc(2026, 3, 7, 12);
      final target = DateTime.utc(2026, 3, 9, 12);
      expect(Countdown.calendarDaysBetween(now, target), 2);
    });

    test('a Friday deadline read on Monday is five weekdays', () {
      final monday = DateTime.utc(2026, 11, 16);
      final friday = DateTime.utc(2026, 11, 20);
      final text = Countdown.format(
        monday,
        friday,
        mode: CountingMode.weekdays,
      );
      expect(text.value, '5');
      expect(text.unit, 'weekdays');
    });

    test('groups thousands with commas', () {
      final now = DateTime.utc(2026, 11, 16);
      final target = DateTime.utc(2023, 5, 12);
      expect(Countdown.format(now, target).value, '1,284');
    });
  });

  group('progress', () {
    test('percentage clamps to 100 after the end', () {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 11);
      expect(
        Countdown.percentageComplete(start, end, DateTime.utc(2026, 2, 1)),
        100,
      );
    });

    test('percentage is zero before the start', () {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 11);
      expect(
        Countdown.percentageComplete(start, end, DateTime.utc(2025, 12, 1)),
        0,
      );
    });

    test('halfway is 50 per cent', () {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 11);
      expect(
        Countdown.percentageComplete(start, end, DateTime.utc(2026, 1, 6)),
        50,
      );
    });

    test('x of y formats both numbers', () {
      expect(Countdown.xOfY(12, 30), '12 of 30');
      expect(Countdown.xOfY(1200, 3000), '1,200 of 3,000');
    });
  });
}
