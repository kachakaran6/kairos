import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/design/colour_tokens.dart';
import '../../../core/theme/theme_extension.dart';

/// Interactive Day/Night Terminator World Globe / Sun Arc representation per Spec §05 & §10.
class WorldClockGlobeWidget extends StatelessWidget {
  const WorldClockGlobeWidget({
    super.key,
    required this.selectedOffsetMinutes,
    required this.nowUtc,
  });

  final int selectedOffsetMinutes;
  final DateTime nowUtc;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    // Solar angle calculation based on UTC hour and fraction
    final decimalUtcHour =
        nowUtc.hour + (nowUtc.minute / 60.0) + (selectedOffsetMinutes / 60.0);
    final sunAngle = ((decimalUtcHour / 24.0) * 2 * math.pi) - math.pi / 2;

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colours.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient circular gradient
          Positioned.fill(
            child: CustomPaint(
              painter: _GlobeTerminatorPainter(
                colours: colours,
                sunAngle: sunAngle,
              ),
            ),
          ),
          // Info overlay
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: colours.accent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Solar Terminator',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colours.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${selectedOffsetMinutes >= 0 ? "+" : ""}${(selectedOffsetMinutes / 60).toStringAsFixed(1)}h Slider',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colours.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobeTerminatorPainter extends CustomPainter {
  const _GlobeTerminatorPainter({
    required this.colours,
    required this.sunAngle,
  });

  final KairosColourTokens colours;
  final double sunAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);
    final radius = math.min(size.width, size.height) * 0.38;

    // Draw Globe Body
    final globePaint = Paint()
      ..color = colours.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, globePaint);

    // Meridian Lines (3D Globe wireframe effect)
    final gridPaint = Paint()
      ..color = colours.border.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.3, height: radius * 2),
      gridPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 0.65, height: radius * 2),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );

    // Day/Night Terminator Shadow
    final nightPaint = Paint()
      ..color = colours.night.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final nightPath = Path();
    nightPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      sunAngle + math.pi / 2,
      math.pi,
    );
    nightPath.close();
    canvas.drawPath(nightPath, nightPaint);

    // Sun Icon Indicator Position
    final sunX = center.dx + radius * math.cos(sunAngle);
    final sunY = center.dy + radius * math.sin(sunAngle);

    final sunPaint = Paint()
      ..color = colours.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 5, sunPaint);

    // Glow ring around the sun
    final glowPaint = Paint()
      ..color = colours.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 10, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobeTerminatorPainter oldDelegate) {
    return oldDelegate.sunAngle != sunAngle || oldDelegate.colours != colours;
  }
}
