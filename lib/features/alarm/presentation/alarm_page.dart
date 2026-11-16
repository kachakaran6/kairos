import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../domain/alarm.dart';
import 'alarm_controller.dart';
import 'alarm_editor_page.dart';

/// Alarm instrument: the list of wake promises and their next ring.
class AlarmPage extends ConsumerWidget {
  const AlarmPage({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final alarms = ref.watch(alarmListProvider);
    final nowLocal = clock.nowUtc().toLocal();

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AlarmEditorPage()),
        ),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Alarm'),
      ),
      body: alarms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load alarms: $error')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.alarm,
                      size: Space.xxxl,
                      color: kairos.colours.textTertiary,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'No alarms yet',
                      style: kairos.typeScale.section,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'An alarm is a promise the phone keeps for you.',
                      style: kairos.typeScale.body.copyWith(
                        color: kairos.colours.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              Space.phoneMargin,
              Space.lg,
              Space.phoneMargin,
              Space.huge,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, index) => _AlarmCard(
              alarm: items[index],
              nowLocal: nowLocal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AlarmEditorPage(alarm: items[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({
    required this.alarm,
    required this.nowLocal,
    required this.onTap,
  });

  final Alarm alarm;
  final DateTime nowLocal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final dim = !alarm.enabled;

    return Material(
      color: kairos.colours.surface,
      borderRadius: RadiusTokens.lgRadius,
      child: InkWell(
        borderRadius: RadiusTokens.lgRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.md,
            Space.xs,
            Space.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      alarm.timeLabel,
                      style: kairos.typeScale.title.copyWith(
                        color: dim
                            ? kairos.colours.textTertiary
                            : kairos.colours.textPrimary,
                        fontFeatures: kairos.typeScale.display.fontFeatures,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      alarm.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kairos.typeScale.section.copyWith(
                        color: dim
                            ? kairos.colours.textTertiary
                            : kairos.colours.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      <String>[
                        alarm.repeatLabel,
                        if (alarm.wakeWindowMinutes > 0)
                          '${alarm.wakeWindowMinutes}-min window',
                        if (alarm.skipNext) 'next skipped',
                      ].join(' · '),
                      style: kairos.typeScale.caption.copyWith(
                        color: kairos.colours.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    if (alarm.enabled)
                      Text(
                        nextRingLabel(alarm, nowLocal),
                        style: kairos.typeScale.caption.copyWith(
                          color: kairos.colours.accent,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (_) =>
                    ref.read(alarmListProvider.notifier).toggle(alarm.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
