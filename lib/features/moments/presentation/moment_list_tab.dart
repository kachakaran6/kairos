import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/time/countdown.dart';
import '../../../core/widgets/kairos_empty_state.dart';
import '../../../core/widgets/surface_card.dart';
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
      backgroundColor: Colors.transparent,
      floatingActionButton: upcoming
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MomentEditorPage(),
                    ),
                  );
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colours.accent,
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colours.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(LucideIcons.plus, color: colours.onAccent, size: 20),
                      const SizedBox(width: Space.xs),
                      Text(
                        'New Moment',
                        style: kairos.typeScale.section.copyWith(
                          color: colours.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: moments.when(
          loading: () => _LoadingSkeleton(title: title),
          error: (error, _) => _ErrorState(
            title: title,
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
              return KairosEmptyState(
                iconType: upcoming
                    ? EmptyStateIconType.future
                    : EmptyStateIconType.past,
                title: upcoming ? 'Nothing ahead yet' : 'Nothing behind yet',
                description: upcoming
                    ? 'Add the day you are counting to. It will sit here, at the top of your day, until it happens.'
                    : 'Moments move here once they pass, and count up from then on. Add one that already happened.',
                actionLabel: upcoming ? 'Add a moment' : 'Add a past date',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MomentEditorPage(
                      moment: !upcoming
                          ? Moment(
                              id: '',
                              title: '',
                              targetUtc: now.subtract(const Duration(days: 30)),
                              direction: MomentDirection.up,
                              createdAtUtc: now,
                            )
                          : null,
                    ),
                  ),
                ),
                secondaryActionLabel: upcoming ? 'See how moments work' : null,
                onSecondaryAction: upcoming
                    ? () => _showHowMomentsWorkSheet(context)
                    : null,
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xl,
                      Space.lg,
                      Space.xl,
                      Space.md,
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
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MomentEditorPage(),
                              ),
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colours.surfaceElevated.withValues(
                                  alpha: 0.6,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: colours.border),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.plus,
                                  color: colours.textPrimary,
                                  size: 18,
                                ),
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
                    final bottomPadding = isBottom ? 120.0 : 0.0;

                    if (upcoming && index == 0) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          Space.xl,
                          0,
                          Space.xl,
                          bottomPadding,
                        ),
                        child: _HeroMomentCard(
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
                        Space.xl,
                        0,
                        Space.xl,
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

  void _showHowMomentsWorkSheet(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colours.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colours.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How Moments Work',
              style: kairos.typeScale.titleM.copyWith(
                color: colours.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _MomentExplainerRow(
              icon: LucideIcons.arrowUpRight,
              title: 'Next: Count Down',
              description:
                  'Track upcoming exams, trips, anniversaries and milestones as they draw closer.',
            ),
            const SizedBox(height: 14),
            const _MomentExplainerRow(
              icon: LucideIcons.clock,
              title: 'Now: Live Clock & Instruments',
              description:
                  'Focus on today with active ongoing moments, alarms, world clock and timers.',
            ),
            const SizedBox(height: 14),
            const _MomentExplainerRow(
              icon: LucideIcons.history,
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

class _HeroMomentCard extends StatelessWidget {
  const _HeroMomentCard({
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

    final totalDuration = moment.targetUtc
        .difference(moment.createdAtUtc)
        .inSeconds
        .abs();
    final elapsed = nowUtc.difference(moment.createdAtUtc).inSeconds.abs();
    final progress = totalDuration > 0
        ? (elapsed / totalDuration).clamp(0.05, 0.95)
        : 0.5;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: <Widget>[
          // Thin progress arc indicator in top-right
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progress,
                  accent: colours.accent,
                  border: colours.border,
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.arrowUpRight,
                    size: 20,
                    color: colours.accent,
                  ),
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colours.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
                child: Text(
                  moment.category.name.toUpperCase(),
                  style: kairos.typeScale.micro.copyWith(
                    color: colours.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                moment.title,
                style: kairos.typeScale.serifTitle.copyWith(
                  color: colours.textPrimary,
                  fontSize: 26,
                  height: 1.2,
                ),
              ),
              if (moment.subtitle != null && moment.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  moment.subtitle!,
                  style: kairos.typeScale.caption.copyWith(
                    color: colours.textSecondary,
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
                    style: kairos.typeScale.displayL.copyWith(
                      color: colours.accent,
                      fontWeight: FontWeight.w200,
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
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
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border;
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
      ThenPhase() => (countdown.value, '${countdown.unit} ago'),
    };

    final card = SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
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
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    child: LinearProgressIndicator(
                      value: phase.fraction,
                      minHeight: 3,
                      backgroundColor: colours.surfaceElevated,
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

    // Editorial vertical timeline with continuous hairline and accent dot
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 22),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colours.accent,
                shape: BoxShape.circle,
                border: Border.all(color: colours.background, width: 2),
              ),
            ),
            if (!isLast)
              Container(width: 1.5, height: 72, color: colours.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: card),
      ],
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

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xl,
        Space.lg,
        Space.xl,
        Space.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: kairos.typeScale.title.copyWith(color: colours.textPrimary),
          ),
          const SizedBox(height: Space.lg),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: colours.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colours.border),
            ),
          ),
          const SizedBox(height: Space.md),
          Container(
            height: 76,
            decoration: BoxDecoration(
              color: colours.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colours.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(LucideIcons.alertTriangle, size: 40, color: colours.accent),
            const SizedBox(height: Space.md),
            Text(
              "Couldn't load your moments",
              style: kairos.typeScale.title.copyWith(
                color: colours.textPrimary,
              ),
            ),
            const SizedBox(height: Space.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
