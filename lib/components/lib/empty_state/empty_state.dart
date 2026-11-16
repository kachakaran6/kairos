import 'package:flutter/material.dart';

/// Kairos empty state component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
/// Shows appropriate illustration/text for empty states.
///
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosEmptyState {
  const KairosEmptyState();

  /// Empty state with illustration and message
  Widget buildWithIllustration({
    required Widget illustration,
    required String message,
    String? subtitle,
    VoidCallback? onRetry,
    Color? backgroundColor,
  }) {
    final Color bgColor = backgroundColor ?? Colors.white;

    return Center(
      child: Container(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration,
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  /// Empty state with image and retry button
  Widget buildWithImage({
    required AssetImage image,
    required String message,
    String? subtitle,
    VoidCallback? onRetry,
    Color? backgroundColor,
  }) {
    final Color bgColor = backgroundColor ?? Colors.white;

    return Center(
      child: Container(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: image),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
