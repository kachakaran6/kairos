import 'dart:async';
import 'package:flutter/services.dart';

/// Low-level MethodChannel bridge to native Google Play Core APIs and Android system services.
class PlayServicesBridge {
  PlayServicesBridge() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel = MethodChannel(
    'com.samyukt.kairos/ecosystem',
  );

  final StreamController<Map<String, dynamic>> _installStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _flexibleUpdateDownloadedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>> _updateFlowResultController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get installStateStream =>
      _installStateController.stream;
  Stream<void> get flexibleUpdateDownloadedStream =>
      _flexibleUpdateDownloadedController.stream;
  Stream<Map<String, dynamic>> get updateFlowResultStream =>
      _updateFlowResultController.stream;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onInstallStateUpdated':
        if (call.arguments is Map) {
          _installStateController.add(
            Map<String, dynamic>.from(call.arguments as Map),
          );
        }
        break;
      case 'onFlexibleUpdateDownloaded':
        _flexibleUpdateDownloadedController.add(null);
        break;
      case 'onUpdateFlowResult':
        if (call.arguments is Map) {
          _updateFlowResultController.add(
            Map<String, dynamic>.from(call.arguments as Map),
          );
        }
        break;
    }
  }

  /// Calls Google Play In-App Updates API to check availability and staleness.
  Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkForUpdate',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Offline, unsupported device, or Play Store not present
    }
    return <String, dynamic>{
      'available': false,
      'inProgress': false,
      'updateAvailability': 1,
    };
  }

  /// Starts official Google Play immediate update flow.
  Future<Map<String, dynamic>> startImmediateUpdate() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startImmediateUpdate',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return <String, dynamic>{'success': false, 'canceled': false};
  }

  /// Starts official Google Play flexible update flow.
  Future<Map<String, dynamic>> startFlexibleUpdate() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'startFlexibleUpdate',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return <String, dynamic>{'success': false, 'canceled': false};
  }

  /// Triggers app restart to finish applying a downloaded flexible update.
  Future<bool> completeFlexibleUpdate() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'completeFlexibleUpdate',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests official Google Play In-App Review dialog.
  Future<bool> requestInAppReview() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'requestInAppReview',
      );
      return result != null && (result['completed'] as bool? ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Opens official Google Play Store listing (Rate Now or external app).
  Future<bool> openPlayStoreListing({String? packageName}) async {
    try {
      final result = await _channel.invokeMethod<bool>('openPlayStoreListing', {
        if (packageName != null) 'packageName': packageName,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens native Android Sharesheet with application details.
  Future<bool> shareApp({required String text, String? subject}) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareApp', {
        'text': text,
        'subject': subject ?? 'Kairos',
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reads actual versionName and versionCode from PackageManager.
  Future<Map<String, dynamic>> getAppVersionInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getAppVersionInfo',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return <String, dynamic>{
      'versionName': '1.0.0',
      'versionCode': 1,
      'packageName': 'com.samyukt.kairos',
    };
  }

  /// Opens external URL (e.g. https://samyukt.pro).
  Future<bool> openUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _installStateController.close();
    _flexibleUpdateDownloadedController.close();
    _updateFlowResultController.close();
  }
}
