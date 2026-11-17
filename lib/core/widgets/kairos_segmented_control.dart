import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion_tokens.dart';
import '../design/radius_tokens.dart';
import '../theme/theme_extension.dart';

/// A sliding thumb segmented control with smooth spring/ease transition.
class KairosSegmentedControl<T> extends StatelessWidget {
  const KairosSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final isDark = kairos.colours.isDark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? kairos.colours.surfaceElevated.withValues(alpha: 0.5)
            : kairos.colours.surfaceElevated,
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: kairos.colours.border, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keys = items.keys.toList();
          final count = keys.length;
          final itemWidth = (constraints.maxWidth) / count;
          final selectedIndex = keys.indexOf(selected);

          return Stack(
            children: <Widget>[
              // Animated sliding thumb
              AnimatedPositioned(
                duration: MotionTokens.fast,
                curve: Curves.easeOutCubic,
                left: selectedIndex >= 0 ? selectedIndex * itemWidth : 0,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? kairos.colours.surface : Colors.white,
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive labels
              Row(
                children: keys.map((key) {
                  final isSelected = key == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(key);
                      },
                      child: Center(
                        child: Text(
                          items[key]!,
                          style: kairos.typeScale.caption.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? kairos.colours.textPrimary
                                : kairos.colours.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
