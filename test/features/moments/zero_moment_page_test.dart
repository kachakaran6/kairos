import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/app/theme/kairos_theme_data.dart';
import 'package:kairos/features/moments/domain/moment.dart';
import 'package:kairos/features/moments/presentation/zero_moment_page.dart';

void main() {
  testWidgets('ZeroMomentPage renders celebratory statement and moment title', (
    tester,
  ) async {
    final moment = Moment(
      id: 'm1',
      title: 'Graduation Ceremony',
      subtitle: 'Class of 2026',
      targetUtc: DateTime.utc(2026, 11, 16, 12),
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: KairosThemeData.dark(),
        home: ZeroMomentPage(moment: moment),
      ),
    );

    // Initial pump
    await tester.pump();

    expect(find.text('THE ZERO MOMENT'), findsOneWidget);
    expect(find.text('It is here.'), findsOneWidget);
    expect(find.text('Graduation Ceremony'), findsOneWidget);
    expect(find.text('Class of 2026'), findsOneWidget);
    expect(find.text('Now counting forward in Then'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Replay
    await tester.tap(find.text('Replay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('THE ZERO MOMENT'), findsOneWidget);
  });
}
