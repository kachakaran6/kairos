import 'package:flutter/material.dart';

/// A widget for big time digits with tabular figures and per-digit rolling animation
/// so seconds tick smoothly without horizontal reflow.
class NumeralText extends StatelessWidget {
  const NumeralText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        for (int i = 0; i < text.length; i++)
          _RollingDigit(char: text[i], style: effectiveStyle),
      ],
    );
  }
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({required this.char, required this.style});

  final String char;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final isDigit = RegExp(r'[0-9]').hasMatch(char);

    if (!isDigit) {
      return Text(char, style: style);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: inAnimation, child: child),
        );
      },
      child: Text(char, key: ValueKey<String>(char), style: style),
    );
  }
}
