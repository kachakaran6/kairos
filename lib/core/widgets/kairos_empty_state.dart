import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../design/spacing_tokens.dart';
import '../theme/theme_extension.dart';
import 'pill_button.dart';

/// Spec: A calm editorial empty state featuring a CustomPainter geometric icon,
/// an elegant serif headline, and one clear pill action.
class KairosEmptyState extends StatelessWidget {
  const KairosEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconType = EmptyStateIconType.future,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateIconType iconType;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomPaint(
              size: const Size(80, 80),
              painter: _GeometricLineArtPainter(
                accent: kairos.colours.accent,
                border: kairos.colours.border,
                type: iconType,
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: kairos.typeScale.serifTitle.copyWith(
                color: kairos.colours.textPrimary,
              ),
            ),
            const SizedBox(height: Space.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: kairos.typeScale.body.copyWith(
                  color: kairos.colours.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            PillButton(
              onPressed: onAction,
              label: actionLabel,
              variant: PillButtonVariant.primary,
            ),
            if (secondaryActionLabel != null &&
                onSecondaryAction != null) ...<Widget>[
              const SizedBox(height: Space.md),
              GestureDetector(
                onTap: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: kairos.typeScale.caption.copyWith(
                    color: kairos.colours.textSecondary,
                    decoration: TextDecoration.underline,
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

enum EmptyStateIconType { future, past, general }

class _GeometricLineArtPainter extends CustomPainter {
  const _GeometricLineArtPainter({
    required this.accent,
    required this.border,
    required this.type,
  });

  final Color accent;
  final Color border;
  final EmptyStateIconType type;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer subtle ring
    final ringPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner accent mark
    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (type == EmptyStateIconType.future) {
      // Arrow pointing up-right into the future
      canvas.drawLine(
        Offset(center.dx - 12, center.dy + 12),
        Offset(center.dx + 12, center.dy - 12),
        accentPaint,
      );
      canvas.drawLine(
        Offset(center.dx + 2, center.dy - 12),
        Offset(center.dx + 12, center.dy - 12),
        accentPaint,
      );
      canvas.drawLine(
        Offset(center.dx + 12, center.dy - 2),
        Offset(center.dx + 12, center.dy - 12),
        accentPaint,
      );
    } else if (type == EmptyStateIconType.past) {
      // Caligraphic clock arc representing past elapsed time
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 16),
        -math.pi / 2,
        math.pi * 1.5,
        false,
        accentPaint,
      );
      canvas.drawLine(center, Offset(center.dx, center.dy - 10), accentPaint);
      canvas.drawLine(center, Offset(center.dx + 8, center.dy), accentPaint);
    } else {
      // Hourglass
      final path = Path()
        ..moveTo(center.dx - 12, center.dy - 12)
        ..lineTo(center.dx + 12, center.dy - 12)
        ..lineTo(center.dx - 12, center.dy + 12)
        ..lineTo(center.dx + 12, center.dy + 12)
        ..close();
      canvas.drawPath(path, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometricLineArtPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.border != border ||
        oldDelegate.type != type;
  }
}
