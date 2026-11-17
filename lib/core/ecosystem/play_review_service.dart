import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'play_services_bridge.dart';
import 'play_update_service.dart';

final playReviewServiceProvider = Provider<PlayReviewService>((ref) {
  final bridge = ref.watch(playServicesBridgeProvider);
  return PlayReviewService(bridge);
});

/// Manages Google Play In-App Review with mandatory 15-day cooldown and engagement criteria.
class PlayReviewService {
  PlayReviewService(this._bridge);

  final PlayServicesBridge _bridge;

  static const String keyLastReviewTimestamp =
      'samyukt_last_review_request_timestamp';
  static const String keyEngagementActionCount =
      'samyukt_engagement_action_count';

  static const int minEngagementThreshold = 5;
  static const Duration cooldownDuration = Duration(days: 15);

  bool _isReviewFlowActive = false;

  /// Logs a meaningful user action (e.g. created moment, set alarm, completed focus session).
  Future<void> recordEngagementAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(keyEngagementActionCount) ?? 0;
      await prefs.setInt(keyEngagementActionCount, current + 1);
    } catch (_) {}
  }

  /// Evaluates engagement criteria and requests in-app review if 15-day cooldown has elapsed.
  Future<bool> requestReviewIfEligible() async {
    if (_isReviewFlowActive) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getInt(keyLastReviewTimestamp);
      final count = prefs.getInt(keyEngagementActionCount) ?? 0;

      final now = DateTime.now();

      // Check engagement threshold
      if (count < minEngagementThreshold) {
        return false;
      }

      // Check 15-day cooldown
      if (lastTimestamp != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
        if (now.difference(lastDate) < cooldownDuration) {
          return false;
        }
      }

      _isReviewFlowActive = true;

      // Update cooldown timestamp immediately before triggering to prevent duplicate flows
      await prefs.setInt(keyLastReviewTimestamp, now.millisecondsSinceEpoch);

      final success = await _bridge.requestInAppReview();
      _isReviewFlowActive = false;
      return success;
    } catch (_) {
      _isReviewFlowActive = false;
      return false;
    }
  }

  /// Rate Now: Opens official Google Play Store listing directly.
  Future<bool> rateNow() async {
    return _bridge.openPlayStoreListing();
  }
}
