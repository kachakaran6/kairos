import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/core/design/colour_tokens.dart';
import 'package:kairos/core/design/type_scale_tokens.dart';
import 'package:kairos/core/theme/theme_extension.dart';

void main() {
  group('KairosThemeData', () {
    test('dark is the default canvas', () {
      final theme = KairosThemeData.dark();
      final kairos = theme.extension<KairosTheme>()!;

      expect(kairos.colours.isDark, isTrue);
      expect(kairos.colours.background, KairosColourTokens.dark.background);
      expect(theme.scaffoldBackgroundColor, kairos.colours.background);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light is a designed parallel theme', () {
      final theme = KairosThemeData.light();
      final kairos = theme.extension<KairosTheme>()!;

      expect(kairos.colours.isDark, isFalse);
      expect(kairos.colours.background, KairosColourTokens.light.background);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('body text meets 4.5:1 in both modes', () {
      for (final tokens in <KairosColourTokens>[
        KairosColourTokens.dark,
        KairosColourTokens.light,
      ]) {
        expect(
          tokens.bodyContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'body contrast',
        );
        expect(
          tokens.secondaryContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'secondary contrast',
        );
      }
    });

    test('type scale carries tabular figures on numeric styles', () {
      final scale = KairosTypeScale.standard;
      final features = scale.display.fontFeatures ?? const [];
      expect(
        features.any((f) => f.feature == 'tnum'),
        isTrue,
        reason: 'display digits must be tabular',
      );
      expect(scale.display.fontSize, 96);
      expect(scale.body.fontSize, 16);
    });

    test('both themes expose every token group through Theme.of', () {
      for (final theme in <ThemeData>[
        KairosThemeData.dark(),
        KairosThemeData.light(),
      ]) {
        final kairos = theme.extension<KairosTheme>()!;
        expect(kairos.typeScale.title.fontSize, 28);
        expect(kairos.colours.accent, isNotNull);
      }
    });
  });

  testWidgets('widgets read the extension under both modes', (tester) async {
    for (final theme in <ThemeData>[
      KairosThemeData.dark(),
      KairosThemeData.light(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              final kairos = KairosTheme.of(context);
              return Scaffold(
                backgroundColor: kairos.colours.background,
                body: Text('probe', style: kairos.typeScale.body),
              );
            },
          ),
        ),
      );

      expect(find.text('probe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
