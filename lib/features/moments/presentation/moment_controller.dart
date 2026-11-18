import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock_provider.dart';
import '../../../core/time/countdown.dart';
import '../../../core/widgets/widget_suite/widget_sync_service.dart';
import '../data/moment_repository.dart';
import '../domain/moment.dart';

final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => PreferencesMomentRepository(),
);

final momentListProvider =
    AsyncNotifierProvider<MomentListNotifier, List<Moment>>(
      MomentListNotifier.new,
    );

class MomentListNotifier extends AsyncNotifier<List<Moment>> {
  MomentRepository get _repository => ref.read(momentRepositoryProvider);

  @override
  Future<List<Moment>> build() async {
    final moments = await _repository.load();
    return _sorted(moments);
  }

  Future<List<Moment>> _getLatest() async {
    if (state.hasValue && state.value != null) {
      return state.value!;
    }
    return await _repository.load();
  }

  Future<void> add({
    required String title,
    String? subtitle,
    required DateTime targetUtc,
    DateTime? endUtc,
    bool isAllDay = true,
    MomentDirection direction = MomentDirection.down,
    MomentCategory category = MomentCategory.custom,
    CountingMode countingMode = CountingMode.days,
    String? notes,
  }) async {
    final now = ref.read(clockProvider).nowUtc();
    final moment = Moment(
      id: _newId(now),
      title: title.trim(),
      subtitle: _emptyToNull(subtitle),
      targetUtc: targetUtc.toUtc(),
      endUtc: endUtc?.toUtc(),
      isAllDay: isAllDay,
      direction: direction,
      category: category,
      countingMode: countingMode,
      notes: _emptyToNull(notes),
      createdAtUtc: now,
    );
    final current = await _getLatest();
    await _commit(<Moment>[...current, moment]);
  }

  Future<void> replace(Moment moment) async {
    final current = await _getLatest();
    final exists = current.any((item) => item.id == moment.id);
    if (!exists) {
      await _commit(<Moment>[...current, moment]);
      return;
    }
    await _commit(
      current.map((item) => item.id == moment.id ? moment : item).toList(),
    );
  }

  Future<void> remove(String id) async {
    final current = await _getLatest();
    await _commit(current.where((item) => item.id != id).toList());
  }

  Future<void> togglePinned(String id) async {
    final current = await _getLatest();
    await _commit(
      current
          .map(
            (item) =>
                item.id == id ? item.copyWith(pinned: !item.pinned) : item,
          )
          .toList(),
    );
  }

  Future<void> _commit(List<Moment> moments) async {
    final sorted = _sorted(moments);
    state = AsyncData(sorted);
    await _repository.saveAll(sorted);
    try {
      await ref.read(widgetSyncServiceProvider).syncAllWidgets();
    } catch (_) {
      // Safe fallback in test harnesses without home_widget platform channel
    }
  }

  List<Moment> _sorted(List<Moment> moments) {
    final copy = List<Moment>.of(moments);
    copy.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return a.targetUtc.compareTo(b.targetUtc);
    });
    return List<Moment>.unmodifiable(copy);
  }

  String _newId(DateTime now) {
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return '${now.microsecondsSinceEpoch.toRadixString(16)}-$random';
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
