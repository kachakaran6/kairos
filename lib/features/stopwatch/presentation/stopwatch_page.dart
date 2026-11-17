import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';

/// Monotonic stopwatch with luxury sweeping analog-style dial and lap highlight.
class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = <Duration>[];
  Timer? _repaint;

  @override
  void dispose() {
    _repaint?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _repaint?.cancel();
      } else {
        _stopwatch.start();
        _repaint = Timer.periodic(const Duration(milliseconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _lap() {
    if (_stopwatch.elapsed == Duration.zero) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  void _reset() {
    _repaint?.cancel();
    setState(() {
      _stopwatch
        ..stop()
        ..reset();
      _laps.clear();
    });
  }

  String _formatMain(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatCentis(Duration value) {
    final centis = (value.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '.$centis';
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final elapsed = _stopwatch.elapsed;
    final secondsSweep = (elapsed.inMilliseconds % 60000) / 60000.0;

    Duration? bestLap;
    Duration? worstLap;
    if (_laps.length > 1) {
      bestLap = _laps.reduce((a, b) => a < b ? a : b);
      worstLap = _laps.reduce((a, b) => a > b ? a : b);
    }

    return KairosScaffold(
      title: 'Stopwatch',
      showBackButton: true,
      body: Column(
        children: <Widget>[
          const Spacer(),

          // Sweeping dial with central numerals
          Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: CustomPaint(
                painter: _SweepingDialPainter(
                  sweepFraction: secondsSweep,
                  accent: colours.accent,
                  border: colours.border,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        _formatMain(elapsed),
                        style: kairos.typeScale.display.copyWith(
                          fontSize: 44,
                          fontWeight: FontWeight.w200,
                          color: colours.textPrimary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      Text(
                        _formatCentis(elapsed),
                        style: kairos.typeScale.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: colours.accent,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: Space.lg),

          // Action controls
          Row(
            children: <Widget>[
              Expanded(
                child: PillButton(
                  onPressed: _stopwatch.isRunning ? _lap : null,
                  label: 'Lap',
                  variant: PillButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                flex: 2,
                child: PillButton(
                  onPressed: _toggle,
                  label: _stopwatch.isRunning ? 'Pause' : 'Start',
                  icon: Icon(
                    _stopwatch.isRunning ? LucideIcons.pause : LucideIcons.play,
                    size: 18,
                  ),
                  variant: PillButtonVariant.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: Space.xs),
          GestureDetector(
            onTap: _reset,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Reset',
                style: kairos.typeScale.caption.copyWith(
                  color: colours.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Laps list with best and worst laps highlighted
          if (_laps.isNotEmpty)
            SizedBox(
              height: 180,
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ListView.separated(
                  itemCount: _laps.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 12, color: colours.border),
                  itemBuilder: (context, index) {
                    final lapNumber = _laps.length - index;
                    final lapTime = _laps[index];
                    final isBest = lapTime == bestLap;
                    final isWorst = lapTime == worstLap;

                    final lapColor = isBest
                        ? colours.success
                        : (isWorst ? colours.danger : colours.textPrimary);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: [
                            Text(
                              'Lap $lapNumber',
                              style: kairos.typeScale.caption.copyWith(
                                color: colours.textSecondary,
                              ),
                            ),
                            if (isBest) ...[
                              const SizedBox(width: 6),
                              Text(
                                'FASTEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colours.success,
                                ),
                              ),
                            ],
                            if (isWorst) ...[
                              const SizedBox(width: 6),
                              Text(
                                'SLOWEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colours.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${_formatMain(lapTime)}${_formatCentis(lapTime)}',
                          style: kairos.typeScale.section.copyWith(
                            color: lapColor,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}

class _SweepingDialPainter extends CustomPainter {
  const _SweepingDialPainter({
    required this.sweepFraction,
    required this.accent,
    required this.border,
  });

  final double sweepFraction;
  final Color accent;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Track circle
    final trackPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, trackPaint);

    // 12 clock tick marks
    final tickPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outer = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - 6) * math.sin(angle),
        center.dy - (radius - 6) * math.cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Sweeping accent hand
    final handAngle = sweepFraction * 2 * math.pi - math.pi / 2;
    final handPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final handTip = Offset(
      center.dx + radius * math.cos(handAngle),
      center.dy + radius * math.sin(handAngle),
    );
    canvas.drawLine(center, handTip, handPaint);

    // Center pivot dot
    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepingDialPainter oldDelegate) =>
      oldDelegate.sweepFraction != sweepFraction ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border;
}
