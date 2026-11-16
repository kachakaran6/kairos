import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/alarm.dart';

/// Local-first alarm storage. Replaced by the Drift alarm table in P1-01.
abstract interface class AlarmRepository {
  Future<List<Alarm>> load();

  Future<void> saveAll(List<Alarm> alarms);
}

class PreferencesAlarmRepository implements AlarmRepository {
  static const String storageKey = 'kairos.alarms.v1';

  @override
  Future<List<Alarm>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Alarm>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Alarm>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Alarm.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(alarms.map((alarm) => alarm.toJson()).toList()),
    );
  }
}

class InMemoryAlarmRepository implements AlarmRepository {
  InMemoryAlarmRepository([List<Alarm> seed = const <Alarm>[]])
    : _alarms = List<Alarm>.of(seed);

  List<Alarm> _alarms;

  @override
  Future<List<Alarm>> load() async => List<Alarm>.unmodifiable(_alarms);

  @override
  Future<void> saveAll(List<Alarm> alarms) async {
    _alarms = List<Alarm>.of(alarms);
  }
}
