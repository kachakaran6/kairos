import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spec §19: The shared data payload exchanged across the native widget bridge.
class KairosWidgetPayload {
  const KairosWidgetPayload({
    required this.generatedAtUtc,
    this.activeMoment,
    this.nextMoments = const <Map<String, dynamic>>[],
    this.todayFocusSessions = 0,
    this.nextAlarmTime,
    this.nextAlarmLabel,
  });

  final DateTime generatedAtUtc;
  final Map<String, dynamic>? activeMoment;
  final List<Map<String, dynamic>> nextMoments;
  final int todayFocusSessions;
  final String? nextAlarmTime;
  final String? nextAlarmLabel;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
    'activeMoment': activeMoment,
    'nextMoments': nextMoments,
    'todayFocusSessions': todayFocusSessions,
    'nextAlarmTime': nextAlarmTime,
    'nextAlarmLabel': nextAlarmLabel,
  };

  factory KairosWidgetPayload.fromJson(Map<String, dynamic> json) {
    return KairosWidgetPayload(
      generatedAtUtc: DateTime.parse(json['generatedAtUtc'] as String).toUtc(),
      activeMoment: json['activeMoment'] as Map<String, dynamic>?,
      nextMoments: (json['nextMoments'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(),
      todayFocusSessions: json['todayFocusSessions'] as int? ?? 0,
      nextAlarmTime: json['nextAlarmTime'] as String?,
      nextAlarmLabel: json['nextAlarmLabel'] as String?,
    );
  }
}

/// Abstract contract for the widget bridge.
abstract interface class WidgetBridge {
  Future<void> syncPayload(KairosWidgetPayload payload);
  Future<void> reloadAllTimelines();
}

/// Production implementation communicating with iOS AppGroup UserDefaults
/// and Android Jetpack Glance storage via MethodChannel and SharedPreferences.
class MethodChannelWidgetBridge implements WidgetBridge {
  const MethodChannelWidgetBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.kairos/widget_bridge');

  final MethodChannel _channel;
  static const String prefsKey = 'kairos_widget_payload_json';

  @override
  Future<void> syncPayload(KairosWidgetPayload payload) async {
    final jsonString = jsonEncode(payload.toJson());

    // 1. Write to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonString);
    } catch (_) {
      // Ignore in mock or restricted environments
    }

    // 2. Transmit to native App Group via MethodChannel
    try {
      await _channel.invokeMethod<void>('syncWidgetData', <String, dynamic>{
        'payload': jsonString,
      });
    } on MissingPluginException {
      // Safe fallback when running on web, unit test, or unlinked platform
    } catch (_) {
      // Non-fatal native bridge exception
    }
  }

  @override
  Future<void> reloadAllTimelines() async {
    try {
      await _channel.invokeMethod<void>('reloadAllTimelines');
    } on MissingPluginException {
      // Safe fallback in test harnesses
    } catch (_) {
      // Non-fatal native bridge exception
    }
  }
}

final widgetBridgeProvider = Provider<WidgetBridge>((ref) {
  return const MethodChannelWidgetBridge();
});
