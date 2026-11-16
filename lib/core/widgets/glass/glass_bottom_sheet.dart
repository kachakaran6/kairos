import 'dart:ui';
import 'package:flutter/material.dart';

import '../../design/radius_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';

/// Spec §12: Shows a modal glassmorphic bottom sheet with real backdrop blur.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final kairos = KairosTheme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: kairos.colours.isDark ? 0.65 : 0.35,
    ),
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: kairos.glass.primaryBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RadiusTokens.xl),
            ),
            border: Border.all(color: kairos.glass.primaryBorder, width: 1.0),
            boxShadow: kairos.glass.heroShadow,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: Space.xs),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kairos.colours.textTertiary.withValues(alpha: 0.4),
                      borderRadius: RadiusTokens.pillRadius,
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Flexible(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
