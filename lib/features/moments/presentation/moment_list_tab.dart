import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/countdown.dart';
import '../domain/moment.dart';
import '../domain/moment_phase.dart';
import 'moment_controller.dart';
import 'moment_detail_page.dart';
import 'moment_editor_page.dart';

/// Timeline tab. `upcoming` selects Next (true) or Then (false).
class MomentListTab extends ConsumerWidget {
  const MomentListTab({super.key, required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kairos = KairosTheme.of(context);
    final moments = ref.watch(momentListProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final title = upcoming ? 'Next' : 'Then';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: upcoming
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MomentEditorPage(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Moment'),
            )
          : null,
      body: moments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load moments: $error')),
        data: (items) {
          final visible = items
              .where((moment) {
                final phase = phaseAt(moment, now);
                return upcoming ? phase is! ThenPhase : phase is ThenPhase;
              })
              .toList(growable: false);

          if (visible.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      upcoming ? Icons.hourglass_empty : Icons.history,
                      size: Space.xxxl,
                      color: kairos.colours.textTertiary,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      upcoming ? 'Nothing ahead yet' : 'Nothing behind yet',
                      textAlign: TextAlign.center,
                      style: kairos.typeScale.section,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      upcoming
                          ? 'Add a moment and it counts down here.'
                          : 'Moments that pass move here and count up forever.',
                      textAlign: TextAlign.center,
                      style: kairos.typeScale.body.copyWith(
                        color: kairos.colours.textSecondary,
                      ),
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
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, index) => MomentCard(
              moment: visible[index],
              nowUtc: now,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MomentDetailPage(momentId: visible[index].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.moment,
    required this.nowUtc,
    required this.onTap,
  });

  final Moment moment;
  final DateTime nowUtc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final phase = phaseAt(moment, nowUtc);
    final countdown = Countdown.format(nowUtc, moment.targetUtc);

    final (String value, String unit) = switch (phase) {
      NextPhase() => (countdown.value, countdown.unit),
      NowPhase(:final dayNumber, :final totalDays) => (
        '$dayNumber',
        'of $totalDays days',
      ),
      ThenPhase() => (countdown.value, '${countdown.unit} since'),
    };

    return Material(
      color: kairos.colours.surface,
      borderRadius: RadiusTokens.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _categoryLabel(moment.category),
                      style: kairos.typeScale.micro.copyWith(
                        color: kairos.colours.textTertiary,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      moment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kairos.typeScale.section,
                    ),
                    if (phase is NowPhase) ...<Widget>[
                      const SizedBox(height: Space.xs),
                      ClipRRect(
                        borderRadius: RadiusTokens.pillRadius,
                        child: LinearProgressIndicator(
                          value: phase.fraction,
                          minHeight: Space.xxs,
                          backgroundColor: kairos.colours.accentMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    value,
                    style: kairos.typeScale.title.copyWith(
                      color: kairos.colours.textPrimary,
                    ),
                  ),
                  Text(
                    unit,
                    style: kairos.typeScale.caption.copyWith(
                      color: kairos.colours.textSecondary,
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

  static String _categoryLabel(MomentCategory category) =>
      category.name.toUpperCase();
}
