import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/colour_tokens.dart';
import '../../../core/design/elevation_tokens.dart';
import '../../../core/design/radius_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/surface_card.dart';

/// Interactive Day/Night Terminator World Globe with 3D spherical depth,
/// solar terminator gradient, and glowing sun indicator.
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

    return SurfaceCard(
      height: 200,
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient circular gradient & Globe
          Positioned.fill(
            child: CustomPaint(
              painter: _GlobeTerminatorPainter(
                colours: colours,
                sunAngle: sunAngle,
              ),
            ),
          ),
          // Info overlay at the bottom
          Positioned(
            bottom: 14,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.sun, size: 15, color: colours.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Solar Terminator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colours.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colours.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Text(
                    '${selectedOffsetMinutes >= 0 ? "+" : ""}${(selectedOffsetMinutes / 60).toStringAsFixed(1)}h Slider',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colours.accent,
                    ),
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
    final center = Offset(size.width / 2, size.height / 2 - 12);
    final radius = math.min(size.width, size.height) * 0.38;

    // Outer subtle atmospheric aura
    final auraPaint = Paint()
      ..color = colours.accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius + 8, auraPaint);

    // Globe Base (Day side)
    final dayPaint = Paint()
      ..color = colours.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dayPaint);

    // Latitude & Longitude grid lines (3D spherical projection)
    final gridPaint = Paint()
      ..color = colours.border.withValues(alpha: colours.isDark ? 0.3 : 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.4, height: radius * 2),
      gridPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 0.7, height: radius * 2),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Smooth Curved Day/Night Terminator
    final nightPaint = Paint()
      ..color =
          (colours.isDark
                  ? ElevationTokens.globeNightDark
                  : ElevationTokens.globeNightLight)
              .withValues(alpha: colours.isDark ? 0.65 : 0.45)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final terminatorPath = Path();
    terminatorPath.addArc(
      Rect.fromCircle(center: center, radius: radius),
      sunAngle + math.pi / 2,
      math.pi,
    );
    terminatorPath.close();
    canvas.drawPath(terminatorPath, nightPaint);
    canvas.restore();

    // Sun Icon Indicator Position
    final sunX = center.dx + radius * math.cos(sunAngle);
    final sunY = center.dy + radius * math.sin(sunAngle);

    // Glow ring around the sun
    final glowPaint = Paint()
      ..color = colours.accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(sunX, sunY), 12, glowPaint);

    final sunPaint = Paint()
      ..color = colours.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 5.5, sunPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobeTerminatorPainter oldDelegate) {
    return oldDelegate.sunAngle != sunAngle || oldDelegate.colours != colours;
  }
}
