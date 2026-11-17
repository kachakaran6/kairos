import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/kairos_chips.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';

enum AmbientSound {
  off('None', LucideIcons.volumeX),
  rain('Gentle Rain', LucideIcons.cloudRain),
  whiteNoise('White Noise', LucideIcons.wind),
  forest('Forest Wind', LucideIcons.trees),
  campfire('Campfire', LucideIcons.flame);

  const AmbientSound(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Pomodoro and deep work focus timer with visible 8px stroke gradient progress ring,
/// ambient soundscapes, 7-day streak bar chart, and proper flame iconography.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  int _workMinutes = 25;
  int _restMinutes = 5;

  late int _remainingSeconds;
  int _completedSessions = 3;
  bool _resting = false;
  AmbientSound _sound = AmbientSound.rain;
  Timer? _ticker;

  late final AnimationController _pulseController;

  bool get _running => _ticker?.isActive ?? false;
  int get _totalSeconds => (_resting ? _restMinutes : _workMinutes) * 60;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _workMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectDuration(int minutes) {
    if (_running) return;
    HapticFeedback.selectionClick();
    setState(() {
      _workMinutes = minutes;
      if (!_resting) {
        _remainingSeconds = minutes * 60;
      }
    });
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_running) {
      _ticker?.cancel();
      _pulseController.stop();
      setState(() {});
      return;
    }
    if (_sound != AmbientSound.off) {
      _pulseController.repeat(reverse: true);
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _pulseController.stop();
        HapticFeedback.heavyImpact();
        setState(() {
          if (_resting) {
            _resting = false;
            _remainingSeconds = _workMinutes * 60;
          } else {
            _completedSessions += 1;
            _resting = true;
            _remainingSeconds = _restMinutes * 60;
          }
        });
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _pulseController.stop();
    setState(() {
      _resting = false;
      _remainingSeconds = _workMinutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return KairosScaffold(
      title: 'Focus',
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Session Length Chips at the top
            Center(
              child: Wrap(
                spacing: Space.sm,
                alignment: WrapAlignment.center,
                children: <int>[15, 25, 45, 60].map((minutes) {
                  return KairosChoiceChip(
                    label: '$minutes min',
                    selected: _workMinutes == minutes && !_resting,
                    onSelected: (_) => _selectDuration(minutes),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: Space.xl),

            // Visible 8px Stroke Gradient Focus Ring
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _FocusRingPainter(
                    progress: progress,
                    accent: _resting ? colours.success : colours.accent,
                    border: colours.border,
                    resting: _resting,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _resting ? 'REST' : 'FOCUS',
                          style: kairos.typeScale.caption.copyWith(
                            color: _resting ? colours.success : colours.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatDuration(
                                Duration(seconds: _remainingSeconds),
                              ),
                              style: kairos.typeScale.display.copyWith(
                                fontSize: 54,
                                fontWeight: FontWeight.w200,
                                color: colours.textPrimary,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_completedSessions sessions completed',
                          style: kairos.typeScale.caption.copyWith(
                            color: colours.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Space.xl),

            // Action Buttons
            Row(
              children: <Widget>[
                Expanded(
                  child: PillButton(
                    onPressed: _reset,
                    label: 'Reset',
                    variant: PillButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  flex: 2,
                  child: PillButton(
                    onPressed: _toggle,
                    label: _running ? 'Pause' : 'Start Focus',
                    icon: Icon(
                      _running ? LucideIcons.pause : LucideIcons.play,
                      size: 18,
                    ),
                    variant: PillButtonVariant.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Space.xl),

            // Ambient Soundscapes
            SurfaceCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.headphones,
                            size: 16,
                            color: colours.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ambient Soundscape',
                            style: kairos.typeScale.section.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colours.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (_running && _sound != AmbientSound.off)
                        Text(
                          'Playing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colours.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: AmbientSound.values.map((sound) {
                      final isSelected = _sound == sound;
                      return KairosChoiceChip(
                        label: sound.label,
                        icon: Icon(sound.icon, size: 15),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _sound = sound);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Space.md),

            // Weekly Activity Streak
            SurfaceCard(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Weekly Activity & Streak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kairos.typeScale.section.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colours.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.flame,
                            size: 16,
                            color: colours.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4-Day Streak',
                            style: kairos.typeScale.caption.copyWith(
                              color: colours.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  _buildWeeklyHeatMap(context),
                  const SizedBox(height: Space.sm),
                  Text(
                    '18 sessions completed this week • 7.5 hours focused',
                    style: kairos.typeScale.caption.copyWith(
                      color: colours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Space.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatMap(BuildContext context) {
    final kairos = KairosTheme.of(context);
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sessionsPerDay = <int>[4, 5, 3, 4, 2, 0, 0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (var i = 0; i < 7; i++) ...<Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sessionsPerDay[i] == 0
                      ? kairos.colours.surfaceElevated
                      : (sessionsPerDay[i] >= 4
                            ? kairos.colours.accent
                            : kairos.colours.accent.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  border: Border.all(
                    color: sessionsPerDay[i] > 0
                        ? kairos.colours.accent
                        : kairos.colours.border,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    sessionsPerDay[i] > 0 ? '${sessionsPerDay[i]}' : '',
                    style: kairos.typeScale.caption.copyWith(
                      color: sessionsPerDay[i] >= 4
                          ? kairos.colours.onAccent
                          : kairos.colours.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days[i],
                style: kairos.typeScale.caption.copyWith(
                  color: kairos.colours.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.progress,
    required this.accent,
    required this.border,
    required this.resting,
  });

  final double progress;
  final Color accent;
  final Color border;
  final bool resting;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track ring
    final trackPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 8px Stroke Gradient Active Arc
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: <Color>[accent.withValues(alpha: 0.5), accent],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border ||
      oldDelegate.resting != resting;
}
