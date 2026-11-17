import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/shell/kairos_shell.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/core/time/clock_provider.dart';
import 'package:kairos/core/time/time_service.dart';
import 'package:kairos/features/alarm/data/alarm_repository.dart';
import 'package:kairos/features/alarm/domain/alarm.dart';
import 'package:kairos/features/alarm/presentation/alarm_controller.dart';
import 'package:kairos/features/alarm/presentation/alarm_editor_page.dart';
import 'package:kairos/features/alarm/presentation/alarm_page.dart';
import 'package:kairos/features/alarm/presentation/alarm_ring_page.dart';
import 'package:kairos/features/focus/presentation/focus_page.dart';
import 'package:kairos/features/moments/data/moment_repository.dart';
import 'package:kairos/features/moments/domain/moment.dart';
import 'package:kairos/features/moments/presentation/moment_controller.dart';
import 'package:kairos/features/moments/presentation/moment_detail_page.dart';
import 'package:kairos/features/moments/presentation/moment_editor_page.dart';
import 'package:kairos/features/moments/presentation/zero_moment_page.dart';
import 'package:kairos/features/settings/presentation/settings_page.dart';
import 'package:kairos/features/stopwatch/presentation/stopwatch_page.dart';
import 'package:kairos/features/timer/presentation/timer_page.dart';
import 'package:kairos/features/world_clock/presentation/world_clock_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const artifactDir =
      r'C:\Users\karan\.gemini\antigravity\brain\bde0f4dc-cf1e-4dbc-815a-3992ba7c9ac2\screenshots';
  const repoDir = 'screenshots';

  final fixedNow = DateTime.utc(2026, 11, 17, 10, 30);
  final fixedClock = FixedClock(fixedNow);

  final sampleUpcomingMoments = <Moment>[
    Moment(
      id: 'm1',
      title: 'Trip to Kyoto',
      subtitle: 'Autumn foliage & temple exploration',
      targetUtc: fixedNow.add(const Duration(days: 42, hours: 8)),
      category: MomentCategory.travel,
      notes: 'Book Shinkansen tickets and pack warm coats.',
      createdAtUtc: fixedNow.subtract(const Duration(days: 10)),
      pinned: true,
    ),
    Moment(
      id: 'm2',
      title: "Karan's Birthday",
      subtitle: 'Milestone celebration with friends',
      targetUtc: fixedNow.add(const Duration(days: 5, hours: 14)),
      category: MomentCategory.birthday,
      createdAtUtc: fixedNow.subtract(const Duration(days: 20)),
    ),
    Moment(
      id: 'm3',
      title: 'Launch Kairos v1.0',
      subtitle: 'Apple-grade production release',
      targetUtc: fixedNow.add(const Duration(days: 14)),
      category: MomentCategory.work,
      createdAtUtc: fixedNow.subtract(const Duration(days: 15)),
    ),
  ];

  final samplePastMoments = <Moment>[
    Moment(
      id: 'p1',
      title: 'First Kairos Commit',
      subtitle: 'The journey to build a calm clock app began',
      targetUtc: fixedNow.subtract(const Duration(days: 45, hours: 12)),
      direction: MomentDirection.up,
      category: MomentCategory.work,
      createdAtUtc: fixedNow.subtract(const Duration(days: 50)),
      pinned: true,
    ),
    Moment(
      id: 'p2',
      title: 'Graduation Day',
      subtitle: 'Computer Science & Systems Architecture',
      targetUtc: fixedNow.subtract(const Duration(days: 520)),
      direction: MomentDirection.up,
      category: MomentCategory.exam,
      createdAtUtc: fixedNow.subtract(const Duration(days: 525)),
    ),
  ];

  final sampleAlarms = <Alarm>[
    Alarm(
      id: 'a1',
      label: 'Morning Run & Coffee',
      hour: 6,
      minute: 30,
      repeatDays: const <int>{1, 2, 3, 4, 5},
      wakeWindowMinutes: 15,
      volumeRampMinutes: 5,
      dismissal: AlarmDismissal.shake,
      createdAtUtc: fixedNow,
    ),
    Alarm(
      id: 'a2',
      label: 'Deep Focus & Standup',
      hour: 8,
      minute: 45,
      repeatDays: const <int>{1, 2, 3, 4, 5},
      wakeWindowMinutes: 0,
      volumeRampMinutes: 1,
      dismissal: AlarmDismissal.math,
      createdAtUtc: fixedNow,
    ),
    Alarm(
      id: 'a3',
      label: 'Weekend Rest & Read',
      hour: 9,
      minute: 15,
      repeatDays: const <int>{6, 7},
      wakeWindowMinutes: 30,
      volumeRampMinutes: 10,
      dismissal: AlarmDismissal.tap,
      enabled: false,
      createdAtUtc: fixedNow,
    ),
  ];

  Future<void> loadRealFonts() async {
    const fontDir = r'C:\flutter\bin\cache\artifacts\material_fonts';

    // Load MaterialIcons
    final iconFile = File('$fontDir\\materialicons-regular.otf');
    if (iconFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(
        Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)),
      );
      await iconLoader.load();
    }

    // Load Roboto regular, bold, medium, light
    final robotoFiles = [
      'roboto-regular.ttf',
      'roboto-bold.ttf',
      'roboto-medium.ttf',
      'roboto-light.ttf',
    ];
    final robotoLoader = FontLoader('Roboto');
    for (final file in robotoFiles) {
      final f = File('$fontDir\\$file');
      if (f.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(f.readAsBytesSync().buffer)),
        );
      }
    }
    await robotoLoader.load();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Directory(repoDir).createSync(recursive: true);
    Directory(artifactDir).createSync(recursive: true);
    await loadRealFonts();
  });

  Future<void> capture(
    WidgetTester tester, {
    required Widget child,
    required String name,
    required bool isDark,
    List<Moment> moments = const <Moment>[],
    List<Alarm> alarms = const <Alarm>[],
  }) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;

    final key = GlobalKey();

    final widget = ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(fixedClock),
        momentRepositoryProvider.overrideWithValue(
          InMemoryMomentRepository(moments),
        ),
        alarmRepositoryProvider.overrideWithValue(
          InMemoryAlarmRepository(alarms),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: isDark
            ? KairosThemeData.dark(fontFamily: 'Roboto')
            : KairosThemeData.light(fontFamily: 'Roboto'),
        home: RepaintBoundary(key: key, child: child),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final repoPath = '$repoDir/$name.png';
      final artifactPath = '$artifactDir/$name.png';

      File(repoPath).writeAsBytesSync(bytes);
      File(artifactPath).writeAsBytesSync(bytes);
    });
  }

  group('Capture Complete Kairos Screenshots in Light & Dark Mode', () {
    for (final isDark in [false, true]) {
      final modeSuffix = isDark ? 'dark' : 'light';

      testWidgets('01_now_tab_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '01_now_tab_$modeSuffix',
          isDark: isDark,
          child: const KairosShell(initialIndex: 1),
          moments: sampleUpcomingMoments,
          alarms: sampleAlarms,
        );
      });

      testWidgets('02_next_empty_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '02_next_empty_$modeSuffix',
          isDark: isDark,
          child: const KairosShell(initialIndex: 0),
          moments: const [],
        );
      });

      testWidgets('03_next_populated_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '03_next_populated_$modeSuffix',
          isDark: isDark,
          child: const KairosShell(initialIndex: 0),
          moments: sampleUpcomingMoments,
        );
      });

      testWidgets('04_then_empty_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '04_then_empty_$modeSuffix',
          isDark: isDark,
          child: const KairosShell(initialIndex: 2),
          moments: const [],
        );
      });

      testWidgets('05_then_populated_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '05_then_populated_$modeSuffix',
          isDark: isDark,
          child: const KairosShell(initialIndex: 2),
          moments: samplePastMoments,
        );
      });

      testWidgets('06_world_clock_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '06_world_clock_$modeSuffix',
          isDark: isDark,
          child: WorldClockPage(clock: fixedClock),
        );
      });

      testWidgets('07_alarm_list_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '07_alarm_list_$modeSuffix',
          isDark: isDark,
          child: AlarmPage(clock: fixedClock),
          alarms: sampleAlarms,
        );
      });

      testWidgets('08_alarm_editor_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '08_alarm_editor_$modeSuffix',
          isDark: isDark,
          child: AlarmEditorPage(alarm: sampleAlarms.first),
        );
      });

      testWidgets('09_alarm_ring_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '09_alarm_ring_$modeSuffix',
          isDark: isDark,
          child: const AlarmRingPage(
            label: 'Morning Run & Coffee',
            timeLabel: '06:30',
            volumeRampMinutes: 5,
            dismissal: AlarmDismissal.shake,
          ),
        );
      });

      testWidgets('10_timer_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '10_timer_$modeSuffix',
          isDark: isDark,
          child: const TimerPage(initialMinutes: 25),
        );
      });

      testWidgets('11_stopwatch_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '11_stopwatch_$modeSuffix',
          isDark: isDark,
          child: const StopwatchPage(),
        );
      });

      testWidgets('12_focus_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '12_focus_$modeSuffix',
          isDark: isDark,
          child: const FocusPage(),
        );
      });

      testWidgets('13_moment_editor_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '13_moment_editor_$modeSuffix',
          isDark: isDark,
          child: MomentEditorPage(moment: sampleUpcomingMoments.first),
        );
      });

      testWidgets('14_moment_detail_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '14_moment_detail_$modeSuffix',
          isDark: isDark,
          child: MomentDetailPage(momentId: sampleUpcomingMoments.first.id),
          moments: sampleUpcomingMoments,
        );
      });

      testWidgets('15_zero_moment_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '15_zero_moment_$modeSuffix',
          isDark: isDark,
          child: ZeroMomentPage(moment: sampleUpcomingMoments.first),
        );
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('16_settings_$modeSuffix', (tester) async {
        await capture(
          tester,
          name: '16_settings_$modeSuffix',
          isDark: isDark,
          child: const SettingsPage(),
        );
      });
    }
  });
}
