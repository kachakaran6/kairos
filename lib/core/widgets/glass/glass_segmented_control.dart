import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/glass_tokens.dart';
import '../../design/radius_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';
import 'glass_container.dart';

class GlassSegment<T> {
  const GlassSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Spec §9 & §12: An Apple-inspired segmented glass control with smooth
/// sliding capsule selection and tactile haptics.
class GlassSegmentedControl<T> extends StatelessWidget {
  const GlassSegmentedControl({
    super.key,
    this.options,
    this.selected,
    this.selectedValue,
    required this.onChanged,
    this.labels,
    this.segments,
  });

  final List<T>? options;
  final T? selected;
  final T? selectedValue;
  final ValueChanged<T> onChanged;
  final Map<T, String>? labels;
  final List<GlassSegment<T>>? segments;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final effectiveSelected = selectedValue ?? selected;
    final effectiveOptions = segments != null
        ? segments!.map((s) => s.value).toList()
        : (options ?? <T>[]);

    return GlassContainer(
      intensity: GlassIntensity.subtle,
      borderRadius: RadiusTokens.pillRadius,
      padding: const EdgeInsets.all(Space.xxs),
      child: Row(
        children: <Widget>[
          for (final option in effectiveOptions) ...<Widget>[
            Expanded(
              child: _SegmentItem<T>(
                option: option,
                isSelected: option == effectiveSelected,
                label: segments != null
                    ? segments!.firstWhere((s) => s.value == option).label
                    : (labels?[option] ?? option.toString()),
                onTap: () {
                  if (option != effectiveSelected) {
                    HapticFeedback.selectionClick();
                    onChanged(option);
                  }
                },
                accentColor: kairos.colours.accent,
                onAccentColor: kairos.colours.onAccent,
                textPrimary: kairos.colours.textPrimary,
                textSecondary: kairos.colours.textSecondary,
                isDark: kairos.colours.isDark,
                glass: kairos.glass,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentItem<T> extends StatelessWidget {
  const _SegmentItem({
    required this.option,
    required this.isSelected,
    required this.label,
    required this.onTap,
    required this.accentColor,
    required this.onAccentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.glass,
  });

  final T option;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final Color onAccentColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final KairosGlassTokens glass;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.90))
              : Colors.transparent,
          borderRadius: RadiusTokens.pillRadius,
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.8,
                )
              : null,
          boxShadow: isSelected ? glass.shadow : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textPrimary : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
