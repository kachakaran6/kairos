import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/glass_tokens.dart';
import '../../design/radius_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';
import 'glass_container.dart';

/// Spec §2 & §12: A tactile glassmorphic action button.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.isPrimary = false,
    this.intensity,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = RadiusTokens.mdRadius,
  }) : assert(
         label != null || child != null,
         'Either label or child must be provided',
       );

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final Widget? icon;
  final bool isPrimary;
  final GlassIntensity? intensity;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final enabled = widget.onPressed != null;

    final effectiveIntensity =
        widget.intensity ??
        (widget.isPrimary ? GlassIntensity.primary : GlassIntensity.secondary);

    final bgColor = widget.isPrimary
        ? kairos.colours.accent
        : (kairos.colours.isDark
              ? kairos.colours.surfaceElevated.withValues(alpha: 0.65)
              : kairos.colours.surface.withValues(alpha: 0.85));

    final textColor = widget.isPrimary
        ? kairos.colours.onAccent
        : kairos.colours.textPrimary;

    final borderColor = widget.isPrimary
        ? kairos.colours.accent.withValues(alpha: 0.8)
        : kairos.glass.secondaryBorder;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: GlassContainer(
            width: widget.width,
            height:
                widget.height ??
                (widget.padding == null ? Space.touchTargetAndroid : null),
            borderRadius: widget.borderRadius,
            backgroundColor: widget.intensity != null ? null : bgColor,
            borderColor: widget.intensity != null ? null : borderColor,
            intensity: effectiveIntensity,
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: Space.lg),
            child:
                widget.child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      IconTheme(
                        data: IconThemeData(color: textColor, size: 20),
                        child: widget.icon!,
                      ),
                      const SizedBox(width: Space.xs),
                    ],
                    if (widget.label != null)
                      Flexible(
                        child: Text(
                          widget.label!,
                          style: kairos.typeScale.section.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

/// A tactile glassmorphic icon button with at least 44pt touch target.
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = Space.touchTargetIos,
    this.intensity = GlassIntensity.subtle,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final GlassIntensity intensity;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final enabled = widget.onPressed != null;

    final button = AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: GlassContainer(
          width: widget.size,
          height: widget.size,
          intensity: widget.intensity,
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: kairos.colours.textPrimary, size: 20),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );

    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: button)
        : button;
  }
}
