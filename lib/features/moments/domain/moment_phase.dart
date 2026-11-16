import '../../../core/time/countdown.dart';
import 'moment.dart';

/// The tense a moment is in right now. One record, three states.
sealed class MomentPhase {
  const MomentPhase(this.moment);

  final Moment moment;

  DateTime get instant => moment.targetUtc;
}

/// Before the moment: a countdown.
final class NextPhase extends MomentPhase {
  const NextPhase(super.moment, this.days, this.sleeps);

  final int days;
  final int sleeps;
}

/// While the moment lasts: a progress bar and days remaining.
final class NowPhase extends MomentPhase {
  const NowPhase(
    super.moment, {
    required this.fraction,
    required this.dayNumber,
    required this.totalDays,
  });

  final double fraction;
  final int dayNumber;
  final int totalDays;

  int get percentage => (fraction * 100).floor();
}

/// After the moment: a count-up that never stops.
final class ThenPhase extends MomentPhase {
  const ThenPhase(super.moment, this.days);

  final int days;
}

/// Computes the tense at a UTC instant. Pure and testable.
MomentPhase phaseAt(Moment moment, DateTime nowUtc) {
  final start = moment.targetUtc.toUtc();
  final end = moment.endUtc?.toUtc();

  if (nowUtc.isBefore(start)) {
    return NextPhase(
      moment,
      Countdown.calendarDaysBetween(nowUtc, start),
      Countdown.sleepsBetween(nowUtc, start),
    );
  }

  if (end != null && nowUtc.isBefore(end)) {
    final dayNumber = Countdown.calendarDaysBetween(start, nowUtc) + 1;
    final totalDays = Countdown.calendarDaysBetween(start, end) + 1;
    return NowPhase(
      moment,
      fraction: Countdown.fractionComplete(start, end, nowUtc),
      dayNumber: dayNumber,
      totalDays: totalDays,
    );
  }

  return ThenPhase(moment, Countdown.calendarDaysBetween(start, nowUtc));
}
