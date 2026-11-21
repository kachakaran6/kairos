import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/spacing_tokens.dart';
import '../theme/theme_extension.dart';

/// One consistent top bar and layout structure for all Kairos screens.
class KairosScaffold extends StatelessWidget {
  const KairosScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final canPop = showBackButton || Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: kairos.colours.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null || canPop || actions != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.md,
                  Space.xl,
                  Space.sm,
                ),
                child: Row(
                  children: <Widget>[
                    if (canPop) ...<Widget>[
                      _CircularBackButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                      const SizedBox(width: Space.md),
                    ],
                    if (title != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              title!,
                              style: kairos.typeScale.title.copyWith(
                                color: kairos.colours.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: kairos.typeScale.caption.copyWith(
                                  color: kairos.colours.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding:
                    padding ?? const EdgeInsets.symmetric(horizontal: Space.xl),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularBackButton extends StatelessWidget {
  const _CircularBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Semantics(
      button: true,
      label: 'Back',
      child: Tooltip(
        message: 'Back',
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: InkResponse(
              onTap: onPressed,
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              radius: 24,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kairos.colours.surfaceElevated.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: kairos.colours.border, width: 1),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.chevronLeft,
                    color: kairos.colours.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
