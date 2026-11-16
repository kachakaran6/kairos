import 'package:flutter/material.dart';

import '../../core/design/spacing_tokens.dart';
import '../../core/theme/theme_extension.dart';

/// Honest empty state for a tab that has no records yet.
class EmptyTab extends StatelessWidget {
  const EmptyTab({
    super.key,
    required this.title,
    required this.headline,
    required this.body,
  });

  final String title;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.hourglass_empty,
                size: Space.xxxl,
                color: kairos.colours.textTertiary,
              ),
              const SizedBox(height: Space.lg),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: kairos.typeScale.title,
              ),
              const SizedBox(height: Space.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: kairos.typeScale.body.copyWith(
                  color: kairos.colours.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
