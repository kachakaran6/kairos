import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/elevation_tokens.dart';
import '../design/radius_tokens.dart';
import '../theme/theme_extension.dart';

/// A luxury surface card for lists, tiles, and groupings with subtle depth,
/// smooth press scaling, and continuous squircle corners.
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = RadiusTokens.cardRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isSelected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool isSelected;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final isDark = kairos.colours.isDark;

    final defaultBg = isDark ? kairos.colours.surface : kairos.colours.surface;

    final effectiveBg = widget.backgroundColor ?? defaultBg;

    final defaultBorder = isDark
        ? kairos.colours.border
        : kairos.colours.border;

    final effectiveBorder = widget.isSelected
        ? kairos.colours.accent
        : (widget.borderColor ?? defaultBorder);

    final shadows = isDark
        ? const <BoxShadow>[
            BoxShadow(
              color: ElevationTokens.shadowDark,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[
            BoxShadow(
              color: ElevationTokens.shadowLight,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ];

    final card = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: effectiveBorder,
          width: widget.isSelected ? 1.5 : widget.borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(20),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: card,
      ),
    );
  }
}
