import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/core/theme/theme_extension.dart';
import 'package:kairos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app boots in light mode with Kairos theme attached', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const KairosApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    final kairos = KairosTheme.of(context);

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, kairos.colours.background);
    expect(find.text('Now'), findsWidgets);
    expect(find.text('World clock'), findsOneWidget);
  });

  testWidgets('app follows the system into dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const KairosApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final kairos = KairosTheme.of(context);

    expect(Theme.of(context).brightness, Brightness.dark);
    expect(kairos.colours.background, const Color(0xFF0C0C0F));
  });

  test('both themes build without throwing', () {
    expect(KairosThemeData.dark().extension<KairosTheme>(), isNotNull);
    expect(KairosThemeData.light().extension<KairosTheme>(), isNotNull);
  });
}
