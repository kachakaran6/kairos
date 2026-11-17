import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'play_services_bridge.dart';
import 'play_update_service.dart';

final samyuktShareServiceProvider = Provider<SamyuktShareService>((ref) {
  final bridge = ref.watch(playServicesBridgeProvider);
  return SamyuktShareService(bridge);
});

class SamyuktShareService {
  const SamyuktShareService(this._bridge);

  final PlayServicesBridge _bridge;

  static const String appName = 'Kairos';
  static const String shortDescription =
      'Calm, beautifully crafted time & moments for Android';
  static const String packageName = 'com.samyukt.kairos';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  /// Generates the official application sharing message.
  static String get shareMessage =>
      'Discover $appName — $shortDescription.\n\n'
      'Explore the app and try it today:\n'
      '$playStoreUrl\n\n'
      'Made with care by Samyukt.';

  /// Opens the native Android Sharesheet with the application message.
  Future<bool> shareApplication() async {
    return _bridge.shareApp(
      text: shareMessage,
      subject: 'Discover Kairos — Time & Moments',
    );
  }
}
