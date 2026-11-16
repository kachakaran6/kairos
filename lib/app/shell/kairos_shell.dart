import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';
import '../../features/focus/presentation/focus_page.dart';
import '../../features/moments/domain/moment_phase.dart';
import '../../features/moments/presentation/moment_controller.dart';
import '../../features/moments/presentation/moment_detail_page.dart';
import '../../features/moments/presentation/moment_list_tab.dart';
import '../../features/stopwatch/presentation/stopwatch_page.dart';
import '../../features/timer/presentation/timer_page.dart';
import '../../features/world_clock/presentation/world_clock_page.dart';

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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          MomentListTab(upcoming: true),
          _NowPage(),
          MomentListTab(upcoming: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty),
            selectedIcon: Icon(Icons.hourglass_bottom),
            label: 'Next',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked),
            selectedIcon: Icon(Icons.radio_button_checked),
            label: 'Now',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Then',
          ),
        ],
      ),
    );
  }
}

class _NowPage extends ConsumerWidget {
  const _NowPage();

  static const List<_Instrument> _instruments = <_Instrument>[
    _Instrument('World clock', Icons.public, WorldClockPage()),
    _Instrument('Timer', Icons.timer_outlined, TimerPage()),
    _Instrument('Stopwatch', Icons.speed_outlined, StopwatchPage()),
    _Instrument('Focus', Icons.center_focus_strong_outlined, FocusPage()),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final moments = ref.watch(momentListProvider).value ?? const [];
    final now = ref.read(clockProvider).nowUtc();
    final ongoing = moments
        .where((moment) => phaseAt(moment, now) is NowPhase)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Now')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.phoneMargin,
            vertical: Space.lg,
          ),
          children: <Widget>[
            Text('Instruments', style: kairos.typeScale.section),
            const SizedBox(height: Space.md),
            for (final instrument in _instruments) ...<Widget>[
              _InstrumentRow(instrument: instrument),
              const SizedBox(height: Space.xs),
            ],
            const SizedBox(height: Space.xxl),
            Text('Happening now', style: kairos.typeScale.section),
            const SizedBox(height: Space.sm),
            if (ongoing.isEmpty)
              Text(
                'Ongoing moments appear here once you add one with an end date.',
                style: kairos.typeScale.body.copyWith(
                  color: kairos.colours.textSecondary,
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

class _InstrumentRow extends StatelessWidget {
  const _InstrumentRow({required this.instrument});

  final _Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Material(
      color: kairos.colours.surface,
      borderRadius: RadiusTokens.lgRadius,
      child: InkWell(
        borderRadius: RadiusTokens.lgRadius,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => instrument.page)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          child: Row(
            children: <Widget>[
              Icon(instrument.icon, color: kairos.colours.textPrimary),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(instrument.label, style: kairos.typeScale.section),
              ),
              Icon(Icons.chevron_right, color: kairos.colours.textTertiary),
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
