import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'play_services_bridge.dart';
import 'play_update_service.dart';

class AppVersionMetadata {
  const AppVersionMetadata({
    required this.versionName,
    required this.versionCode,
    required this.packageName,
  });

  final String versionName;
  final int versionCode;
  final String packageName;

  String get formattedVersion => 'Version $versionName (Build $versionCode)';
}

final appVersionServiceProvider = Provider<AppVersionService>((ref) {
  final bridge = ref.watch(playServicesBridgeProvider);
  return AppVersionService(bridge);
});

class AppVersionService {
  AppVersionService(this._bridge);

  final PlayServicesBridge _bridge;
  AppVersionMetadata? _cached;

  Future<AppVersionMetadata> getVersionMetadata() async {
    if (_cached != null) return _cached!;

    final data = await _bridge.getAppVersionInfo();
    final name = (data['versionName'] as String?) ?? '1.0.0';
    final code = (data['versionCode'] as num?)?.toInt() ?? 1;
    final pkg = (data['packageName'] as String?) ?? 'com.samyukt.kairos';

    _cached = AppVersionMetadata(
      versionName: name,
      versionCode: code,
      packageName: pkg,
    );
    return _cached!;
  }
}
