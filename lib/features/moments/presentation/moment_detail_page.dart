import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/time/countdown.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/moment.dart';
import '../domain/moment_phase.dart';
import 'moment_controller.dart';
import 'moment_editor_page.dart';
import 'zero_moment_page.dart';

class MomentDetailPage extends ConsumerStatefulWidget {
  const MomentDetailPage({super.key, required this.momentId});

  final String momentId;

  @override
  ConsumerState<MomentDetailPage> createState() => _MomentDetailPageState();
}

class _MomentDetailPageState extends ConsumerState<MomentDetailPage> {
  Timer? _ticker;
  CountingMode? _overrideMode;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final moments = ref.watch(momentListProvider).value;
    final moment = moments
        ?.where((item) => item.id == widget.momentId)
        .firstOrNull;

    if (moment == null) {
      return KairosScaffold(
        title: 'Moment',
        showBackButton: true,
        body: const Center(child: Text('Moment not found')),
      );
    }

    final currentMode = _overrideMode ?? moment.countingMode;
    final now = ref.read(clockProvider).nowUtc();
    final phase = phaseAt(moment, now);
    final countdown = Countdown.format(
      now,
      moment.targetUtc,
      mode: currentMode,
    );
    final parts = Countdown.continuousParts(now, moment.targetUtc);

    final totalDuration = moment.targetUtc
        .difference(moment.createdAtUtc)
        .inSeconds
        .abs();
    final elapsed = now.difference(moment.createdAtUtc).inSeconds.abs();
    final progress = totalDuration > 0
        ? (elapsed / totalDuration).clamp(0.05, 0.95)
        : 0.5;

    return KairosScaffold(
      title: moment.category.name.toUpperCase(),
      showBackButton: true,
      actions: <Widget>[
        IconButton(
          tooltip: moment.pinned ? 'Unpin' : 'Pin',
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(momentListProvider.notifier).togglePinned(moment.id);
          },
          icon: Icon(
            moment.pinned ? LucideIcons.pinOff : LucideIcons.pin,
            color: moment.pinned ? colours.accent : colours.textSecondary,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MomentEditorPage(moment: moment),
            ),
          ),
          icon: Icon(LucideIcons.edit3, color: colours.textSecondary, size: 20),
        ),
      ],
      body: Column(
        children: <Widget>[
          const Spacer(),

          // Progress Ring and Live Continuous Counter
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: _DetailRingPainter(
                  progress: progress,
                  accent: colours.accent,
                  border: colours.border,
                ),
                child: Center(
                  child: currentMode == CountingMode.continuous
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ContinuousUnitBox(
                                  value: parts.days,
                                  label: 'DAYS',
                                  accentColor: colours.accent,
                                  textColor: colours.textPrimary,
                                  secondaryColor: colours.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                _ContinuousUnitBox(
                                  value: parts.hours,
                                  label: 'HOURS',
                                  accentColor: colours.accent,
                                  textColor: colours.textPrimary,
                                  secondaryColor: colours.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ContinuousUnitBox(
                                  value: parts.minutes,
                                  label: 'MINS',
                                  accentColor: colours.accent,
                                  textColor: colours.textPrimary,
                                  secondaryColor: colours.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                _ContinuousUnitBox(
                                  value: parts.seconds,
                                  label: 'SECS',
                                  accentColor: colours.accent,
                                  textColor: colours.textPrimary,
                                  secondaryColor: colours.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phase is ThenPhase ? 'since' : 'to go',
                              style: kairos.typeScale.micro.copyWith(
                                color: colours.textTertiary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  countdown.value,
                                  style: kairos.typeScale.display.copyWith(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w200,
                                    color: colours.accent,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              phase is ThenPhase
                                  ? '${countdown.unit} since'
                                  : '${countdown.unit} to go',
                              style: kairos.typeScale.section.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: Space.md),

          // Live Interactive Unit Mode Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DetailModeChip(
                  label: 'Continuous',
                  icon: LucideIcons.timer,
                  isSelected: currentMode == CountingMode.continuous,
                  accentColor: colours.accent,
                  surfaceColor: colours.surfaceElevated,
                  textColor: colours.textPrimary,
                  textSecondary: colours.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _overrideMode = CountingMode.continuous);
                    ref
                        .read(momentListProvider.notifier)
                        .replace(
                          moment.copyWith(
                            countingMode: CountingMode.continuous,
                          ),
                        );
                  },
                ),
                const SizedBox(width: Space.xs),
                _DetailModeChip(
                  label: 'Days',
                  isSelected: currentMode == CountingMode.days,
                  accentColor: colours.accent,
                  surfaceColor: colours.surfaceElevated,
                  textColor: colours.textPrimary,
                  textSecondary: colours.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _overrideMode = CountingMode.days);
                    ref
                        .read(momentListProvider.notifier)
                        .replace(
                          moment.copyWith(countingMode: CountingMode.days),
                        );
                  },
                ),
                const SizedBox(width: Space.xs),
                _DetailModeChip(
                  label: 'Hours',
                  isSelected: currentMode == CountingMode.hours,
                  accentColor: colours.accent,
                  surfaceColor: colours.surfaceElevated,
                  textColor: colours.textPrimary,
                  textSecondary: colours.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _overrideMode = CountingMode.hours);
                    ref
                        .read(momentListProvider.notifier)
                        .replace(
                          moment.copyWith(countingMode: CountingMode.hours),
                        );
                  },
                ),
                const SizedBox(width: Space.xs),
                _DetailModeChip(
                  label: 'Minutes',
                  isSelected: currentMode == CountingMode.minutes,
                  accentColor: colours.accent,
                  surfaceColor: colours.surfaceElevated,
                  textColor: colours.textPrimary,
                  textSecondary: colours.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _overrideMode = CountingMode.minutes);
                    ref
                        .read(momentListProvider.notifier)
                        .replace(
                          moment.copyWith(countingMode: CountingMode.minutes),
                        );
                  },
                ),
                const SizedBox(width: Space.xs),
                _DetailModeChip(
                  label: 'Seconds',
                  isSelected: currentMode == CountingMode.seconds,
                  accentColor: colours.accent,
                  surfaceColor: colours.surfaceElevated,
                  textColor: colours.textPrimary,
                  textSecondary: colours.textSecondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _overrideMode = CountingMode.seconds);
                    ref
                        .read(momentListProvider.notifier)
                        .replace(
                          moment.copyWith(countingMode: CountingMode.seconds),
                        );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.md),

          // Title in Editorial Serif
          Text(
            moment.title,
            textAlign: TextAlign.center,
            style: kairos.typeScale.serifTitle.copyWith(
              color: colours.textPrimary,
              fontSize: 28,
            ),
          ),
          if (moment.subtitle != null &&
              moment.subtitle!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              moment.subtitle!,
              textAlign: TextAlign.center,
              style: kairos.typeScale.caption.copyWith(
                color: colours.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _dateLabel(moment),
            textAlign: TextAlign.center,
            style: kairos.typeScale.caption.copyWith(
              color: colours.textTertiary,
              letterSpacing: 0.5,
            ),
          ),

          const Spacer(),

          // Notes in card if present
          if (moment.notes != null && moment.notes!.isNotEmpty) ...<Widget>[
            SurfaceCard(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.fileText, size: 16, color: colours.accent),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      moment.notes!,
                      style: kairos.typeScale.body.copyWith(
                        color: colours.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
          ],

          // Action buttons in bottom thumb zone
          PillButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ZeroMomentPage(moment: moment),
              ),
            ),
            label: 'Preview Zero Instant',
            icon: const Icon(LucideIcons.sparkles, size: 18),
            variant: PillButtonVariant.primary,
          ),
          const SizedBox(height: Space.sm),
          PillButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this moment?'),
                  content: const Text('This cannot be undone.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(momentListProvider.notifier).remove(moment.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            label: 'Delete Moment',
            icon: const Icon(LucideIcons.trash2, size: 18),
            variant: PillButtonVariant.ghost,
          ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }

  String _dateLabel(Moment moment) {
    final date = moment.targetUtc.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final time = moment.isAllDay
        ? ''
        : ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$day/$month/${date.year}$time';
  }
}

class _DetailRingPainter extends CustomPainter {
  const _DetailRingPainter({
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
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DetailRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border;
}

class _ContinuousUnitBox extends StatelessWidget {
  const _ContinuousUnitBox({
    required this.value,
    required this.label,
    required this.accentColor,
    required this.textColor,
    required this.secondaryColor,
  });

  final int value;
  final String label;
  final Color accentColor;
  final Color textColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailModeChip extends StatelessWidget {
  const _DetailModeChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : surfaceColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
