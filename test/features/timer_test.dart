import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/features/timer/presentation/timer_page.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: KairosThemeData.dark(), home: child);
  }

  testWidgets('timer starts, ticks and pauses', (tester) async {
    await tester.pumpWidget(wrap(const TimerPage(initialMinutes: 1)));

    expect(find.text('00:01:00'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:00:59'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('00:00:59'), findsOneWidget);
  });

  testWidgets('preset switches the remaining time', (tester) async {
    await tester.pumpWidget(wrap(const TimerPage()));

    await tester.tap(find.text('10 min'));
    await tester.pump();

    expect(find.text('00:10:00'), findsOneWidget);
  });
}
