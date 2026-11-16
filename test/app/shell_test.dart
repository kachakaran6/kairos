import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/shell/kairos_shell.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: KairosThemeData.dark(), home: child);
  }

  testWidgets('shell exposes Next, Now and Then', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    expect(find.text('Now'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Then'), findsOneWidget);
    expect(find.text('Instruments'), findsOneWidget);
  });

  testWidgets('Next tab shows its empty state', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing ahead yet'), findsOneWidget);
  });

  testWidgets('Then tab shows its empty state', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(find.text('Then'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing behind yet'), findsOneWidget);
  });

  testWidgets('world clock opteration is reachable from Now', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(find.text('World clock'));
    await tester.pumpAndSettle();

    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
  });

  testWidgets('timer is reachable from Now', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();

    expect(find.text('00:05:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
