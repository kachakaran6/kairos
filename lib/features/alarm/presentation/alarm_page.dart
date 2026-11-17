import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/kairos_empty_state.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/alarm.dart';
import 'alarm_controller.dart';
import 'alarm_editor_page.dart';

/// Alarm instrument: the list of wake promises with luxury typography,
/// custom animated switches, and next-ring accent pills.
class AlarmPage extends ConsumerWidget {
  const AlarmPage({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmListProvider);
    final nowLocal = clock.nowUtc().toLocal();

    return KairosScaffold(
      title: 'Alarm',
      showBackButton: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: PillButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AlarmEditorPage()),
            );
          },
          label: 'Add Alarm',
          icon: const Icon(LucideIcons.plus, size: 18),
          variant: PillButtonVariant.primary,
        ),
      ),
      body: alarms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load alarms: $error')),
        data: (items) {
          if (items.isEmpty) {
            return KairosEmptyState(
              iconType: EmptyStateIconType.general,
              title: 'No alarms yet',
              description:
                  'An alarm is a calm promise the phone keeps for your morning.',
              actionLabel: 'Add an alarm',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AlarmEditorPage(),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: Space.md),
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
    final colours = kairos.colours;
    final dim = !alarm.enabled;

    return SurfaceCard(
      isSelected: alarm.enabled,
      onTap: onTap,
      padding: const EdgeInsets.all(Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Large tabular time
                Text(
                  alarm.timeLabel,
                  style: kairos.typeScale.title.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: dim ? colours.textTertiary : colours.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alarm.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kairos.typeScale.section.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: dim ? colours.textTertiary : colours.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  <String>[
                    alarm.repeatLabel,
                    if (alarm.wakeWindowMinutes > 0)
                      '${alarm.wakeWindowMinutes}-min window',
                    if (alarm.skipNext) 'next skipped',
                  ].join(' · '),
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
                  ),
                ),
                if (alarm.enabled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colours.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                    child: Text(
                      nextRingLabel(alarm, nowLocal),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colours.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Custom tactile switch
          _CustomSwitch(
            value: alarm.enabled,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(alarmListProvider.notifier).toggle(alarm.id);
            },
          ),
        ],
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          color: value
              ? colours.accent
              : (colours.isDark ? colours.surfaceElevated : colours.border),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? colours.onAccent
                  : (colours.isDark ? colours.textTertiary : Colors.white),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
