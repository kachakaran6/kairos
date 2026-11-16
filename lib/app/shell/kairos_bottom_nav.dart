import 'package:flutter/material.dart';

import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';

/// Custom three-tab bottom navigation per spec §6.3.
/// No pill, no Material component. Colour change + scale is the affordance.
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
    final colours = kairos.colours;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colours.background,
        border: Border(top: BorderSide(color: colours.border, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 72,
        child: Row(
          children: <Widget>[
            _NavItem(
              index: 0,
              label: 'Next',
              icon: const _NextIcon(),
              currentIndex: currentIndex,
              onTap: onChanged,
            ),
            _NavItem(
              index: 1,
              label: 'Now',
              icon: const _NowIcon(),
              currentIndex: currentIndex,
              onTap: onChanged,
            ),
            _NavItem(
              index: 2,
              label: 'Then',
              icon: const _ThenIcon(),
              currentIndex: currentIndex,
              onTap: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;
    final active = index == currentIndex;
    final color = active ? colours.accent : colours.textTertiary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          onTap: () => onTap(index),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  scale: active ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: IconTheme(
                    data: IconThemeData(color: color, size: 24),
                    child: icon,
                  ),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  label,
                  style: kairos.typeScale.micro.copyWith(
                    color: active ? colours.textPrimary : colours.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Custom tab glyphs (§5.8), drawn as CustomPainter, 24x24, 1.75pt stroke ----

class _NextIcon extends StatelessWidget {
  const _NextIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(size: const Size(24, 24), painter: _NextPainter(color));
  }
}

class _NextPainter extends CustomPainter {
  _NextPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    // Circle with a gap at top-right (~45deg region).
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      0.9,
      4.2,
      false,
      paint,
    );
    // Arrow leaving the gap, pointing up-right.
    final start = Offset(c.dx + r * 0.7, c.dy - r * 0.7);
    canvas.drawLine(start, start + const Offset(5, -5), paint);
    canvas.drawLine(
      start + const Offset(5, -5),
      start + const Offset(2, -5),
      paint,
    );
    canvas.drawLine(
      start + const Offset(5, -5),
      start + const Offset(5, -2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _NextPainter old) => old.color != color;
}

class _NowIcon extends StatelessWidget {
  const _NowIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(size: const Size(24, 24), painter: _NowPainter(color));
  }
}

class _NowPainter extends CustomPainter {
  _NowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 9, paint);
    canvas.drawCircle(c, 4, paint);
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, 1.6, dot);
  }

  @override
  bool shouldRepaint(covariant _NowPainter old) => old.color != color;
}

class _ThenIcon extends StatelessWidget {
  const _ThenIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return CustomPaint(size: const Size(24, 24), painter: _ThenPainter(color));
  }
}

class _ThenPainter extends CustomPainter {
  _ThenPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    canvas.drawCircle(c, r, paint);
    // Trail of two arcs behind (left side), fading.
    final fade1 = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fade2 = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 2),
      2.6,
      0.9,
      false,
      fade1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 4),
      2.7,
      0.7,
      false,
      fade2,
    );
  }

  @override
  bool shouldRepaint(covariant _ThenPainter old) => old.color != color;
}
