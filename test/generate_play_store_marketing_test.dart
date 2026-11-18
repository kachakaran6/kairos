import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/core/design/radius_tokens.dart';
import 'package:kairos/core/time/clock_provider.dart';
import 'package:kairos/core/time/time_service.dart';
import 'package:kairos/core/widgets/widget_suite/widget_artwork_renderer.dart';
import 'package:kairos/features/alarm/data/alarm_repository.dart';
import 'package:kairos/features/alarm/domain/alarm.dart';
import 'package:kairos/features/alarm/presentation/alarm_controller.dart';
import 'package:kairos/features/alarm/presentation/alarm_page.dart';
import 'package:kairos/features/focus/presentation/focus_page.dart';
import 'package:kairos/features/moments/data/moment_repository.dart';
import 'package:kairos/features/moments/domain/moment.dart';
import 'package:kairos/features/moments/presentation/moment_controller.dart';
import 'package:kairos/features/moments/presentation/moment_detail_page.dart';
import 'package:kairos/features/stopwatch/presentation/stopwatch_page.dart';
import 'package:kairos/features/timer/presentation/timer_page.dart';
import 'package:kairos/features/widgets/presentation/widget_studio_page.dart';
import 'package:kairos/features/world_clock/presentation/world_clock_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storeAssetsDir = 'store_assets';
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
      enabled: true,
      createdAtUtc: fixedNow.subtract(const Duration(days: 5)),
    ),
  ];

  Future<void> loadRealFonts() async {
    const fontPaths = [
      'C:\\Windows\\Fonts\\arial.ttf',
      'C:\\Windows\\Fonts\\segoeui.ttf',
      'C:\\Windows\\Fonts\\georgia.ttf',
    ];

    for (final path in fontPaths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final name = path.split('\\').last.split('.').first;
        final loader = FontLoader(name);
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();
      }
    }
  }

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Directory(storeAssetsDir).createSync(recursive: true);
    await loadRealFonts();
  });

  Future<void> renderAndSave(
    WidgetTester tester,
    Widget child,
    String filename, {
    Size size = const Size(1080, 1920),
    List<Moment> moments = const <Moment>[],
    List<Alarm> alarms = const <Alarm>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final key = GlobalKey();

    final testApp = ProviderScope(
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
        theme: KairosThemeData.dark(fontFamily: 'Arial'),
        home: RepaintBoundary(key: key, child: child),
      ),
    );

    await tester.pumpWidget(testApp);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);

      final file = File('$storeAssetsDir/$filename');
      file.writeAsBytesSync(byteData!.buffer.asUint8List());
    });
  }

  Widget buildMarketingBanner({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    const bgDark = Color(0xFF100E0D);
    const textDark = Color(0xFFF4EFE8);
    const textMuted = Color(0xFF9E968D);
    const accent = Color(0xFFE8895A);

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        color: bgDark,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181513), Color(0xFF0C0A09)],
        ),
      ),
      child: Stack(
        children: [
          // Ambient warm glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: textDark,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Device / Card Mockup Frame
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161412),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(44),
                      topRight: Radius.circular(44),
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(42),
                      topRight: Radius.circular(42),
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  testWidgets('Generate Screenshot 01: Warm Precision Home Widgets', (
    tester,
  ) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Warm Precision',
      title: 'Crafted Like Luxury Dials.',
      subtitle:
          'Android & iOS widgets with live-ticking typography and zero battery cost.',
      child: Container(
        color: const Color(0xFF0F0D0B),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Widget 1: Clock Monolith
            Container(
              height: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFE8895A).withValues(alpha: 0.3),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '10:30',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14120E),
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        'TUE, 17 NOV • MUMBAI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE8895A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const WidgetProgressRing(
                    progress: 0.72,
                    accentColor: Color(0xFFE8895A),
                    size: 80,
                    strokeWidth: 6.5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Widget 2: Dashboard Combo
            Container(
              height: 220,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161412),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'NEXT MOMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4FACFE),
                          ),
                        ),
                        Text(
                          '42 days',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF4EFE8),
                          ),
                        ),
                        Text(
                          'Trip to Kyoto',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'serif',
                            color: Color(0xFF9E968D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 120, color: Colors.white12),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'ALARM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4FACFE),
                          ),
                        ),
                        Text(
                          '06:30',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFF4EFE8),
                          ),
                        ),
                        Text(
                          'Wake window 15m',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E968D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await renderAndSave(tester, widget, '01_warm_precision.png');
  });

  testWidgets('Generate Screenshot 02: Next Moment Countdown', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Zero Anxiety',
      title: 'Count Every Breath.',
      subtitle:
          'One hero moment at a time. Multi-scale units and milestone progression.',
      child: MomentDetailPage(momentId: sampleUpcomingMoments.first.id),
    );

    await renderAndSave(
      tester,
      widget,
      '02_count_every_breath.png',
      moments: sampleUpcomingMoments,
    );
  });

  testWidgets('Generate Screenshot 03: World Clock & 3D Earth Globe', (
    tester,
  ) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Planetary Time',
      title: 'Four Corners of Earth.',
      subtitle:
          '3D interactive globe with real-time astronomical solar terminator.',
      child: const WorldClockPage(),
    );

    await renderAndSave(tester, widget, '03_four_corners.png');
  });

  testWidgets('Generate Screenshot 04: Widget Studio', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Total Customization',
      title: 'Live on Your Home Screen.',
      subtitle:
          '10 curated Looks, Time Builder, Moment Builder, and custom typography.',
      child: const WidgetStudioPage(),
    );

    await renderAndSave(
      tester,
      widget,
      '04_widget_studio.png',
      moments: sampleUpcomingMoments,
      alarms: sampleAlarms,
    );
  });

  testWidgets('Generate Screenshot 05: Alarm Wake Window', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Circadian Awakening',
      title: 'The Rhythm of Time.',
      subtitle:
          'Gentle volume ramps, 90-minute sleep cycles, and mindful dismissal.',
      child: const AlarmPage(),
    );

    await renderAndSave(
      tester,
      widget,
      '05_alarm_wake_window.png',
      moments: sampleUpcomingMoments,
      alarms: sampleAlarms,
    );
  });

  testWidgets('Generate Screenshot 06: Deep Focus', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Deep Focus',
      title: 'Calm Productive Space.',
      subtitle:
          'Ambient acoustic soundscapes paired with 7-day streak density heat maps.',
      child: const FocusPage(),
    );

    await renderAndSave(tester, widget, '06_deep_focus.png');
  });

  testWidgets('Generate Screenshot 07: Stopwatch & Timers', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Monotonic Accuracy',
      title: 'Stopwatch & Precision Timers.',
      subtitle:
          'Split-lap analytics and zero-drift monotonic countdown timers.',
      child: const StopwatchPage(),
    );

    await renderAndSave(tester, widget, '07_precision_timers.png');
  });

  testWidgets('Generate Screenshot 08: Time Travel Slider', (tester) async {
    final widget = buildMarketingBanner(
      eyebrow: 'Time Travel Planner',
      title: 'Coordinate Across Timezones.',
      subtitle:
          'Dynamic meeting slider with sun arc elevation and working hour overlaps.',
      child: const TimerPage(),
    );

    await renderAndSave(tester, widget, '08_time_travel.png');
  });

  testWidgets('Generate Google Play Feature Graphic 1024x500', (tester) async {
    final featureGraphicWidget = Container(
      width: 1024,
      height: 500,
      decoration: const BoxDecoration(
        color: Color(0xFF100E0D),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF181513), Color(0xFF0C0A09)],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow
          Positioned(
            right: 80,
            top: 50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8895A).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 60),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE8895A,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFE8895A,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'WARM PRECISION CLOCK & MOMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE8895A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'KAIROS',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                          color: Color(0xFFF4EFE8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Time, held gently.',
                        style: TextStyle(
                          fontSize: 26,
                          fontFamily: 'serif',
                          color: Color(0xFFE8895A),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Minimalist home widgets, circadian awakening & planetary time.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF9E968D),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161412),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: const Color(
                            0xFFE8895A,
                          ).withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.48),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '10:30',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFF4EFE8),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8895A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TUE, 17 NOV',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF9E968D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await renderAndSave(
      tester,
      featureGraphicWidget,
      'feature_graphic.png',
      size: const Size(1024, 500),
    );
  });

  testWidgets('Generate Google Play App Icon 512x512', (tester) async {
    final appIconWidget = Container(
      width: 512,
      height: 512,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D0B),
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.2),
          radius: 1.2,
          colors: [Color(0xFF221F1C), Color(0xFF090807)],
        ),
        borderRadius: BorderRadius.circular(110),
        border: Border.all(
          color: const Color(0xFFE8895A).withValues(alpha: 0.4),
          width: 4.0,
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular golden hour track
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE8895A).withValues(alpha: 0.2),
                  width: 8.0,
                ),
              ),
            ),
            // Accent dial indicator
            Positioned(
              top: 96,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8895A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFFE8895A), blurRadius: 16),
                  ],
                ),
              ),
            ),
            // Kairos K monogram / minimal hour hand
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'K',
                  style: TextStyle(
                    fontSize: 140,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFF4EFE8),
                    fontFamily: 'serif',
                    height: 1.0,
                  ),
                ),
                Text(
                  'KAIROS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6.0,
                    color: Color(0xFFE8895A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await renderAndSave(
      tester,
      appIconWidget,
      'app_icon_512.png',
      size: const Size(512, 512),
    );
  });
}
