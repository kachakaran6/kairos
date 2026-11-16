import 'dart:ui';
import 'package:flutter/material.dart';

import '../../design/glass_tokens.dart';
import '../../design/radius_tokens.dart';
import '../../theme/theme_extension.dart';

/// Spec §2 & §12: A reusable glassmorphic surface with backdrop blur,
/// translucent tint, subtle border, inner highlight, and ambient shadow.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.intensity = GlassIntensity.secondary,
    this.borderRadius = RadiusTokens.lgRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showHighlight = true,
    this.shadows,
  });

  final Widget child;
  final GlassIntensity intensity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double? blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showHighlight;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final glass = kairos.glass;

    final effectiveBlur = blur ?? glass.blurFor(intensity);
    final effectiveBg = backgroundColor ?? glass.backgroundFor(intensity);
    final effectiveBorder = borderColor ?? glass.borderFor(intensity);
    final effectiveShadows =
        shadows ??
        (intensity == GlassIntensity.primary ? glass.heroShadow : glass.shadow);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: borderRadius,
              border: Border.all(color: effectiveBorder, width: borderWidth),
            ),
            child: showHighlight
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          glass.innerHighlight,
                          Colors.transparent,
                        ],
                        stops: const <double>[0.0, 0.45],
                      ),
                    ),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
