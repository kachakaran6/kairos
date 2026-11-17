import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/time/clock_provider.dart';
import '../../core/widgets/glass/atmospheric_background.dart';
import '../../core/widgets/surface_card.dart';
import '../../features/alarm/presentation/alarm_controller.dart';
import '../../features/alarm/presentation/alarm_page.dart';
import '../../features/focus/presentation/focus_page.dart';
import '../../features/moments/domain/moment_phase.dart';
import '../../features/moments/presentation/moment_controller.dart';
import '../../features/moments/presentation/moment_detail_page.dart';
import '../../features/moments/presentation/moment_list_tab.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/stopwatch/presentation/stopwatch_page.dart';
import '../../features/timer/presentation/timer_page.dart';
import '../../features/world_clock/presentation/world_clock_page.dart';
import 'kairos_bottom_nav.dart';

/// Three-tab shell: Next, Now, Then. Instruments live inside Now.
class KairosShell extends StatefulWidget {
  const KairosShell({super.key, this.initialIndex = 1});

  final int initialIndex;

  @override
  State<KairosShell> createState() => _KairosShellState();
}

class _KairosShellState extends State<KairosShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    return Scaffold(
      backgroundColor: kairos.colours.background,
      extendBody: true,
      body: AtmosphericBackground(
        child: IndexedStack(
          index: _index,
          children: const <Widget>[
            MomentListTab(upcoming: true),
            _NowPage(),
            MomentListTab(upcoming: false),
          ],
        ),
      ),
      bottomNavigationBar: KairosBottomNav(
        currentIndex: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _NowPage extends ConsumerWidget {
  const _NowPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final moments = ref.watch(momentListProvider).value ?? const [];
    final now = ref.read(clockProvider).nowUtc();
    final ongoing = moments
        .where((moment) => phaseAt(moment, now) is NowPhase)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.lg,
            Space.xl,
            110, // Clear of floating pill nav
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LiveClockBlock(clock: ref.read(clockProvider)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colours.surfaceElevated.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: colours.border, width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.settings,
                          color: colours.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text(
              'INSTRUMENTS',
              style: kairos.typeScale.label.copyWith(
                color: colours.textTertiary,
              ),
            ),
            const SizedBox(height: Space.sm),
            const _InstrumentBentoGrid(),
            const SizedBox(height: Space.xl),
            Text(
              'HAPPENING NOW',
              style: kairos.typeScale.label.copyWith(
                color: colours.textTertiary,
              ),
            ),
            const SizedBox(height: Space.sm),
            if (ongoing.isEmpty)
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hourglass,
                      size: 18,
                      color: colours.textTertiary,
                    ),
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        'No moment in progress.',
                        style: kairos.typeScale.body.copyWith(
                          color: colours.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final moment in ongoing) ...<Widget>[
                MomentCard(
                  moment: moment,
                  nowUtc: now,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MomentDetailPage(momentId: moment.id),
                    ),
                  ),
                ),
                const SizedBox(height: Space.xs),
              ],
          ],
        ),
      ),
    );
  }
}

class _LiveClockBlock extends StatefulWidget {
  const _LiveClockBlock({required this.clock});

  final dynamic clock;

  @override
  State<_LiveClockBlock> createState() => _LiveClockBlockState();
}

class _LiveClockBlockState extends State<_LiveClockBlock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = (widget.clock as dynamic).nowUtc() as DateTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = (widget.clock as dynamic).nowUtc() as DateTime);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final seconds = _now.second.toString().padLeft(2, '0');
    final months = const <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = const <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final date =
        '${weekdays[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                time,
                style: kairos.typeScale.display.copyWith(
                  fontSize: 76,
                  height: 1.0,
                  fontWeight: FontWeight.w200,
                  color: colours.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              Text(
                seconds,
                style: kairos.typeScale.title.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: colours.accent,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          date,
          style: kairos.typeScale.caption.copyWith(
            color: colours.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _InstrumentBentoGrid extends ConsumerWidget {
  const _InstrumentBentoGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmListProvider).value ?? const [];
    final activeAlarm = alarms.where((a) => a.enabled).firstOrNull;
    final alarmSub = activeAlarm != null
        ? '${activeAlarm.hour.toString().padLeft(2, '0')}:${activeAlarm.minute.toString().padLeft(2, '0')}'
        : 'No alarm';

    return Column(
      children: <Widget>[
        // Top row: World Clock & Alarm (prominent hero tiles)
        Row(
          children: <Widget>[
            Expanded(
              child: _BentoTile(
                title: 'World clock',
                microValue: '8 cities',
                icon: LucideIcons.globe,
                page: const WorldClockPage(),
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: _BentoTile(
                title: 'Alarm',
                microValue: alarmSub,
                icon: LucideIcons.alarmClock,
                isLive: activeAlarm != null,
                page: const AlarmPage(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),

        // Middle row: Timer & Stopwatch
        Row(
          children: <Widget>[
            const Expanded(
              child: _BentoTile(
                title: 'Timer',
                microValue: 'Presets ready',
                icon: LucideIcons.timer,
                page: TimerPage(),
              ),
            ),
            const SizedBox(width: Space.sm),
            const Expanded(
              child: _BentoTile(
                title: 'Stopwatch',
                microValue: '00:00.00',
                icon: LucideIcons.gauge,
                page: StopwatchPage(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),

        // Bottom row: Focus (wide card with live mini progress arc)
        _FocusBentoTile(),
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.title,
    required this.microValue,
    required this.icon,
    required this.page,
    this.isLive = false,
  });

  final String title;
  final String microValue;
  final IconData icon;
  final Widget page;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return SurfaceCard(
      isSelected: isLive,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => page)),
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 20,
                color: isLive ? colours.accent : colours.textSecondary,
              ),
              if (isLive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colours.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            title,
            style: kairos.typeScale.section.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colours.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            microValue,
            style: kairos.typeScale.caption.copyWith(
              fontSize: 12,
              fontWeight: isLive ? FontWeight.w600 : FontWeight.w400,
              color: isLive ? colours.accent : colours.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBentoTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return SurfaceCard(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const FocusPage())),
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 14),
      child: Row(
        children: <Widget>[
          // Mini progress arc
          SizedBox(
            width: 38,
            height: 38,
            child: CustomPaint(
              painter: _MiniArcPainter(
                progress: 0.65,
                accent: colours.accent,
                border: colours.border,
              ),
              child: Center(
                child: Icon(LucideIcons.focus, size: 16, color: colours.accent),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Focus',
                  style: kairos.typeScale.section.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colours.textPrimary,
                  ),
                ),
                Text(
                  '25 min session · Soundscapes ready',
                  style: kairos.typeScale.caption.copyWith(
                    fontSize: 12,
                    color: colours.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colours.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
            ),
            child: Text(
              'READY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colours.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniArcPainter extends CustomPainter {
  const _MiniArcPainter({
    required this.progress,
    required this.accent,
    required this.border,
  });

  final double progress;
  final Color accent;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final bgPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border;
}
