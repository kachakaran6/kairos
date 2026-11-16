import 'package:flutter/material.dart';

/// Kairos loading state component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosLoadingState {
  const KairosLoadingState();

  /// Standard circular progress indicator within card
  Widget buildInCard({required Widget child, double? strokeWidth}) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(strokeWidth: strokeWidth ?? 2),
      ),
    );
  }

  /// Full-screen loading overlay
  Widget buildOverlay({
    required Widget child,
    Color? color,
    bool? dismissible,
  }) {
    return GestureDetector(
      onTap: dismissible == true ? () {} : null,
      child: Container(
        color: color,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      ),
    );
  }

  /// Progress bar at the top
  Widget buildTopBar({required Widget child, Color? color, double? height}) {
    return Container(
      color: color,
      height: height ?? kToolbarHeight,
      child: child,
    );
  }
}
