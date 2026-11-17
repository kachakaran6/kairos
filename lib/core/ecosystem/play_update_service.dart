import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'play_services_bridge.dart';

final playServicesBridgeProvider = Provider<PlayServicesBridge>((ref) {
  final bridge = PlayServicesBridge();
  ref.onDispose(bridge.dispose);
  return bridge;
});

final playUpdateServiceProvider = Provider<PlayUpdateService>((ref) {
  final bridge = ref.watch(playServicesBridgeProvider);
  final service = PlayUpdateService(bridge);
  ref.onDispose(service.dispose);
  return service;
});

enum UpdateFlowStatus {
  idle,
  checking,
  available,
  inProgress,
  downloading,
  downloaded,
  failed,
  canceled,
  notAvailable,
}

class PlayUpdateState {
  const PlayUpdateState({
    this.status = UpdateFlowStatus.idle,
    this.availableVersionCode,
    this.updatePriority = 0,
    this.clientVersionStalenessDays,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
    this.errorMessage,
  });

  final UpdateFlowStatus status;
  final int? availableVersionCode;
  final int updatePriority;
  final int? clientVersionStalenessDays;
  final int bytesDownloaded;
  final int totalBytesToDownload;
  final String? errorMessage;

  double get downloadProgress =>
      totalBytesToDownload > 0 ? bytesDownloaded / totalBytesToDownload : 0.0;
}

class PlayUpdateService with WidgetsBindingObserver {
  PlayUpdateService(this._bridge) {
    _init();
  }

  final PlayServicesBridge _bridge;
  final ValueNotifier<PlayUpdateState> state = ValueNotifier<PlayUpdateState>(
    const PlayUpdateState(),
  );

  StreamSubscription<Map<String, dynamic>>? _installSub;
  StreamSubscription<void>? _downloadedSub;
  StreamSubscription<Map<String, dynamic>>? _flowResultSub;

  DateTime? _lastCheckTimestamp;
  bool _isPromptActive = false;

  void _init() {
    WidgetsBinding.instance.addObserver(this);

    _installSub = _bridge.installStateStream.listen((event) {
      final statusInt = event['installStatus'] as int? ?? 0;
      final bytes = event['bytesDownloaded'] as int? ?? 0;
      final total = event['totalBytesToDownload'] as int? ?? 0;

      // 2 = DOWNLOADING, 11 = DOWNLOADED, 5 = FAILED, 6 = CANCELED
      if (statusInt == 2) {
        state.value = PlayUpdateState(
          status: UpdateFlowStatus.downloading,
          bytesDownloaded: bytes,
          totalBytesToDownload: total,
          availableVersionCode: state.value.availableVersionCode,
        );
      } else if (statusInt == 11) {
        state.value = PlayUpdateState(
          status: UpdateFlowStatus.downloaded,
          bytesDownloaded: total,
          totalBytesToDownload: total,
          availableVersionCode: state.value.availableVersionCode,
        );
      } else if (statusInt == 5) {
        state.value = PlayUpdateState(
          status: UpdateFlowStatus.failed,
          errorMessage: 'Update download failed',
        );
      } else if (statusInt == 6) {
        state.value = const PlayUpdateState(status: UpdateFlowStatus.canceled);
      }
    });

    _downloadedSub = _bridge.flexibleUpdateDownloadedStream.listen((_) {
      state.value = PlayUpdateState(
        status: UpdateFlowStatus.downloaded,
        availableVersionCode: state.value.availableVersionCode,
      );
    });

    _flowResultSub = _bridge.updateFlowResultStream.listen((event) {
      _isPromptActive = false;
      final canceled = event['canceled'] as bool? ?? false;
      final success = event['success'] as bool? ?? false;

      if (canceled) {
        state.value = const PlayUpdateState(status: UpdateFlowStatus.canceled);
      } else if (!success) {
        state.value = const PlayUpdateState(status: UpdateFlowStatus.failed);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      // Avoid spamming checks on rapid foreground toggles (throttle to 10 minutes)
      final now = DateTime.now();
      if (_lastCheckTimestamp == null ||
          now.difference(_lastCheckTimestamp!) > const Duration(minutes: 10)) {
        checkAndPromptUpdate(isAutomatic: true);
      }
    }
  }

  /// Evaluates update availability and executes immediate or flexible flow based on priority.
  Future<bool> checkAndPromptUpdate({bool isAutomatic = false}) async {
    if (_isPromptActive) return false;

    _lastCheckTimestamp = DateTime.now();
    state.value = const PlayUpdateState(status: UpdateFlowStatus.checking);

    final info = await _bridge.checkForUpdate();
    final isAvailable = info['available'] as bool? ?? false;
    final isInProgress = info['inProgress'] as bool? ?? false;
    final isImmediateAllowed = info['immediateAllowed'] as bool? ?? false;
    final isFlexibleAllowed = info['flexibleAllowed'] as bool? ?? false;
    final priority = info['updatePriority'] as int? ?? 0;
    final staleness = info['clientVersionStalenessDays'] as int?;
    final versionCode = info['availableVersionCode'] as int?;

    if (isInProgress) {
      state.value = PlayUpdateState(
        status: UpdateFlowStatus.inProgress,
        availableVersionCode: versionCode,
        updatePriority: priority,
      );
      return true;
    }

    if (!isAvailable) {
      state.value = const PlayUpdateState(
        status: UpdateFlowStatus.notAvailable,
      );
      return false;
    }

    state.value = PlayUpdateState(
      status: UpdateFlowStatus.available,
      availableVersionCode: versionCode,
      updatePriority: priority,
      clientVersionStalenessDays: staleness,
    );

    // Update Policy:
    // Immediate flow: priority >= 4 or staleness > 14 days (or manual request with immediate permitted)
    final shouldBeImmediate = (priority >= 4 || (staleness ?? 0) > 14);

    if (shouldBeImmediate && isImmediateAllowed) {
      _isPromptActive = true;
      await _bridge.startImmediateUpdate();
      return true;
    } else if (isFlexibleAllowed) {
      _isPromptActive = true;
      await _bridge.startFlexibleUpdate();
      return true;
    } else if (isImmediateAllowed) {
      _isPromptActive = true;
      await _bridge.startImmediateUpdate();
      return true;
    }

    return false;
  }

  /// Triggers restart to install a downloaded flexible update.
  Future<bool> completeFlexibleUpdate() async {
    return _bridge.completeFlexibleUpdate();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _installSub?.cancel();
    _downloadedSub?.cancel();
    _flowResultSub?.cancel();
  }
}
