import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/core/time/time_service.dart';
import 'package:kairos/features/alarm/data/alarm_repository.dart';
import 'package:kairos/features/alarm/domain/alarm.dart';
import 'package:kairos/features/alarm/presentation/alarm_controller.dart';
import 'package:kairos/features/alarm/presentation/alarm_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget wrap(AlarmRepository repository, Clock clock) {
    return ProviderScope(
      overrides: [alarmRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: KairosThemeData.dark(),
        home: AlarmPage(clock: clock),
      ),
    );
  }

  testWidgets('alarm list shows the empty state', (tester) async {
    final clock = FixedClock(DateTime.utc(2026, 11, 16, 2));
    await tester.pumpWidget(wrap(InMemoryAlarmRepository(), clock));
    await tester.pumpAndSettle();

    expect(find.text('No alarms yet'), findsOneWidget);
    expect(find.text('Alarm'), findsWidgets);
  });

  testWidgets('alarm list shows time, label and next ring', (tester) async {
    final clock = FixedClock(DateTime.utc(2026, 11, 16, 2));
    final alarm = Alarm(
      id: 'a1',
      label: 'Wake up',
      hour: 7,
      minute: 30,
      repeatDays: const <int>{DateTime.monday},
      createdAtUtc: DateTime.utc(2026, 11, 16),
    );
    await tester.pumpWidget(
      wrap(InMemoryAlarmRepository(<Alarm>[alarm]), clock),
    );
    await tester.pumpAndSettle();

    expect(find.text('07:30'), findsOneWidget);
    expect(find.text('Wake up'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.textContaining('rings in'), findsOneWidget);
  });

  testWidgets('the add button opens the editor', (tester) async {
    final clock = FixedClock(DateTime.utc(2026, 11, 16, 2));
    await tester.pumpWidget(wrap(InMemoryAlarmRepository(), clock));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New alarm'), findsOneWidget);
    expect(find.text('Wake window'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Preview the ring'), findsOneWidget);
  });
}
