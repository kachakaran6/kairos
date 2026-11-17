import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/features/focus/presentation/focus_page.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: KairosThemeData.light(), home: child);
}

void main() {
  testWidgets(
    'FocusPage shows presets, timer, ambient soundscapes, and streak heat map',
    (tester) async {
      await tester.pumpWidget(_wrap(const FocusPage()));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsWidgets);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('00:25:00'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);
      expect(find.text('Ambient Soundscape'), findsOneWidget);
      expect(find.text('Gentle Rain'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Activity & Streak'), findsOneWidget);
      expect(find.text('4-Day Streak'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      // Switch preset to 45 min
      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
      expect(find.text('00:45:00'), findsOneWidget);

      // Toggle start
      await tester.tap(find.text('Start Focus'));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      // Toggle pause
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Start Focus'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('00:45:00'), findsOneWidget);
    },
  );
}
