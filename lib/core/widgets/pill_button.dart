import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/radius_tokens.dart';
import '../design/spacing_tokens.dart';
import '../theme/theme_extension.dart';

enum PillButtonVariant { primary, secondary, ghost }

/// Spec: PillButton in primary / secondary / ghost, with centered label,
/// 56 high, press-scale 0.97 with haptic feedback, and an optional loading state.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = PillButtonVariant.primary,
    this.height = 56.0,
    this.width,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final PillButtonVariant variant;
  final double height;
  final double? width;
  final bool isLoading;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final enabled = widget.onPressed != null && !widget.isLoading;

    final bgColor = switch (widget.variant) {
      PillButtonVariant.primary => kairos.colours.accent,
      PillButtonVariant.secondary =>
        kairos.colours.isDark
            ? kairos.colours.surfaceElevated
            : kairos.colours.surfaceElevated,
      PillButtonVariant.ghost => Colors.transparent,
    };

    final textColor = switch (widget.variant) {
      PillButtonVariant.primary => kairos.colours.onAccent,
      PillButtonVariant.secondary => kairos.colours.textPrimary,
      PillButtonVariant.ghost => kairos.colours.accent,
    };

    final border = switch (widget.variant) {
      PillButtonVariant.primary => null,
      PillButtonVariant.secondary => Border.all(
        color: kairos.colours.border,
        width: 1,
      ),
      PillButtonVariant.ghost => null,
    };

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
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
          child: Container(
            height: widget.height,
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              border: border,
              boxShadow: widget.variant == PillButtonVariant.primary
                  ? <BoxShadow>[
                      BoxShadow(
                        color: kairos.colours.accent.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          IconTheme(
                            data: IconThemeData(color: textColor, size: 20),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: Space.sm),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kairos.typeScale.section.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
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
