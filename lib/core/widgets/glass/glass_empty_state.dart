import 'package:flutter/material.dart';

import '../../design/glass_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';
import 'glass_button.dart';
import 'glass_container.dart';

/// Spec §4 & §6: A premium glassmorphic empty state composition.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.description,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String heading;
  final String description;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.phoneMargin,
          vertical: Space.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Glowing circular glass icon container
            GlassContainer(
              width: 88,
              height: 88,
              borderRadius: BorderRadius.circular(44),
              intensity: GlassIntensity.primary,
              child: Center(
                child: Icon(icon, size: 40, color: kairos.colours.accent),
              ),
            ),
            const SizedBox(height: Space.xl),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: kairos.typeScale.title.copyWith(
                color: kairos.colours.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 24,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: Space.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: kairos.typeScale.body.copyWith(
                  color: kairos.colours.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: Space.xxl),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: GlassButton(
                onPressed: onPrimaryAction,
                label: primaryActionLabel,
                isPrimary: true,
                icon: const Icon(Icons.add),
              ),
            ),
            if (secondaryActionLabel != null &&
                onSecondaryAction != null) ...<Widget>[
              const SizedBox(height: Space.sm),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: kairos.typeScale.caption.copyWith(
                    color: kairos.colours.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
