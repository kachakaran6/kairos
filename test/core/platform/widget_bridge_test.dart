import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/platform/widget_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KairosWidgetPayload', () {
    test(
      'serializes and deserializes accurately across the bridge contract',
      () {
        final now = DateTime.utc(2026, 11, 16, 14, 30);
        final payload = KairosWidgetPayload(
          generatedAtUtc: now,
          activeMoment: <String, dynamic>{
            'id': 'm1',
            'title': 'Birthday Celebration',
            'daysRemaining': 5,
          },
          nextMoments: <Map<String, dynamic>>[
            <String, dynamic>{'title': 'Product Launch', 'daysRemaining': 12},
          ],
          todayFocusSessions: 4,
          nextAlarmTime: '07:30',
          nextAlarmLabel: 'Morning Workout',
        );

        final json = payload.toJson();
        final decoded = KairosWidgetPayload.fromJson(json);

        expect(decoded.generatedAtUtc, now);
        expect(decoded.activeMoment?['title'], 'Birthday Celebration');
        expect(decoded.nextMoments.length, 1);
        expect(decoded.nextMoments.first['title'], 'Product Launch');
        expect(decoded.todayFocusSessions, 4);
        expect(decoded.nextAlarmTime, '07:30');
        expect(decoded.nextAlarmLabel, 'Morning Workout');
      },
    );

    test(
      'MethodChannelWidgetBridge handles storage and safe channel dispatch',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});

        const bridge = MethodChannelWidgetBridge();
        final now = DateTime.utc(2026, 11, 16, 12);
        final payload = KairosWidgetPayload(
          generatedAtUtc: now,
          todayFocusSessions: 2,
        );

        // Should complete gracefully without throwing MissingPluginException
        await bridge.syncPayload(payload);
        await bridge.reloadAllTimelines();

        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString(MethodChannelWidgetBridge.prefsKey);
        expect(saved, isNotNull);
        expect(saved, contains('todayFocusSessions'));
      },
    );
  });
}
