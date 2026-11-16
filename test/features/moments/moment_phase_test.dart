import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/moments/domain/moment.dart';
import 'package:kairos/features/moments/domain/moment_phase.dart';

Moment _moment({DateTime? target, DateTime? end}) {
  return Moment(
    id: 'm1',
    title: 'Goa',
    targetUtc: target ?? DateTime.utc(2026, 11, 20),
    endUtc: end,
    createdAtUtc: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('phaseAt', () {
    test('is Next before the moment', () {
      final phase = phaseAt(
        _moment(target: DateTime.utc(2026, 11, 20, 6)),
        DateTime.utc(2026, 11, 16, 12),
      );

      expect(phase, isA<NextPhase>());
      final next = phase as NextPhase;
      expect(next.days, 4);
      expect(next.sleeps, 4);
    });

    test('is Now between start and end', () {
      final phase = phaseAt(
        _moment(
          target: DateTime.utc(2026, 11, 16),
          end: DateTime.utc(2026, 11, 20),
        ),
        DateTime.utc(2026, 11, 18, 12),
      );

      expect(phase, isA<NowPhase>());
      final now = phase as NowPhase;
      expect(now.dayNumber, 3);
      expect(now.totalDays, 5);
      expect(now.fraction, closeTo(0.625, 0.01));
    });

    test('is Then after the moment and counts up', () {
      final phase = phaseAt(
        _moment(target: DateTime.utc(2023, 5, 12)),
        DateTime.utc(2026, 11, 16),
      );

      expect(phase, isA<ThenPhase>());
      expect((phase as ThenPhase).days, 1284);
    });

    test('the exact zero instant is Then with zero days', () {
      final instant = DateTime.utc(2026, 11, 16, 12);
      final phase = phaseAt(_moment(target: instant), instant);

      expect(phase, isA<ThenPhase>());
      expect((phase as ThenPhase).days, 0);
    });

    test('an all-day moment with no end is Then the next day', () {
      final phase = phaseAt(
        _moment(target: DateTime.utc(2026, 11, 16)),
        DateTime.utc(2026, 11, 17, 0, 1),
      );

      expect(phase, isA<ThenPhase>());
    });
  });

  test('a moment round-trips through JSON', () {
    final moment =
        _moment(
          target: DateTime.utc(2026, 12, 24, 18, 30),
          end: DateTime.utc(2026, 12, 31),
        ).copyWith(
          subtitle: 'Home for Christmas',
          category: MomentCategory.festival,
          direction: MomentDirection.both,
          notes: 'Book the train',
          pinned: true,
        );

    final decoded = Moment.fromJson(moment.toJson());

    expect(decoded.id, moment.id);
    expect(decoded.title, moment.title);
    expect(decoded.subtitle, moment.subtitle);
    expect(decoded.targetUtc, moment.targetUtc);
    expect(decoded.endUtc, moment.endUtc);
    expect(decoded.category, MomentCategory.festival);
    expect(decoded.direction, MomentDirection.both);
    expect(decoded.notes, moment.notes);
    expect(decoded.pinned, isTrue);
  });
}
