import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/glass_tokens.dart';
import '../../design/radius_tokens.dart';
import 'glass_container.dart';

/// Spec §2 & §12: An interactive glassmorphic card with smooth press scaling,
/// haptic feedback, and translucent depth.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.intensity = GlassIntensity.secondary,
    this.borderRadius = RadiusTokens.lgRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GlassIntensity intensity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _pressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _pressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: GlassContainer(
          intensity: widget.intensity,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          borderColor: widget.borderColor,
          backgroundColor: widget.backgroundColor,
          child: widget.child,
        ),
      ),
    );
  }
}
