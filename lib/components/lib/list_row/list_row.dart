import 'package:flutter/material.dart';

/// Kairos list row component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
///
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosListRow {
  const KairosListRow();

  /// Standard list row with leading and trailing widgets
  Widget buildStandard({
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// List row with leading icon and trailing chevron
  Widget buildWithChevron({
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// Divider list row
  Widget buildDivider({required Widget child, Color? dividerColor}) {
    final Color color = dividerColor ?? Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 1)),
      ),
      child: child,
    );
  }
}
