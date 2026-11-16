import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/clock_provider.dart';
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
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      Space.phoneMargin,
                      0,
                      Space.phoneMargin,
                      index == visible.length - 1 ? Space.huge : 0,
                    ),
                    child: MomentCard(
                      moment: visible[index],
                      nowUtc: now,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MomentDetailPage(momentId: visible[index].id),
                        ),
                      ),
                    ),
                  ),
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
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.phoneMargin,
          vertical: Space.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Elegant glowing circular illustration badge
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colours.surface,
                border: Border.all(
                  color: colours.accent.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colours.accent.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  upcoming ? Icons.arrow_outward_rounded : Icons.history_rounded,
                  size: 38,
                  color: colours.accent,
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(
              upcoming ? 'Nothing ahead yet' : 'Nothing behind yet',
              textAlign: TextAlign.center,
              style: kairos.typeScale.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colours.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: Space.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                upcoming
                    ? 'Add the day you are counting to. It will sit here, at the top of your day, until it happens.'
                    : 'Moments move here once they pass, and count up from then on. Add one that already happened.',
                textAlign: TextAlign.center,
                style: kairos.typeScale.body.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: colours.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: Space.xxl),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colours.accent,
                    foregroundColor: colours.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    upcoming ? 'Add a moment' : 'Add a past date',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (upcoming) ...[
              const SizedBox(height: Space.sm),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See how moments work',
                  style: kairos.typeScale.caption.copyWith(
                    fontSize: 13,
                    color: colours.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
  });

  final Moment moment;
  final DateTime nowUtc;
  final VoidCallback onTap;

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

    return Material(
      color: colours.surface,
      borderRadius: RadiusTokens.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.lgRadius,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.lgRadius,
            border: Border.all(color: colours.border),
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
                      const SizedBox(height: Space.xxs),
                      ClipRRect(
                        borderRadius: RadiusTokens.pillRadius,
                        child: LinearProgressIndicator(
                          value: phase.fraction,
                          minHeight: Space.xxs,
                          backgroundColor: colours.accentMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colours.accent,
                          ),
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
        ),
      ),
    );
  }
}
