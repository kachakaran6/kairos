import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/time/time_service.dart';
import '../../../core/widgets/kairos_chips.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';

/// Countdown timer with presets and luxury circular progress ring.
class TimerPage extends StatefulWidget {
  const TimerPage({super.key, this.initialMinutes = 5});

  final int initialMinutes;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const List<int> _presets = <int>[1, 5, 10, 25];

  late int _totalSeconds = widget.initialMinutes * 60;
  late int _remainingSeconds = widget.initialMinutes * 60;
  Timer? _ticker;

  bool get _running => _ticker?.isActive ?? false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    _ticker?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() {});
      return;
    }
    if (_remainingSeconds == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        HapticFeedback.mediumImpact();
        _showFinished();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }

  void _reset() {
    _ticker?.cancel();
    setState(() => _remainingSeconds = _totalSeconds);
  }

  void _addMinute() {
    setState(() {
      _totalSeconds += 60;
      _remainingSeconds += 60;
    });
  }

  Future<void> _showFinished() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Time's up"),
        content: const Text('Your timer has finished.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return KairosScaffold(
      title: 'Timer',
      showBackButton: true,
      body: Column(
        children: <Widget>[
          const Spacer(),

          // Hero circular timer ring
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: CustomPaint(
                painter: _TimerRingPainter(
                  progress: progress,
                  accent: colours.accent,
                  border: colours.border,
                  isDark: colours.isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatDuration(
                              Duration(seconds: _remainingSeconds),
                            ),
                            style: kairos.typeScale.display.copyWith(
                              fontSize: 56,
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
                        _running ? 'Counting' : 'Paused',
                        style: kairos.typeScale.caption.copyWith(
                          color: colours.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: Space.xl),

          // Preset Chips
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final preset in _presets)
                KairosChoiceChip(
                  label: '$preset min',
                  selected: _totalSeconds == preset * 60,
                  onSelected: (_) => _selectPreset(preset),
                ),
            ],
          ),

          const Spacer(),

          // Primary Controls: Start/Pause & Reset
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
                  label: _running ? 'Pause' : 'Start',
                  icon: Icon(
                    _running ? LucideIcons.pause : LucideIcons.play,
                    size: 18,
                  ),
                  variant: PillButtonVariant.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: Space.sm),

          // +1 minute helper button
          GestureDetector(
            onTap: _addMinute,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '+1 minute',
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.accent,
    required this.border,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final Color border;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background track ring
    final trackPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Soft accent glow behind the active arc
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.25 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      glowPaint,
    );

    // Sharp active foreground arc
    final arcPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border ||
      oldDelegate.isDark != isDark;
}
