import 'package:flutter/material.dart';

import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';

/// Spec §12: An Apple-inspired section header with elegant typography and action.
class GlassSectionHeader extends StatelessWidget {
  const GlassSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: Space.xxs,
        right: Space.xxs,
        bottom: Space.sm,
        top: Space.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: kairos.typeScale.caption.copyWith(
              color: kairos.colours.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
