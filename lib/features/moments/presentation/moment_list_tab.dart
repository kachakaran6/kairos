import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/time/countdown.dart';
import '../../../core/widgets/glass/glass.dart';
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
    final colours = kairos.colours;
    final moments = ref.watch(momentListProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final title = upcoming ? 'Next' : 'Then';

    return Scaffold(
      backgroundColor: colours.background,
      body: SafeArea(
        child: moments.when(
          loading: () => _LoadingSkeleton(upcoming: upcoming, title: title),
          error: (error, _) => _ErrorState(
            title: title,
            upcoming: upcoming,
            onRetry: () => ref.invalidate(momentListProvider),
          ),
          data: (items) {
            final visible = items
                .where((moment) {
                  final phase = phaseAt(moment, now);
                  return upcoming ? phase is! ThenPhase : phase is ThenPhase;
                })
                .toList(growable: false);

            if (visible.isEmpty) {
              return _EmptyState(
                upcoming: upcoming,
                title: title,
                onAdd: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MomentEditorPage(),
                  ),
                ),
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.phoneMargin,
                      Space.xs,
                      Space.phoneMargin,
                      Space.lg,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: kairos.typeScale.title.copyWith(
                              color: colours.textPrimary,
                            ),
                          ),
                        ),
                        if (upcoming)
                          IconButton(
                            icon: Icon(Icons.add, color: colours.textPrimary),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MomentEditorPage(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final isBottom = index == visible.length - 1;
                    final bottomPadding = isBottom ? 110.0 : 0.0;

                    if (upcoming && index == 0) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          Space.phoneMargin,
                          0,
                          Space.phoneMargin,
                          bottomPadding,
                        ),
                        child: _GlassHeroMomentCard(
                          moment: visible[0],
                          nowUtc: now,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  MomentDetailPage(momentId: visible[0].id),
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        Space.phoneMargin,
                        0,
                        Space.phoneMargin,
                        bottomPadding,
                      ),
                      child: MomentCard(
                        moment: visible[index],
                        nowUtc: now,
                        isTimeline: !upcoming,
                        isLast: isBottom,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                MomentDetailPage(momentId: visible[index].id),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.upcoming, required this.title});

  final bool upcoming;
  final String title;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.phoneMargin,
              Space.xs,
              Space.phoneMargin,
              Space.lg,
            ),
            child: Text(
              title,
              style: kairos.typeScale.title.copyWith(
                color: colours.textPrimary,
              ),
            ),
          ),
        ),
        SliverList.separated(
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.phoneMargin),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: colours.surface,
                borderRadius: RadiusTokens.lgRadius,
                border: Border.all(color: colours.border),
              ),
            ),
          ),
          separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.upcoming,
    required this.title,
    required this.onAdd,
  });

  final bool upcoming;
  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: upcoming ? Icons.arrow_outward_rounded : Icons.history_rounded,
      heading: upcoming ? 'Nothing ahead yet' : 'Nothing behind yet',
      description: upcoming
          ? 'Add the day you are counting to. It will sit here, at the top of your day, until it happens.'
          : 'Moments move here once they pass, and count up from then on. Add one that already happened.',
      primaryActionLabel: upcoming ? 'Add a moment' : 'Add a past date',
      onPrimaryAction: onAdd,
      secondaryActionLabel: upcoming ? 'See how moments work' : null,
      onSecondaryAction: upcoming
          ? () => _showHowMomentsWorkSheet(context)
          : null,
    );
  }

  void _showHowMomentsWorkSheet(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    showGlassBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Moments Work',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colours.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _MomentExplainerRow(
              icon: Icons.arrow_outward_rounded,
              title: 'Next: Count Down',
              description:
                  'Track upcoming exams, trips, anniversaries and milestones as they draw closer.',
            ),
            const SizedBox(height: 14),
            const _MomentExplainerRow(
              icon: Icons.radio_button_checked_rounded,
              title: 'Now: Live Clock & Instruments',
              description:
                  'Focus on today with active ongoing moments, alarms, world clock and timers.',
            ),
            const SizedBox(height: 14),
            const _MomentExplainerRow(
              icon: Icons.history_rounded,
              title: 'Then: Count Up',
              description:
                  'Celebrate past milestones, memories and elapsed days that stay with you forever.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentExplainerRow extends StatelessWidget {
  const _MomentExplainerRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colours.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colours.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colours.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colours.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.upcoming,
    required this.onRetry,
  });

  final String title;
  final bool upcoming;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final height = MediaQuery.of(context).size.height;
    final top = height * 0.38;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Space.phoneMargin,
          top,
          Space.phoneMargin,
          Space.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: colours.accent.withValues(alpha: 0.45),
            ),
            const SizedBox(height: Space.xl),
            Text(
              "Couldn't load your moments",
              style: kairos.typeScale.title.copyWith(
                color: colours.textPrimary,
              ),
            ),
            const SizedBox(height: Space.xxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
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
    this.isTimeline = false,
    this.isLast = false,
  });

  final Moment moment;
  final DateTime nowUtc;
  final VoidCallback onTap;
  final bool isTimeline;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
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

    final card = GlassCard(
      intensity: GlassIntensity.secondary,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  moment.category.name.toUpperCase(),
                  style: kairos.typeScale.micro.copyWith(
                    color: colours.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  moment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: kairos.typeScale.section.copyWith(
                    color: colours.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (phase is NowPhase) ...<Widget>[
                  const SizedBox(height: Space.xs),
                  ClipRRect(
                    borderRadius: RadiusTokens.pillRadius,
                    child: LinearProgressIndicator(
                      value: phase.fraction,
                      minHeight: Space.xxs,
                      backgroundColor: colours.accentMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(colours.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: kairos.typeScale.title.copyWith(
                  color: colours.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                unit,
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isTimeline) return card;

    // Refined timeline connector for Then screen
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 18),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colours.accent,
                boxShadow: [
                  BoxShadow(
                    color: colours.accent.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 60,
                color: colours.border.withValues(alpha: 0.7),
              ),
          ],
        ),
        const SizedBox(width: Space.sm),
        Expanded(child: card),
      ],
    );
  }
}

class _GlassHeroMomentCard extends StatelessWidget {
  const _GlassHeroMomentCard({
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
    final colours = kairos.colours;
    final countdown = Countdown.format(nowUtc, moment.targetUtc);
    final date = moment.targetUtc.toLocal();
    final dateLabel = '${date.day} ${_monthName(date.month)} ${date.year}';

    return GlassCard(
      intensity: GlassIntensity.primary,
      onTap: onTap,
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colours.accent.withValues(alpha: 0.15),
                  borderRadius: RadiusTokens.pillRadius,
                  border: Border.all(
                    color: colours.accent.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  moment.category.name.toUpperCase(),
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            moment.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: kairos.typeScale.title.copyWith(
              color: colours.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          if (moment.subtitle != null &&
              moment.subtitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.xxs),
            Text(
              moment.subtitle!,
              style: kairos.typeScale.caption.copyWith(
                color: colours.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                countdown.value,
                style: kairos.typeScale.display.copyWith(
                  color: colours.accent,
                  fontSize: 52,
                  height: 1.0,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              Text(
                countdown.unit,
                style: kairos.typeScale.section.copyWith(
                  color: colours.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}
