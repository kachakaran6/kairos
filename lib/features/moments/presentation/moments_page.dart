import 'dart:async';
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
import '../../../core/widgets/widget_suite/widget_sync_service.dart';
import '../domain/moment.dart';
import '../domain/moment_phase.dart';
import 'moment_controller.dart';
import 'moment_detail_page.dart';
import 'moment_editor_page.dart';
import 'moment_list_tab.dart';

/// Unified Moments screen seamlessly merging Next (upcoming) and Then (past memories)
/// into a single refined, luxury experience with a fluid segmented toggle and category filters.
class MomentsPage extends ConsumerStatefulWidget {
  const MomentsPage({super.key, this.initialUpcoming = true});

  final bool initialUpcoming;

  @override
  ConsumerState<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends ConsumerState<MomentsPage> {
  late bool _upcoming = widget.initialUpcoming;
  MomentCategory? _selectedCategory;
  CountingMode _memoriesUnit = CountingMode.continuous;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _checkTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _checkTicker() {
    final needsTicking =
        !_upcoming &&
        (_memoriesUnit == CountingMode.continuous ||
            _memoriesUnit == CountingMode.seconds);
    if (needsTicking && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!needsTicking && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onUnitChanged(CountingMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _memoriesUnit = mode);
    _checkTicker();
    ref.read(widgetSyncServiceProvider).syncAllWidgets();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final momentsAsync = ref.watch(momentListProvider);
    final now = ref.watch(clockProvider).nowUtc();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MomentEditorPage(
                  moment: !_upcoming
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
      ),
      body: SafeArea(
        child: momentsAsync.when(
          loading: () => _LoadingSkeleton(title: _upcoming ? 'Next' : 'Then'),
          error: (error, _) => _ErrorState(
            title: _upcoming ? 'Next' : 'Then',
            onRetry: () => ref.invalidate(momentListProvider),
          ),
          data: (items) {
            final upcomingItems = items
                .where((m) => phaseAt(m, now) is! ThenPhase)
                .toList(growable: false);
            final pastItems = items
                .where((m) => phaseAt(m, now) is ThenPhase)
                .toList(growable: false);

            final activeList = _upcoming ? upcomingItems : pastItems;
            final filteredItems = _selectedCategory == null
                ? activeList
                : activeList
                      .where((m) => m.category == _selectedCategory)
                      .toList(growable: false);

            return CustomScrollView(
              slivers: <Widget>[
                // Header Bar: Title + Explainer Action
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xl,
                      Space.lg,
                      Space.xl,
                      Space.xs,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Moments',
                            style: kairos.typeScale.title.copyWith(
                              color: colours.textPrimary,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.info,
                            color: colours.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => _showHowMomentsWorkSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fluid Segmented Toggle: Upcoming (Next) vs Memories (Then)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.xl,
                      Space.xs,
                      Space.xl,
                      Space.sm,
                    ),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colours.surfaceElevated.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                        border: Border.all(color: colours.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentTab(
                              title: 'Upcoming',
                              altTitle: 'Next',
                              count: upcomingItems.length,
                              isSelected: _upcoming,
                              onTap: () {
                                if (!_upcoming) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _upcoming = true);
                                  _checkTicker();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: _SegmentTab(
                              title: 'Memories',
                              altTitle: 'Then',
                              count: pastItems.length,
                              isSelected: !_upcoming,
                              onTap: () {
                                if (_upcoming) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _upcoming = false);
                                  _checkTicker();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Memories Live Continuous Counter Unit Selector Bar
                if (!_upcoming)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.xl,
                        0,
                        Space.xl,
                        Space.xs,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colours.surfaceElevated.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          border: Border.all(color: colours.border),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  'COUNT',
                                  style: kairos.typeScale.micro.copyWith(
                                    color: colours.textTertiary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              _UnitFilterChip(
                                label: 'Continuous',
                                icon: LucideIcons.timer,
                                isSelected:
                                    _memoriesUnit == CountingMode.continuous,
                                onTap: () =>
                                    _onUnitChanged(CountingMode.continuous),
                              ),
                              const SizedBox(width: 4),
                              _UnitFilterChip(
                                label: 'Days',
                                isSelected: _memoriesUnit == CountingMode.days,
                                onTap: () => _onUnitChanged(CountingMode.days),
                              ),
                              const SizedBox(width: 4),
                              _UnitFilterChip(
                                label: 'Hours',
                                isSelected: _memoriesUnit == CountingMode.hours,
                                onTap: () => _onUnitChanged(CountingMode.hours),
                              ),
                              const SizedBox(width: 4),
                              _UnitFilterChip(
                                label: 'Mins',
                                isSelected:
                                    _memoriesUnit == CountingMode.minutes,
                                onTap: () =>
                                    _onUnitChanged(CountingMode.minutes),
                              ),
                              const SizedBox(width: 4),
                              _UnitFilterChip(
                                label: 'Secs',
                                isSelected:
                                    _memoriesUnit == CountingMode.seconds,
                                onTap: () =>
                                    _onUnitChanged(CountingMode.seconds),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Category Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl,
                      vertical: Space.xs,
                    ),
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = null);
                          },
                        ),
                        const SizedBox(width: Space.xs),
                        for (final cat in MomentCategory.values) ...[
                          _CategoryChip(
                            label:
                                cat.name[0].toUpperCase() +
                                cat.name.substring(1),
                            isSelected: _selectedCategory == cat,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCategory = _selectedCategory == cat
                                    ? null
                                    : cat;
                              });
                            },
                          ),
                          const SizedBox(width: Space.xs),
                        ],
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: Space.sm)),

                // Empty state or Content List
                if (filteredItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: Space.lg,
                        bottom: 120,
                      ),
                      child: KairosEmptyState(
                        iconType: _upcoming
                            ? EmptyStateIconType.future
                            : EmptyStateIconType.past,
                        title: _upcoming
                            ? 'Nothing ahead yet'
                            : 'Nothing behind yet',
                        description: _upcoming
                            ? 'Add the day you are counting to. It will sit here, at the top of your day, until it happens.'
                            : 'Moments move here once they pass, and count up from then on. Add one that already happened.',
                        actionLabel: _upcoming
                            ? 'Add a moment'
                            : 'Add a past date',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MomentEditorPage(
                              moment: !_upcoming
                                  ? Moment(
                                      id: '',
                                      title: '',
                                      targetUtc: now.subtract(
                                        const Duration(days: 30),
                                      ),
                                      direction: MomentDirection.up,
                                      createdAtUtc: now,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        secondaryActionLabel: _upcoming
                            ? 'See how moments work'
                            : null,
                        onSecondaryAction: _upcoming
                            ? () => _showHowMomentsWorkSheet(context)
                            : null,
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final isBottom = index == filteredItems.length - 1;
                      final bottomPadding = isBottom ? 120.0 : 0.0;

                      if (_upcoming &&
                          index == 0 &&
                          _selectedCategory == null) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            Space.xl,
                            0,
                            Space.xl,
                            bottomPadding,
                          ),
                          child: _HeroMomentCard(
                            moment: filteredItems[0],
                            nowUtc: now,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MomentDetailPage(
                                  momentId: filteredItems[0].id,
                                ),
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
                          moment: filteredItems[index],
                          nowUtc: now,
                          isTimeline: !_upcoming,
                          isLast: isBottom,
                          overrideCountingMode: !_upcoming
                              ? _memoriesUnit
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MomentDetailPage(
                                momentId: filteredItems[index].id,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Space.sm),
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
              title: 'Upcoming: Count Down',
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
              title: 'Memories: Count Up',
              description:
                  'Celebrate past milestones, memories and elapsed days that stay with you forever.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.title,
    required this.altTitle,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String altTitle;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? colours.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: kairos.typeScale.section.copyWith(
                color: isSelected ? colours.textPrimary : colours.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colours.accent.withValues(alpha: 0.16)
                      : colours.surfaceElevated,
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colours.accent : colours.textTertiary,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colours.accent
              : colours.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          border: Border.all(
            color: isSelected ? colours.accent : colours.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colours.onAccent : colours.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UnitFilterChip extends StatelessWidget {
  const _UnitFilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = KairosTheme.of(context).colours;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colours.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 11,
                color: isSelected ? colours.onAccent : colours.textSecondary,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colours.onAccent : colours.textSecondary,
              ),
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
