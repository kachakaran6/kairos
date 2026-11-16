import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/moments/data/moment_repository.dart';
import 'package:kairos/features/moments/domain/moment.dart';

Moment _moment(String id) => Moment(
  id: id,
  title: 'Moment $id',
  targetUtc: DateTime.utc(2026, 12, 1),
  createdAtUtc: DateTime.utc(2026, 11, 16),
);

void main() {
  test('the in-memory repository persists saved moments', () async {
    final repository = InMemoryMomentRepository();
    await repository.saveAll(<Moment>[_moment('a'), _moment('b')]);

    final loaded = await repository.load();

    expect(loaded.map((moment) => moment.id), <String>['a', 'b']);
  });

  test('an empty repository loads nothing', () async {
    expect(await InMemoryMomentRepository().load(), isEmpty);
  });
}
