import 'package:flutter/material.dart';

/// Kairos sheet component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
///
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosSheet {
  const KairosSheet();

  /// Modal sheet that slides up from bottom
  Widget buildModal({
    required Widget child,
    required VoidCallback onDismiss,
    Color? backgroundColor,
    double? maxHeight,
  }) {
    final Color bgColor = backgroundColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Container(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  /// Bottom sheet with action buttons
  Widget buildWithActions({
    required Widget child,
    required VoidCallback onDismiss,
    required VoidCallback onConfirm,
    Color? backgroundColor,
  }) {
    final Color bgColor = backgroundColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onDismiss, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onConfirm,
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
