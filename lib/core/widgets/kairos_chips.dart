import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion_tokens.dart';
import '../design/radius_tokens.dart';
import '../design/spacing_tokens.dart';
import '../theme/theme_extension.dart';

/// A refined choice chip with smooth animated fill and no tick glyph clutter.
class KairosChoiceChip extends StatelessWidget {
  const KairosChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final isDark = kairos.colours.isDark;

    final bgColor = selected
        ? kairos.colours.accent.withValues(alpha: 0.15)
        : (isDark ? kairos.colours.surface : kairos.colours.surfaceElevated);

    final borderColor = selected
        ? kairos.colours.accent
        : kairos.colours.border;

    final textColor = selected
        ? kairos.colours.accent
        : kairos.colours.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(!selected);
      },
      child: AnimatedContainer(
        duration: MotionTokens.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(RadiusTokens.chip),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              IconTheme(
                data: IconThemeData(color: textColor, size: 16),
                child: icon!,
              ),
              const SizedBox(width: Space.xs),
            ],
            Text(
              label,
              style: kairos.typeScale.caption.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round DayChip showing M T W T F S S with an accessible semantic label.
class KairosDayChip extends StatelessWidget {
  const KairosDayChip({
    super.key,
    required this.dayNumber, // 1 = Monday .. 7 = Sunday
    required this.selected,
    required this.onToggle,
  });

  final int dayNumber;
  final bool selected;
  final VoidCallback onToggle;

  static const _labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _longNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final isDark = kairos.colours.isDark;

    final index = (dayNumber - 1).clamp(0, 6);
    final shortLabel = _labels[index];
    final longLabel = _longNames[index];

    final bgColor = selected
        ? kairos.colours.accent
        : (isDark ? kairos.colours.surface : kairos.colours.surfaceElevated);

    final textColor = selected
        ? kairos.colours.onAccent
        : kairos.colours.textSecondary;

    return Semantics(
      label: longLabel,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onToggle();
        },
        child: AnimatedContainer(
          duration: MotionTokens.fast,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: selected ? kairos.colours.accent : kairos.colours.border,
              width: 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: kairos.colours.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              shortLabel,
              style: kairos.typeScale.caption.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
