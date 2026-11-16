import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/glass/glass.dart';
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

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Alarm',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: kairos.colours.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: kairos.colours.textPrimary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: FloatingActionButton.extended(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            splashColor: Colors.transparent,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AlarmEditorPage(),
                ),
              );
            },
            label: GlassContainer(
              intensity: GlassIntensity.primary,
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_alarm_rounded,
                    color: kairos.colours.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Alarm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kairos.colours.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: alarms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load alarms: $error')),
          data: (items) {
            if (items.isEmpty) {
              return GlassEmptyState(
                icon: Icons.alarm_rounded,
                heading: 'No alarms yet',
                description: 'An alarm is a promise the phone keeps for you.',
                primaryActionLabel: 'Add an alarm',
                onPrimaryAction: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlarmEditorPage(),
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

    return GlassCard(
      intensity: GlassIntensity.secondary,
      borderRadius: RadiusTokens.lgRadius,
      onTap: onTap,
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
    );
  }
}
