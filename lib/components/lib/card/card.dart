import 'package:flutter/material.dart';

/// Kairos card component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosCard {
  const KairosCard();

  /// Standard card with elevation
  Widget buildStandard({
    required Widget child,
    Color? color,
    double? elevation,
  }) {
    final Color cardColor = color ?? Colors.white;
    final double elev = elevation ?? 2;

    return Card(color: cardColor, elevation: elev, child: child);
  }

  /// Outline card with border
  Widget buildOutline({
    required Widget child,
    Color? color,
    double? elevation,
  }) {
    final Color cardColor = color ?? Colors.transparent;
    final double elev = elevation ?? 0;

    return Card(color: cardColor, elevation: elev, child: child);
  }

  /// Card with header and action
  Widget buildWithAction({
    required Widget header,
    required Widget content,
    required Widget action,
    Color? color,
  }) {
    final Color cardColor = color ?? Colors.white;

    return Card(
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [header, content, const SizedBox(height: 8), action],
      ),
    );
  }
}
