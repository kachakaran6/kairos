import 'package:flutter/material.dart';
import '../../theme/theme_extension.dart';

/// Spec §2: A luxury ambient background with subtle, atmospheric tonal glows.
class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Stack(
      children: <Widget>[
        Positioned.fill(child: Container(color: kairos.colours.background)),
        Positioned.fill(
          child: CustomPaint(
            painter: _AtmosphericPainter(
              accent: kairos.colours.accent,
              surfaceElevated: kairos.colours.surfaceElevated,
              isDark: kairos.colours.isDark,
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AtmosphericPainter extends CustomPainter {
  const _AtmosphericPainter({
    required this.accent,
    required this.surfaceElevated,
    required this.isDark,
  });

  final Color accent;
  final Color surfaceElevated;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right subtle accent haze
    final topHazePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.6),
        radius: 0.9,
        colors: <Color>[
          accent.withValues(alpha: isDark ? 0.08 : 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topHazePaint);

    // Bottom-left secondary surface haze
    final bottomHazePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, 0.7),
        radius: 1.1,
        colors: <Color>[
          surfaceElevated.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bottomHazePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AtmosphericPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.surfaceElevated != surfaceElevated ||
        oldDelegate.isDark != isDark;
  }
}
