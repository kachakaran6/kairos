import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock_provider.dart';
import '../domain/alarm.dart';
import 'alarm_controller.dart';
import 'alarm_ring_page.dart';

/// Watches the alarm list while the app is open and rings a matching alarm.
///
/// Exact background scheduling through the platform notification service lands
/// in P1-05; this is the in-app ring that keeps the alarms honest today.
class AlarmWatcher extends ConsumerStatefulWidget {
  const AlarmWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AlarmWatcher> createState() => _AlarmWatcherState();
}

class _AlarmWatcherState extends ConsumerState<AlarmWatcher> {
  Timer? _ticker;
  final Set<String> _fired = <String>{};
  bool _ringing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_ringing || !mounted) return;
    final alarms = ref.read(alarmListProvider).value ?? const <Alarm>[];
    final nowLocal = ref.read(clockProvider).nowUtc().toLocal();

    for (final alarm in alarms) {
      if (!alarm.enabled) continue;
      if (alarm.hour != nowLocal.hour || alarm.minute != nowLocal.minute) {
        continue;
      }
      if (alarm.repeats && !alarm.repeatDays.contains(nowLocal.weekday)) {
        continue;
      }
      final key =
          '${alarm.id}-${nowLocal.year}-${nowLocal.month}-${nowLocal.day}-${nowLocal.hour}-${nowLocal.minute}';
      if (_fired.contains(key)) continue;
      _fired.add(key);

      final notifier = ref.read(alarmListProvider.notifier);
      if (alarm.skipNext) {
        await notifier.replace(alarm.copyWith(skipNext: false));
        continue;
      }

      _ringing = true;
      final result = await Navigator.of(context).push<AlarmRingResult>(
        MaterialPageRoute<AlarmRingResult>(
          builder: (_) => AlarmRingPage(
            label: alarm.label,
            timeLabel: alarm.timeLabel,
            dismissal: alarm.dismissal,
          ),
        ),
      );
      await notifier.markRung(alarm.id);
      if (result == AlarmRingResult.snooze) {
        final snoozeAt = nowLocal.add(const Duration(minutes: 5));
        await notifier.add(
          label: 'Snooze · ${alarm.label}',
          hour: snoozeAt.hour,
          minute: snoozeAt.minute,
        );
      }
      _ringing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
