import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/shell/kairos_shell.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: KairosThemeData.dark(), home: child),
    );
  }

  testWidgets('shell exposes Next, Now and Then', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));
    await tester.pumpAndSettle();

    expect(find.text('Now'), findsWidgets);
    expect(find.text('Next'), findsWidgets);
    expect(find.text('Then'), findsWidgets);
    expect(find.text('Instruments'), findsOneWidget);
  });

  testWidgets('Next tab shows its empty state', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Next'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing ahead yet'), findsOneWidget);
  });

  testWidgets('Then tab shows its empty state', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Then'),
      ),
    );
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
