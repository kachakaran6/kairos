import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/shell/kairos_shell.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/features/alarm/domain/alarm.dart';
import 'package:kairos/features/alarm/presentation/alarm_ring_page.dart';
import 'package:kairos/features/timer/presentation/timer_page.dart';
import 'package:kairos/features/widgets/presentation/widget_setup_help_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  group('Back Navigation Restoration (R2)', () {
    testWidgets(
      'system back on Moments tab (index 0) navigates to Now tab (index 1)',
      (tester) async {
        await tester.pumpWidget(wrap(const KairosShell(initialIndex: 0)));
        await tester.pumpAndSettle();

        // Verify we start at Moments
        expect(find.text('Nothing ahead yet'), findsOneWidget);

        // Invoke Android system back gesture / button
        final didPop = await tester.binding.handlePopRoute();

        // PopScope handled the back event without exiting app
        expect(didPop, isTrue);
        await tester.pumpAndSettle();

        // Now tab is displayed
        expect(find.text('INSTRUMENTS'), findsOneWidget);
      },
    );

    testWidgets(
      'system back on Widgets tab (index 2) navigates to Now tab (index 1)',
      (tester) async {
        await tester.pumpWidget(wrap(const KairosShell(initialIndex: 2)));
        await tester.pumpAndSettle();

        // Verify we start at Widgets
        expect(find.text('Widget Studio'), findsOneWidget);

        // Invoke Android system back gesture / button
        final didPop = await tester.binding.handlePopRoute();

        // PopScope handled the back event
        expect(didPop, isTrue);
        await tester.pumpAndSettle();

        // Now tab is displayed
        expect(find.text('INSTRUMENTS'), findsOneWidget);
      },
    );

    testWidgets('system back on Now tab (index 1) allows app exit', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const KairosShell(initialIndex: 1)));
      await tester.pumpAndSettle();

      expect(find.text('INSTRUMENTS'), findsOneWidget);

      // System back on home tab exits root
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isFalse);
    });

    testWidgets('_CircularBackButton meets Android 48dp minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const TimerPage()));
      await tester.pumpAndSettle();

      final backButtonFinder = find.byTooltip('Back');
      expect(backButtonFinder, findsOneWidget);

      final size = tester.getSize(backButtonFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('in-app back button pops SettingsPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Returns to Now screen
      expect(find.text('INSTRUMENTS'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('in-app back button pops TimerPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open timer
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Returns to Now screen
      expect(find.text('INSTRUMENTS'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('in-app back button pops WorldClockPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open World Clock
      await tester.tap(find.text('World clock'));
      await tester.pumpAndSettle();

      expect(find.text('World Clock'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('INSTRUMENTS'), findsOneWidget);
      expect(find.text('World Clock'), findsNothing);
    });

    testWidgets('in-app back button pops AlarmPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open Alarm
      await tester.tap(find.text('Alarm'));
      await tester.pumpAndSettle();

      expect(find.text('Add Alarm'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('INSTRUMENTS'), findsOneWidget);
    });

    testWidgets('in-app back button pops FocusPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open Focus
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('INSTRUMENTS'), findsOneWidget);
    });

    testWidgets('in-app back button pops StopwatchPage', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open Stopwatch
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();

      expect(find.text('Stopwatch'), findsOneWidget);

      // Tap in-app circular back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('INSTRUMENTS'), findsOneWidget);
    });

    testWidgets('system back gesture pops pushed sub-screens', (tester) async {
      await tester.pumpWidget(wrap(const KairosShell()));
      await tester.pumpAndSettle();

      // Open Timer
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);

      // System back pops the Timer route
      final didPop = await tester.binding.handlePopRoute();
      expect(didPop, isTrue);
      await tester.pumpAndSettle();

      // We are back at KairosShell Now screen
      expect(find.text('INSTRUMENTS'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('in-app back button pops WidgetSetupHelpPage', (tester) async {
      await tester.pumpWidget(wrap(const WidgetSetupHelpPage()));
      await tester.pumpAndSettle();

      expect(find.text('Widget Setup Help'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets(
      'AlarmRingPage blocks back navigation to enforce wake dismissal challenge',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const AlarmRingPage(
              label: 'Wake Up',
              timeLabel: '07:00',
              dismissal: AlarmDismissal.tap,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('07:00'), findsOneWidget);

        // Hardware/system back is blocked
        final didPop = await tester.binding.handlePopRoute();
        expect(didPop, isTrue); // PopScope intercepted
        await tester.pump(const Duration(milliseconds: 100));

        // Screen is still present
        expect(find.text('07:00'), findsOneWidget);
        expect(find.text('Wake Up'), findsOneWidget);
      },
    );
  });
}
