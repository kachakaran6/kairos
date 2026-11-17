import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../design/widget_tokens.dart';

/// Renders luxury graphical elements for Kairos widgets as offscreen bitmaps.
class WidgetArtworkRenderer {
  /// Category background gradient helper ensuring high AA contrast.
  static LinearGradient categoryGradient(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'travel':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? WidgetTokens.workDark : WidgetTokens.workLight,
        );
      case 'birthday':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? WidgetTokens.loveDark : WidgetTokens.loveLight,
        );
      case 'exam':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? WidgetTokens.travelDark : WidgetTokens.travelLight,
        );
      case 'festival':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? WidgetTokens.lifeDark : WidgetTokens.lifeLight,
        );
      case 'work':
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? WidgetTokens.defaultDark : WidgetTokens.defaultLight,
        );
    }
  }
}

/// Progress arc ring for the Hero countdown widget.
class WidgetProgressRing extends StatelessWidget {
  const WidgetProgressRing({
    super.key,
    required this.progress,
    required this.accentColor,
    required this.size,
    this.strokeWidth = 6.0,
  });

  final double progress;
  final Color accentColor;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          accentColor: accentColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.accentColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color accentColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final sweepAngle = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// 7-Day Focus Streak Bars for the Focus widget.
class WidgetStreakBars extends StatelessWidget {
  const WidgetStreakBars({
    super.key,
    required this.activeDays,
    required this.accentColor,
  });

  final List<bool> activeDays; // 7 days (Mon-Sun)
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final isActive = index < activeDays.length && activeDays[index];
          return Container(
            width: 12,
            height: isActive ? 28 : 10,
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor
                  : accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }
}

/// Concentric rings for Day / Week / Month / Year life progress.
class WidgetLifeProgressRings extends StatelessWidget {
  const WidgetLifeProgressRings({
    super.key,
    required this.dayProgress,
    required this.weekProgress,
    required this.monthProgress,
    required this.yearProgress,
    required this.accentColor,
    required this.size,
  });

  final double dayProgress;
  final double weekProgress;
  final double monthProgress;
  final double yearProgress;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LifeRingsPainter(
          dayProgress: dayProgress,
          weekProgress: weekProgress,
          monthProgress: monthProgress,
          yearProgress: yearProgress,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _LifeRingsPainter extends CustomPainter {
  const _LifeRingsPainter({
    required this.dayProgress,
    required this.weekProgress,
    required this.monthProgress,
    required this.yearProgress,
    required this.accentColor,
  });

  final double dayProgress;
  final double weekProgress;
  final double monthProgress;
  final double yearProgress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final values = [dayProgress, weekProgress, monthProgress, yearProgress];
    final opacities = [1.0, 0.8, 0.6, 0.4];
    final strokeWidth = size.width / 18;

    for (int i = 0; i < 4; i++) {
      final r = (size.width / 2) - (i * strokeWidth * 1.5) - strokeWidth;
      if (r <= 0) continue;

      final trackPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, r, trackPaint);

      final sweep = 2 * math.pi * values[i].clamp(0.0, 1.0);
      final arcPaint = Paint()
        ..color = accentColor.withValues(alpha: opacities[i])
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        sweep,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LifeRingsPainter oldDelegate) => true;
}
