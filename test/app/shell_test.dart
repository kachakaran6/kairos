import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/shell/kairos_bottom_nav.dart';
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

  testWidgets('shell exposes Moments, Now and Widgets', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));
    await tester.pumpAndSettle();

    expect(find.text('Now'), findsWidgets);
    expect(find.text('Moments'), findsWidgets);
    expect(find.text('Widgets'), findsWidgets);
    expect(find.text('INSTRUMENTS'), findsOneWidget);
  });

  testWidgets('Moments tab shows Upcoming and Memories empty states', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(
      find.descendant(
        of: find.byType(KairosBottomNav),
        matching: find.text('Moments'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing ahead yet'), findsOneWidget);

    // Switch to Memories
    await tester.tap(find.text('Memories'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing behind yet'), findsOneWidget);
  });

  testWidgets('Widgets tab is reachable from bottom nav', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(
      find.descendant(
        of: find.byType(KairosBottomNav),
        matching: find.text('Widgets'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Widget Studio'), findsOneWidget);
  });

  testWidgets('world clock opteration is reachable from Now', (tester) async {
    await tester.pumpWidget(wrap(const KairosShell()));

    await tester.tap(find.text('World clock'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
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
