import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock_provider.dart';
import '../data/alarm_repository.dart';
import '../domain/alarm.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => PreferencesAlarmRepository(),
);

final alarmListProvider = AsyncNotifierProvider<AlarmListNotifier, List<Alarm>>(
  AlarmListNotifier.new,
);

class AlarmListNotifier extends AsyncNotifier<List<Alarm>> {
  AlarmRepository get _repository => ref.read(alarmRepositoryProvider);

  @override
  Future<List<Alarm>> build() async {
    final alarms = await _repository.load();
    return _sorted(alarms);
  }

  Future<void> add({
    required String label,
    required int hour,
    required int minute,
    Set<int> repeatDays = const <int>{},
    int wakeWindowMinutes = 0,
    int volumeRampMinutes = 0,
    AlarmDismissal dismissal = AlarmDismissal.tap,
  }) async {
    final now = ref.read(clockProvider).nowUtc();
    final alarm = Alarm(
      id: _newId(now),
      label: label.trim().isEmpty ? 'Alarm' : label.trim(),
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      wakeWindowMinutes: wakeWindowMinutes,
      volumeRampMinutes: volumeRampMinutes,
      dismissal: dismissal,
      createdAtUtc: now,
    );
    await _commit(<Alarm>[...?state.value, alarm]);
  }

  Future<void> replace(Alarm alarm) async {
    final current = state.value;
    if (current == null) return;
    await _commit(
      current.map((item) => item.id == alarm.id ? alarm : item).toList(),
    );
  }

  Future<void> remove(String id) async {
    final current = state.value;
    if (current == null) return;
    await _commit(current.where((alarm) => alarm.id != id).toList());
  }

  Future<void> toggle(String id) async {
    final current = state.value;
    if (current == null) return;
    await _commit(
      current
          .map(
            (alarm) => alarm.id == id
                ? alarm.copyWith(enabled: !alarm.enabled)
                : alarm,
          )
          .toList(),
    );
  }

  Future<void> skipNext(String id) async {
    final current = state.value;
    if (current == null) return;
    await _commit(
      current
          .map(
            (alarm) => alarm.id == id ? alarm.copyWith(skipNext: true) : alarm,
          )
          .toList(),
    );
  }

  /// Marks an alarm as rung: a one-off switches off, a repeat stays armed.
  Future<void> markRung(String id) async {
    final current = state.value;
    if (current == null) return;
    await _commit(
      current
          .map(
            (alarm) => alarm.id == id
                ? alarm.copyWith(enabled: alarm.repeats, skipNext: false)
                : alarm,
          )
          .toList(),
    );
  }

  Future<void> _commit(List<Alarm> alarms) async {
    final sorted = _sorted(alarms);
    state = AsyncData(sorted);
    await _repository.saveAll(sorted);
  }

  List<Alarm> _sorted(List<Alarm> alarms) {
    final copy = List<Alarm>.of(alarms)
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    return List<Alarm>.unmodifiable(copy);
  }

  String _newId(DateTime now) {
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return '${now.microsecondsSinceEpoch.toRadixString(16)}-$random';
  }
}

/// Formats the distance to the next ring for the alarm list.
String nextRingLabel(Alarm alarm, DateTime nowLocal) {
  final next = alarm.nextOccurrence(nowLocal);
  if (next == null) return 'Off';
  final delta = next.difference(nowLocal);
  if (delta.inMinutes < 60) {
    final minutes = max(delta.inMinutes, 1);
    return 'rings in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }
  if (delta.inHours < 24) {
    return 'rings in ${delta.inHours}h ${delta.inMinutes % 60}m';
  }
  return 'rings in ${delta.inDays} ${delta.inDays == 1 ? 'day' : 'days'}';
}
