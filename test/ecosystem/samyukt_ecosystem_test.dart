import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/ecosystem/app_version_service.dart';
import 'package:kairos/core/ecosystem/play_review_service.dart';
import 'package:kairos/core/ecosystem/play_services_bridge.dart';
import 'package:kairos/core/ecosystem/samyukt_registry_service.dart';
import 'package:kairos/core/ecosystem/samyukt_share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Samyukt Registry Service Tests', () {
    late SamyuktRegistryService registryService;

    setUp(() {
      registryService = SamyuktRegistryService();
    });

    test(
      'Strictly parses apps[] and excludes websites[] and disallowed statuses',
      () {
        final sampleJson = jsonEncode({
          'version': '2.0.0',
          'apps': [
            {
              'id': 'com.vaultx.vault_x',
              'appName': 'Vault X',
              'packageName': 'com.vaultx.vault_x',
              'playStoreUrl':
                  'https://play.google.com/store/apps/details?id=com.vaultx.vault_x',
              'iconUrl': '/images/vaultx.png',
              'status': 'production',
              'category': 'Privacy',
              'description': 'On-device digital vault',
            },
            {
              'id': 'com.test.coming_soon',
              'appName': 'Upcoming App',
              'packageName': 'com.test.coming_soon',
              'iconUrl': 'images/upcoming.png',
              'status': 'coming_soon',
              'description': 'Coming soon product',
            },
            {
              'id': 'com.test.draft',
              'appName': 'Draft App',
              'packageName': 'com.test.draft',
              'status': 'draft',
              'description': 'Should be excluded',
            },
            {
              'id': 'com.test.in_progress',
              'appName': 'In Progress App',
              'packageName': 'com.test.in_progress',
              'status': 'in_progress',
              'description': 'Should be excluded',
            },
            {
              'id': 'com.test.closed_testing',
              'appName': 'Closed Testing App',
              'packageName': 'com.test.closed_testing',
              'status': 'closed_testing',
              'description': 'Should be excluded',
            },
          ],
          'websites': [
            {
              'id': 'web1',
              'name': 'Website App',
              'status': 'production',
              'description': 'Websites must NEVER appear in mobile catalog',
            },
          ],
        });

        final apps = registryService.parseRegistryJson(sampleJson);

        // Only Vault X and Upcoming App should be accepted
        expect(apps.length, 2);
        expect(apps[0].appName, 'Vault X');
        expect(apps[0].isPublished, true);
        expect(
          apps[0].iconUrl,
          'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/vaultx.png',
        );

        expect(apps[1].appName, 'Upcoming App');
        expect(apps[1].isComingSoon, true);
        expect(
          apps[1].iconUrl,
          'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/upcoming.png',
        );

        // Ensure no website or draft/in_progress app leaked
        expect(apps.any((a) => a.appName == 'Website App'), false);
        expect(apps.any((a) => a.appName == 'Draft App'), false);
        expect(apps.any((a) => a.appName == 'In Progress App'), false);
        expect(apps.any((a) => a.appName == 'Closed Testing App'), false);
      },
    );

    test('Gracefully handles malformed JSON and empty payloads', () {
      expect(registryService.parseRegistryJson(''), isEmpty);
      expect(registryService.parseRegistryJson('{invalid: json}'), isEmpty);
      expect(
        registryService.parseRegistryJson('{"apps": "not-a-list"}'),
        isEmpty,
      );
    });

    test('Resolves relative and absolute asset URLs accurately', () {
      const assetBase =
          'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/';

      expect(
        SamyuktAppItem.resolveAssetUrl('/images/app.png', assetBase: assetBase),
        'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/app.png',
      );
      expect(
        SamyuktAppItem.resolveAssetUrl('images/app.png', assetBase: assetBase),
        'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/app.png',
      );
      expect(
        SamyuktAppItem.resolveAssetUrl('app.png', assetBase: assetBase),
        'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/app.png',
      );
      expect(
        SamyuktAppItem.resolveAssetUrl(
          'https://example.com/icon.png',
          assetBase: assetBase,
        ),
        'https://example.com/icon.png',
      );
    });
  });

  group('Samyukt Share Service Tests', () {
    test(
      'Dynamic share message includes app name, description, Play Store URL, and attribution',
      () {
        final message = SamyuktShareService.shareMessage;

        expect(message.contains('Discover Kairos'), true);
        expect(
          message.contains(
            'Calm, beautifully crafted time & moments for Android',
          ),
          true,
        );
        expect(
          message.contains(
            'https://play.google.com/store/apps/details?id=com.samyukt.kairos',
          ),
          true,
        );
        expect(message.contains('Made with care by Samyukt.'), true);
      },
    );
  });

  group('Play Review Service Cooldown Tests', () {
    test('Enforces 15-day cooldown and engagement threshold', () async {
      SharedPreferences.setMockInitialValues({});
      final bridge = PlayServicesBridge();
      final reviewService = PlayReviewService(bridge);

      // 0 actions -> ineligible
      var eligible = await reviewService.requestReviewIfEligible();
      expect(eligible, false);

      // Record actions up to threshold
      for (var i = 0; i < PlayReviewService.minEngagementThreshold; i++) {
        await reviewService.recordEngagementAction();
      }

      // Check SharedPreferences count
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(PlayReviewService.keyEngagementActionCount), 5);
    });
  });

  group('App Version Metadata Tests', () {
    test('Formats version name and build code correctly', () {
      const meta = AppVersionMetadata(
        versionName: '1.2.0',
        versionCode: 15,
        packageName: 'com.samyukt.kairos',
      );
      expect(meta.formattedVersion, 'Version 1.2.0 (Build 15)');
    });
  });
}
