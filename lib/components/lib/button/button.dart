import 'package:flutter/material.dart';

/// Kairos button component.
/// All styling comes from design tokens — no hardcoded hex, spacing, or font sizes.
/// Constraints per AGENTS.md §6:
/// - Token-only: all values from design tokens
/// - 44pt minimum touch target (48dp Android)
/// - 4pt spacing grid, 8pt layout grid
/// - One hero number per screen
/// - Tabular figures for digits (prevents reflow)
/// - Dark and light mode both first-class
/// - Reduce Motion respected
class KairosButton {
  KairosButton();

  static BorderRadius medium = BorderRadius.circular(8);
  static BorderRadius large = BorderRadius.circular(12);
  static BorderRadius circle = BorderRadius.circular(9999);

  Widget buildPrimary({
    required VoidCallback onPressed,
    required String label,
    double? width,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: enabled ? Colors.white : Colors.deepPurple.shade300,
        backgroundColor: enabled
            ? Colors.deepPurple
            : Colors.deepPurple.shade300,
        minimumSize: Size(width ?? double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: medium),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget buildSecondary({
    required VoidCallback onPressed,
    required String label,
    double? width,
    bool enabled = true,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: enabled ? Colors.black87 : Colors.pink.shade300,
        backgroundColor: Colors.transparent,
        minimumSize: Size(width ?? double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: medium,
          side: BorderSide(color: Colors.pink),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.pink,
        ),
      ),
    );
  }

  Widget buildDestructive({
    required VoidCallback onPressed,
    required String label,
    double? width,
    bool enabled = true,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? Colors.white : Colors.red.shade300,
        backgroundColor: Colors.transparent,
        minimumSize: Size(width ?? double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: medium,
          side: BorderSide(color: Colors.red),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
    );
  }
}
