import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/time/clock_provider.dart';
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
  const KairosShell({super.key});

  @override
  State<KairosShell> createState() => _KairosShellState();
}

class _KairosShellState extends State<KairosShell> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    return Scaffold(
      backgroundColor: kairos.colours.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          MomentListTab(upcoming: true),
          _NowPage(),
          MomentListTab(upcoming: false),
        ],
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

  static const List<_Instrument> _instruments = <_Instrument>[
    _Instrument('World clock', Icons.public, WorldClockPage()),
    _Instrument('Alarm', Icons.alarm, AlarmPage()),
    _Instrument('Timer', Icons.timer_outlined, TimerPage()),
    _Instrument('Stopwatch', Icons.speed_outlined, StopwatchPage()),
    _Instrument('Focus', Icons.center_focus_strong_outlined, FocusPage()),
  ];

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
      backgroundColor: colours.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LiveClockBlock(clock: ref.read(clockProvider))),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined, color: colours.textTertiary, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Divider(color: colours.border, height: 1, thickness: 1),
            const SizedBox(height: Space.lg),
            Text(
              'INSTRUMENTS',
              style: kairos.typeScale.section.copyWith(
                color: colours.textTertiary,
              ),
            ),
            const SizedBox(height: Space.md),
            _InstrumentGrid(instruments: _instruments),
            const SizedBox(height: Space.xxl),
            Text(
              'HAPPENING NOW',
              style: kairos.typeScale.section.copyWith(
                color: colours.textTertiary,
              ),
            ),
            const SizedBox(height: Space.sm),
            if (ongoing.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  'No moment in progress.',
                  style: kairos.typeScale.body.copyWith(
                    color: colours.textTertiary,
                  ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              time,
              style: kairos.typeScale.display.copyWith(
                fontSize: 64,
                height: 1,
                color: colours.textPrimary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: Space.xs),
            Text(
              seconds,
              style: kairos.typeScale.title.copyWith(
                fontSize: 24,
                color: colours.textTertiary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Text(
          date,
          style: kairos.typeScale.body.copyWith(
            color: colours.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _InstrumentGrid extends ConsumerWidget {
  const _InstrumentGrid({required this.instruments});

  final List<_Instrument> instruments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmListProvider).value ?? const [];
    final activeAlarm = alarms.where((a) => a.enabled).firstOrNull;
    final alarmSub = activeAlarm != null
        ? '${activeAlarm.hour.toString().padLeft(2, '0')}:${activeAlarm.minute.toString().padLeft(2, '0')}'
        : 'No alarm';

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _InstrumentTile(
                instrument: instruments[0],
                microValue: '8 cities',
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: _InstrumentTile(
                instrument: instruments[1],
                microValue: alarmSub,
                isLive: activeAlarm != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _InstrumentTile(
                instrument: instruments[2],
                microValue: 'Presets ready',
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: _InstrumentTile(
                instrument: instruments[3],
                microValue: '00:00.00',
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        _InstrumentTile(
          instrument: instruments[4],
          span: true,
          microValue: '25 min focus · Ready',
        ),
      ],
    );
  }
}

class _InstrumentTile extends StatelessWidget {
  const _InstrumentTile({
    required this.instrument,
    required this.microValue,
    this.span = false,
    this.isLive = false,
  });

  final _Instrument instrument;
  final String microValue;
  final bool span;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Material(
      color: colours.surface,
      borderRadius: RadiusTokens.lgRadius,
      child: InkWell(
        borderRadius: RadiusTokens.lgRadius,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => instrument.page)),
        child: Container(
          height: 96,
          width: span ? double.infinity : null,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.lgRadius,
            border: Border.all(
              color: isLive ? colours.accent.withValues(alpha: 0.4) : colours.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    instrument.icon,
                    size: 22,
                    color: isLive ? colours.accent : colours.accent.withValues(alpha: 0.8),
                  ),
                  if (span)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colours.surfaceElevated,
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Text(
                        'FOCUS MODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colours.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instrument.label,
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
                      fontWeight: isLive ? FontWeight.w600 : FontWeight.w500,
                      color: isLive ? colours.accent : colours.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Instrument {
  const _Instrument(this.label, this.icon, this.page);

  final String label;
  final IconData icon;
  final Widget page;
}
