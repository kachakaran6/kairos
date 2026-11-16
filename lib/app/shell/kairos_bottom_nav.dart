import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';

/// Floating pill bottom navigation bar with Apple-inspired frosted glass aesthetic.
class KairosBottomNav extends StatelessWidget {
  const KairosBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: Space.phoneMargin,
        right: Space.phoneMargin,
        bottom: bottomPadding > 0 ? bottomPadding : Space.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: kairos.glass.primaryBlur,
            sigmaY: kairos.glass.primaryBlur,
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: kairos.glass.primaryBackground,
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              border: Border.all(color: kairos.glass.primaryBorder, width: 1.2),
              boxShadow: kairos.glass.heroShadow,
            ),
            child: Row(
              children: <Widget>[
                _FloatingNavItem(
                  index: 0,
                  label: 'Next',
                  icon: const _NextIcon(),
                  currentIndex: currentIndex,
                  onTap: onChanged,
                ),
                _FloatingNavItem(
                  index: 1,
                  label: 'Now',
                  icon: const _NowIcon(),
                  currentIndex: currentIndex,
                  onTap: onChanged,
                ),
                _FloatingNavItem(
                  index: 2,
                  label: 'Then',
                  icon: const _ThenIcon(),
                  currentIndex: currentIndex,
                  onTap: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.currentIndex,
    required this.onTap,
  });

  final int index;
  final String label;
  final Widget icon;
  final int currentIndex;
  final ValueChanged<int> onTap;

  bool get _selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
          onTap: () => onTap(index),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _selected
                    ? colours.accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(RadiusTokens.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedScale(
                    scale: _selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconTheme(
                      data: IconThemeData(
                        size: 20,
                        color: _selected
                            ? colours.accent
                            : colours.textTertiary,
                      ),
                      child: icon,
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  Text(
                    label,
                    style: kairos.typeScale.caption.copyWith(
                      fontSize: 12,
                      fontWeight: _selected ? FontWeight.w700 : FontWeight.w500,
                      color: _selected ? colours.accent : colours.textTertiary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextIcon extends StatelessWidget {
  const _NextIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(
      size: const Size.square(22),
      painter: _NextIconPainter(color: color),
    );
  }
}

class _NextIconPainter extends CustomPainter {
  const _NextIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(rect, 0.45, 4.9, false, paint);

    final tip = Offset(size.width - 3, 3);
    canvas.drawLine(Offset(size.width * 0.48, size.height * 0.52), tip, paint);
    canvas.drawLine(tip, Offset(tip.dx - 6, tip.dy), paint);
    canvas.drawLine(tip, Offset(tip.dx, tip.dy + 6), paint);
  }

  @override
  bool shouldRepaint(covariant _NextIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NowIcon extends StatelessWidget {
  const _NowIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(
      size: const Size.square(22),
      painter: _NowIconPainter(color: color),
    );
  }
}

class _NowIconPainter extends CustomPainter {
  const _NowIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2 - 2, stroke);
    canvas.drawCircle(center, size.width / 2 - 6, stroke);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.2, fill);
  }

  @override
  bool shouldRepaint(covariant _NowIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ThenIcon extends StatelessWidget {
  const _ThenIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(
      size: const Size.square(22),
      painter: _ThenIconPainter(color: color),
    );
  }
}

class _ThenIconPainter extends CustomPainter {
  const _ThenIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2 + 1, size.height / 2);
    canvas.drawCircle(center, size.width / 2 - 3, paint);

    canvas.drawLine(center, Offset(center.dx, center.dy - 5.5), paint);
    canvas.drawLine(center, Offset(center.dx - 4.5, center.dy), paint);

    final trail = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx - 3, center.dy), radius: 5.5),
      2.0,
      2.4,
      false,
      trail,
    );
  }

  @override
  bool shouldRepaint(covariant _ThenIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
