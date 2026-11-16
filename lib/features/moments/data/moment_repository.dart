import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/moment.dart';

/// Local-first moment storage. Swapped for Drift in P1-01; callers depend only
/// on this interface.
abstract interface class MomentRepository {
  Future<List<Moment>> load();

  Future<void> saveAll(List<Moment> moments);
}

class PreferencesMomentRepository implements MomentRepository {
  static const String storageKey = 'kairos.moments.v1';

  @override
  Future<List<Moment>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <Moment>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Moment>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Moment.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(List<Moment> moments) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      moments.map((moment) => moment.toJson()).toList(growable: false),
    );
    await prefs.setString(storageKey, raw);
  }
}

/// Test double that keeps moments for the lifetime of the object.
class InMemoryMomentRepository implements MomentRepository {
  InMemoryMomentRepository([List<Moment> seed = const <Moment>[]])
    : _moments = List<Moment>.of(seed);

  List<Moment> _moments;

  @override
  Future<List<Moment>> load() async => List<Moment>.unmodifiable(_moments);

  @override
  Future<void> saveAll(List<Moment> moments) async {
    _moments = List<Moment>.of(moments);
  }
}
