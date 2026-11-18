import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../domain/globe_config.dart';

/// Manages camera rotation, arcball interaction, inertia physics,
/// pinch-to-zoom, and smooth fly-to animations for the 3D globe.
class GlobeController extends ChangeNotifier {
  GlobeController({
    TickerProvider? vsync,
    GlobeConfig? config,
    bool disableAnimations = false,
  }) : _config = config ?? const GlobeConfig(),
       _disableAnimations = disableAnimations {
    _lonRotation = -0.5;
    _latTilt = _config.axialTiltRad;

    if (vsync != null) {
      _ticker = vsync.createTicker(_onTick);
      _flyToController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 900),
      );
      if (!_disableAnimations) {
        _ticker?.start();
      }
    }
  }

  GlobeConfig _config;
  GlobeConfig get config => _config;
  set config(GlobeConfig newConfig) {
    _config = newConfig;
    notifyListeners();
  }

  bool _disableAnimations;
  bool get disableAnimations => _disableAnimations;
  set disableAnimations(bool val) {
    if (_disableAnimations == val) return;
    _disableAnimations = val;
    if (_disableAnimations) {
      _ticker?.stop();
    } else if (!_isInteracting) {
      _ticker?.start();
    }
    notifyListeners();
  }

  Ticker? _ticker;
  AnimationController? _flyToController;
  Animation<double>? _lonAnim;
  Animation<double>? _latAnim;

  // Angles in radians
  double _lonRotation = -0.5;
  double get lonRotation => _flyToController?.isAnimating == true
      ? (_lonAnim?.value ?? _lonRotation)
      : _lonRotation;

  double _latTilt = 0.288;
  double get latTilt => _flyToController?.isAnimating == true
      ? (_latAnim?.value ?? _latTilt)
      : _latTilt;

  double _zoomScale = 1.0;
  double get zoomScale => _zoomScale;

  // Touch & Inertia
  Offset? _lastPanPos;
  Offset _panVelocity = Offset.zero;
  bool _isInteracting = false;
  bool get isInteracting => _isInteracting;
  Timer? _resumeIdleTimer;
  Duration _lastTickTime = Duration.zero;

  // Parallax star shift offset (reacts subtly to drag)
  Offset _starParallax = Offset.zero;
  Offset get starParallax => _starParallax;

  void handlePanStart(Offset position) {
    _isInteracting = true;
    _resumeIdleTimer?.cancel();
    _flyToController?.stop();
    _lastPanPos = position;
    _panVelocity = Offset.zero;
    notifyListeners();
  }

  void handlePanUpdate(Offset position, Size viewSize) {
    if (_lastPanPos == null) {
      _lastPanPos = position;
      return;
    }

    final delta = position - _lastPanPos!;
    _lastPanPos = position;

    // Arcball sensitivity scaling based on view size and current zoom
    final sensitivity = 2.4 / (viewSize.height * _zoomScale);
    _lonRotation += delta.dx * sensitivity;
    _latTilt = (_latTilt - delta.dy * sensitivity).clamp(-1.25, 1.25);

    // Parallax stars react subtly to drag
    _starParallax += Offset(delta.dx * 0.08, delta.dy * 0.08);

    // Velocity for release inertia
    _panVelocity = Offset(
      delta.dx * sensitivity * 40.0,
      -delta.dy * sensitivity * 40.0,
    );
    notifyListeners();
  }

  void handlePanEnd() {
    _scheduleIdleResume();
  }

  void handlePinchZoom(double scaleDelta) {
    _zoomScale = (_zoomScale * scaleDelta).clamp(0.85, 1.80);
    notifyListeners();
  }

  void resetToHome({double homeLonDeg = 72.8777, double homeLatDeg = 19.0760}) {
    flyToCoordinates(homeLatDeg, homeLonDeg);
  }

  void flyToCoordinates(double latitudeDeg, double longitudeDeg) {
    _resumeIdleTimer?.cancel();
    _isInteracting = true;

    // Target angles to center latitude and longitude facing the user
    final targetLon = -(longitudeDeg * math.pi / 180.0) + math.pi / 2.0;
    final targetLat = latitudeDeg * math.pi / 180.0;

    // Shortest rotational path around circle
    var diffLon = (targetLon - _lonRotation) % (2.0 * math.pi);
    if (diffLon > math.pi) diffLon -= 2.0 * math.pi;
    if (diffLon < -math.pi) diffLon += 2.0 * math.pi;

    if (_disableAnimations || _flyToController == null) {
      _lonRotation += diffLon;
      _latTilt = targetLat.clamp(-1.1, 1.1);
      _isInteracting = false;
      notifyListeners();
      return;
    }

    final startLon = _lonRotation;
    final endLon = _lonRotation + diffLon;
    final startLat = _latTilt;
    final endLat = targetLat.clamp(-1.1, 1.1);

    _flyToController!.reset();
    final curve = CurvedAnimation(
      parent: _flyToController!,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _lonAnim = Tween<double>(begin: startLon, end: endLon).animate(curve);
    _latAnim = Tween<double>(begin: startLat, end: endLat).animate(curve);

    _flyToController!.forward().then((_) {
      _lonRotation = endLon % (2.0 * math.pi);
      _latTilt = endLat;
      _scheduleIdleResume();
    });
  }

  void _scheduleIdleResume() {
    _resumeIdleTimer?.cancel();
    _resumeIdleTimer = Timer(const Duration(seconds: 3), () {
      _isInteracting = false;
      notifyListeners();
    });
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    var changed = false;

    // Inertia decay
    if (!_isInteracting && _panVelocity != Offset.zero) {
      _lonRotation += _panVelocity.dx * dt;
      _latTilt = (_latTilt + _panVelocity.dy * dt).clamp(-1.25, 1.25);
      _panVelocity *= 0.92;
      if (_panVelocity.distance < 0.005) {
        _panVelocity = Offset.zero;
      }
      changed = true;
    }

    // Idle auto-rotation
    if (!_isInteracting &&
        _panVelocity == Offset.zero &&
        !(_flyToController?.isAnimating ?? false) &&
        !_disableAnimations) {
      _lonRotation =
          (_lonRotation + _config.rotationSpeedRadPerSec * dt) %
          (2.0 * math.pi);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _resumeIdleTimer?.cancel();
    _flyToController?.dispose();
    super.dispose();
  }
}
