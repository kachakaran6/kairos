import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design/motion_tokens.dart';
import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';

/// Floating pill bottom navigation bar with luxury frosted glass and smooth sliding capsule.
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = kairos.colours.isDark;

    return Padding(
      padding: EdgeInsets.only(
        left: Space.phoneMargin,
        right: Space.phoneMargin,
        bottom: bottomPadding > 0 ? bottomPadding : Space.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? kairos.colours.surface.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              border: Border.all(color: kairos.colours.border, width: 1.0),
              boxShadow: isDark
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x121A1714),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;

                return Stack(
                  children: <Widget>[
                    // Smooth sliding selection capsule
                    AnimatedPositioned(
                      duration: MotionTokens.fast,
                      curve: Curves.easeOutCubic,
                      left: currentIndex * tabWidth + 6,
                      top: 6,
                      bottom: 6,
                      width: tabWidth - 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kairos.colours.accent.withValues(
                            alpha: isDark ? 0.22 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(
                            RadiusTokens.pill,
                          ),
                          border: Border.all(
                            color: kairos.colours.accent.withValues(
                              alpha: 0.25,
                            ),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),

                    // Navigation items
                    Row(
                      children: <Widget>[
                        _NavItem(
                          index: 0,
                          label: 'Next',
                          icon: const Icon(LucideIcons.calendar),
                          currentIndex: currentIndex,
                          onTap: (idx) {
                            HapticFeedback.selectionClick();
                            onChanged(idx);
                          },
                        ),
                        _NavItem(
                          index: 1,
                          label: 'Now',
                          icon: const Icon(LucideIcons.clock),
                          currentIndex: currentIndex,
                          onTap: (idx) {
                            HapticFeedback.selectionClick();
                            onChanged(idx);
                          },
                        ),
                        _NavItem(
                          index: 2,
                          label: 'Then',
                          icon: const Icon(LucideIcons.history),
                          currentIndex: currentIndex,
                          onTap: (idx) {
                            HapticFeedback.selectionClick();
                            onChanged(idx);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
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

  bool get _selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconTheme(
                data: IconThemeData(
                  size: 19,
                  color: _selected ? colours.accent : colours.textSecondary,
                ),
                child: icon,
              ),
              const SizedBox(width: Space.xs),
              Text(
                label,
                style: kairos.typeScale.caption.copyWith(
                  fontSize: 13,
                  fontWeight: _selected ? FontWeight.w600 : FontWeight.w400,
                  color: _selected ? colours.accent : colours.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
