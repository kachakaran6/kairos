import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/surface_card.dart';

enum GlobeStyle { dottedAtlas, realisticEarth }

class GlobeCity {
  const GlobeCity({
    required this.name,
    required this.utcOffsetMinutes,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final int utcOffsetMinutes;
  final double latitude;
  final double longitude;
}

const GlobeCity kHomeCity = GlobeCity(
  name: 'Mumbai',
  utcOffsetMinutes: 330,
  latitude: 19.0760,
  longitude: 72.8777,
);

/// Professional 3D Rotating Globe with GLSL fragment shader ray-casting,
/// real solar terminator astronomy, inertia gestures, city pins & arcs,
/// and graceful CustomPainter fallback.
class WorldClockGlobe3DWidget extends StatefulWidget {
  const WorldClockGlobe3DWidget({
    super.key,
    required this.nowUtc,
    required this.selectedOffsetMinutes,
    this.selectedCity,
    this.onCitySelected,
    this.globeStyle = GlobeStyle.dottedAtlas,
    this.onGlobeStyleChanged,
  });

  final DateTime nowUtc;
  final int selectedOffsetMinutes;
  final GlobeCity? selectedCity;
  final ValueChanged<GlobeCity>? onCitySelected;
  final GlobeStyle globeStyle;
  final ValueChanged<GlobeStyle>? onGlobeStyleChanged;

  @override
  State<WorldClockGlobe3DWidget> createState() =>
      WorldClockGlobe3DWidgetState();
}

class WorldClockGlobe3DWidgetState extends State<WorldClockGlobe3DWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // 3D rotation angles in radians
  double _lonRotation = -0.5; // Longitude rotation
  double _latTilt = 0.25; // Axial tilt / latitude
  double _zoomScale = 1.0;

  // Interaction & Inertia
  Offset? _lastPanPos;
  Offset _panVelocity = Offset.zero;
  bool _isInteracting = false;
  Timer? _resumeIdleTimer;

  // Spin-to-city animation
  AnimationController? _animController;
  Animation<double>? _lonAnim;
  Animation<double>? _latAnim;

  // GLSL Shader & Textures
  ui.FragmentShader? _shader;
  ui.Image? _landMaskImage;
  ui.Image? _dayImage;
  ui.Image? _nightImage;
  bool _shaderFailed = false;

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShaderAndTextures();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _ticker = createTicker(_onTick);
    if (!_isTest) {
      _ticker.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final disableMotion = mounted
          ? (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          : false;
      if (!_isTest && !_ticker.isTicking && !disableMotion) {
        _ticker.start();
      }
    } else {
      if (_ticker.isTicking) {
        _ticker.stop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableMotion && _ticker.isTicking) {
      _ticker.stop();
    }
  }

  Future<void> _loadShaderAndTextures() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/globe3d.frag',
      );
      final maskData = await rootBundle.load(
        'assets/globe/earth_land_mask.png',
      );
      final dayData = await rootBundle.load('assets/globe/earth_day.webp');
      final nightData = await rootBundle.load('assets/globe/earth_night.webp');

      final maskCodec = await ui.instantiateImageCodec(
        maskData.buffer.asUint8List(),
      );
      final dayCodec = await ui.instantiateImageCodec(
        dayData.buffer.asUint8List(),
      );
      final nightCodec = await ui.instantiateImageCodec(
        nightData.buffer.asUint8List(),
      );

      final maskFrame = await maskCodec.getNextFrame();
      final dayFrame = await dayCodec.getNextFrame();
      final nightFrame = await nightCodec.getNextFrame();

      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
          _landMaskImage = maskFrame.image;
          _dayImage = dayFrame.image;
          _nightImage = nightFrame.image;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _shaderFailed = true);
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    final disableMotion = MediaQuery.of(context).disableAnimations;

    // Apply pan inertia decay if not actively touching
    if (!_isInteracting && _panVelocity != Offset.zero) {
      setState(() {
        _lonRotation += _panVelocity.dx * dt;
        _latTilt = (_latTilt + _panVelocity.dy * dt).clamp(-1.2, 1.2);
        _panVelocity *= 0.92;
        if (_panVelocity.distance < 0.01) {
          _panVelocity = Offset.zero;
        }
      });
    }

    // Idle auto-rotation (1 rev per 60s -> ~0.1047 rad/s)
    if (!_isInteracting &&
        _panVelocity == Offset.zero &&
        !(_animController?.isAnimating ?? false) &&
        !disableMotion) {
      setState(() {
        _lonRotation = (_lonRotation + 0.08 * dt) % (2 * math.pi);
      });
    }
  }

  @override
  void didUpdateWidget(WorldClockGlobe3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCity != null &&
        widget.selectedCity != oldWidget.selectedCity) {
      spinToCity(widget.selectedCity!);
    }
  }

  /// Smoothly spin the 3D globe to center a specified city.
  void spinToCity(GlobeCity city) {
    _resumeIdleTimer?.cancel();
    _isInteracting = true;

    // Target angles to bring the city to the front center:
    final targetLon = -(city.longitude * math.pi / 180.0) + math.pi / 2;
    final targetLat = (city.latitude * math.pi / 180.0);

    // Shortest rotational path
    var diffLon = (targetLon - _lonRotation) % (2 * math.pi);
    if (diffLon > math.pi) diffLon -= 2 * math.pi;
    if (diffLon < -math.pi) diffLon += 2 * math.pi;

    final startLon = _lonRotation;
    final endLon = _lonRotation + diffLon;
    final startLat = _latTilt;
    final endLat = targetLat.clamp(-0.8, 0.8);

    _animController?.reset();
    final curve = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _lonAnim = Tween<double>(begin: startLon, end: endLon).animate(curve);
    _latAnim = Tween<double>(begin: startLat, end: endLat).animate(curve);

    _animController?.forward().then((_) {
      _scheduleIdleResume();
    });
  }

  void _scheduleIdleResume() {
    _resumeIdleTimer?.cancel();
    _resumeIdleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isInteracting = false);
    });
  }

  Future<void> captureSnapshotForWidget() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        // Save to widget data
        await HomeWidget.saveWidgetData<String>(
          'world_clock_globe_ready',
          'true',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _resumeIdleTimer?.cancel();
    _animController?.dispose();
    _shader?.dispose();
    _landMaskImage?.dispose();
    _dayImage?.dispose();
    _nightImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    // Astronomy calculation for sub-solar point
    final totalOffsetMinutes = widget.selectedOffsetMinutes;
    final sunDir = _computeSubSolarVector(widget.nowUtc, totalOffsetMinutes);

    final currentLon = _animController?.isAnimating == true
        ? (_lonAnim?.value ?? _lonRotation)
        : _lonRotation;
    final currentLat = _animController?.isAnimating == true
        ? (_latAnim?.value ?? _latTilt)
        : _latTilt;

    return SurfaceCard(
      height: 190,
      padding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Gesture detection & Globe canvas
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) {
                _isInteracting = true;
                _resumeIdleTimer?.cancel();
                _animController?.stop();
                _lastPanPos = details.focalPoint;
                _panVelocity = Offset.zero;
              },
              onScaleUpdate: (details) {
                if (details.scale != 1.0) {
                  setState(() {
                    _zoomScale = (_zoomScale * details.scale).clamp(0.85, 1.45);
                  });
                }
                if (_lastPanPos != null) {
                  final delta = details.focalPoint - _lastPanPos!;
                  _lastPanPos = details.focalPoint;
                  setState(() {
                    _lonRotation += delta.dx * 0.007;
                    _latTilt = (_latTilt - delta.dy * 0.007).clamp(-1.2, 1.2);
                    _panVelocity = Offset(delta.dx * 0.4, -delta.dy * 0.4);
                  });
                }
              },
              onScaleEnd: (details) {
                _scheduleIdleResume();
              },
              onDoubleTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _lonRotation = -0.5;
                  _latTilt = 0.25;
                  _zoomScale = 1.0;
                  _panVelocity = Offset.zero;
                });
              },
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: CustomPaint(
                  painter: _Globe3DPainter(
                    shader: _shader,
                    landMask: _landMaskImage,
                    dayMap: _dayImage,
                    nightMap: _nightImage,
                    useShader: _shader != null && !_shaderFailed,
                    style: widget.globeStyle,
                    lonRotation: currentLon,
                    latTilt: currentLat,
                    zoomScale: _zoomScale,
                    sunSphere: sunDir,
                    accentColor: colours.accent,
                    sphereBgColor: colours.background,
                    selectedCity: widget.selectedCity,
                    homeCity: kHomeCity,
                  ),
                ),
              ),
            ),
          ),

          // 2. Style toggle chip & Solar terminator indicator
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Style Toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final nextStyle =
                        widget.globeStyle == GlobeStyle.dottedAtlas
                        ? GlobeStyle.realisticEarth
                        : GlobeStyle.dottedAtlas;
                    widget.onGlobeStyleChanged?.call(nextStyle);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colours.surfaceElevated.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(color: colours.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.globeStyle == GlobeStyle.dottedAtlas
                              ? LucideIcons.disc
                              : LucideIcons.globe,
                          size: 13,
                          color: colours.accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.globeStyle == GlobeStyle.dottedAtlas
                              ? 'Dotted Atlas'
                              : 'Realistic Earth',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colours.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Solar Terminator Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colours.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sun, size: 13, color: colours.accent),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.selectedOffsetMinutes >= 0 ? "+" : ""}${(widget.selectedOffsetMinutes / 60).toStringAsFixed(1)}h Sun',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colours.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom overlay: hint & selected city badge
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drag to rotate • Pinch to zoom',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colours.textTertiary,
                  ),
                ),
                if (widget.selectedCity != null)
                  Text(
                    '${widget.selectedCity!.name} focused',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colours.accent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Astronomy calculation: computes sub-solar latitude & longitude in unit sphere vector.
  math.Point<double> _computeSubSolarPoint(DateTime utc, int offsetMinutes) {
    final adjusted = utc.add(Duration(minutes: offsetMinutes));
    final dayOfYear = adjusted
        .difference(DateTime.utc(adjusted.year, 1, 1))
        .inDays;

    // Solar declination (approximate equation: -23.44° * cos(360°/365 * (N + 10)))
    final declinationRad =
        -23.44 *
        math.cos((2.0 * math.pi / 365.25) * (dayOfYear + 10)) *
        (math.pi / 180.0);

    // Subsolar longitude from UTC fractional hour
    final fracDay =
        (adjusted.hour + adjusted.minute / 60.0 + adjusted.second / 3600.0) /
        24.0;
    final subsolarLonRad = -(fracDay * 2.0 * math.pi - math.pi);

    return math.Point(subsolarLonRad, declinationRad);
  }

  List<double> _computeSubSolarVector(DateTime utc, int offsetMinutes) {
    final pt = _computeSubSolarPoint(utc, offsetMinutes);
    final lon = pt.x;
    final lat = pt.y;

    final x = math.cos(lat) * math.cos(lon);
    final y = math.sin(lat);
    final z = math.cos(lat) * math.sin(lon);
    return [x, y, z];
  }
}

class _Globe3DPainter extends CustomPainter {
  const _Globe3DPainter({
    required this.shader,
    required this.landMask,
    required this.dayMap,
    required this.nightMap,
    required this.useShader,
    required this.style,
    required this.lonRotation,
    required this.latTilt,
    required this.zoomScale,
    required this.sunSphere,
    required this.accentColor,
    required this.sphereBgColor,
    required this.selectedCity,
    required this.homeCity,
  });

  final ui.FragmentShader? shader;
  final ui.Image? landMask;
  final ui.Image? dayMap;
  final ui.Image? nightMap;
  final bool useShader;
  final GlobeStyle style;
  final double lonRotation;
  final double latTilt;
  final double zoomScale;
  final List<double> sunSphere;
  final Color accentColor;
  final Color sphereBgColor;
  final GlobeCity? selectedCity;
  final GlobeCity homeCity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.40 * zoomScale;

    // 1. Draw 3D Globe surface (GLSL Shader or fallback)
    if (useShader && shader != null) {
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      shader!.setFloat(2, lonRotation);
      shader!.setFloat(3, latTilt);
      shader!.setFloat(4, sunSphere[0]);
      shader!.setFloat(5, sunSphere[1]);
      shader!.setFloat(6, sunSphere[2]);
      shader!.setFloat(7, accentColor.r);
      shader!.setFloat(8, accentColor.g);
      shader!.setFloat(9, accentColor.b);
      shader!.setFloat(10, accentColor.a);
      shader!.setFloat(11, sphereBgColor.r);
      shader!.setFloat(12, sphereBgColor.g);
      shader!.setFloat(13, sphereBgColor.b);
      shader!.setFloat(14, 1.0);
      shader!.setFloat(15, style == GlobeStyle.dottedAtlas ? 0.0 : 1.0);
      shader!.setFloat(16, radius);

      if (style == GlobeStyle.dottedAtlas && landMask != null) {
        shader!.setImageSampler(0, landMask!);
        if (nightMap != null) shader!.setImageSampler(1, nightMap!);
      } else if (dayMap != null && nightMap != null) {
        shader!.setImageSampler(0, dayMap!);
        shader!.setImageSampler(1, nightMap!);
      }

      final paint = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      _drawVectorFallbackGlobe(canvas, center, radius);
    }

    // 2. Great-circle arc between Home city and Selected city
    if (selectedCity != null && selectedCity!.name != homeCity.name) {
      _drawGreatCircleArc(canvas, center, radius, homeCity, selectedCity!);
    }

    // 3. Project & draw city pins on the 3D surface
    _drawCityPin(canvas, center, radius, homeCity, isHome: true);
    if (selectedCity != null) {
      _drawCityPin(canvas, center, radius, selectedCity!, isSelected: true);
    }
  }

  void _drawVectorFallbackGlobe(Canvas canvas, Offset center, double radius) {
    // Atmosphere outer halo
    final auraPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 1.15,
        [
          accentColor.withValues(alpha: 0.25),
          accentColor.withValues(alpha: 0.0),
        ],
        [0.85, 1.0],
      );
    canvas.drawCircle(center, radius * 1.15, auraPaint);

    // Sphere base
    final spherePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        radius * 1.3,
        [sphereBgColor, const Color(0xFF070605)],
      );
    canvas.drawCircle(center, radius, spherePaint);

    // Parallels & Meridians
    final gridPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double lat = -60; lat <= 60; lat += 30) {
      final y = center.dy - math.sin(lat * math.pi / 180) * radius;
      final rLat = math.cos(lat * math.pi / 180) * radius;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, y),
          width: rLat * 2,
          height: rLat * 0.4,
        ),
        gridPaint,
      );
    }

    // Atmospheric rim
    final rimPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, rimPaint);
  }

  void _drawCityPin(
    Canvas canvas,
    Offset center,
    double radius,
    GlobeCity city, {
    bool isHome = false,
    bool isSelected = false,
  }) {
    final pos3d = _projectLatLonTo3D(city.latitude, city.longitude);
    final rotated = _rotate3D(pos3d, lonRotation, latTilt);

    // Only draw if on the visible front hemisphere (z > 0)
    if (rotated[2] <= 0.05) return;

    final screenX = center.dx + rotated[0] * radius;
    final screenY = center.dy - rotated[1] * radius;
    final pinPos = Offset(screenX, screenY);

    final depthAlpha = rotated[2].clamp(0.2, 1.0);

    // Pulsing outer glow
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35 * depthAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinPos, (isSelected ? 9.0 : 6.0), glowPaint);

    // Pin core dot
    final corePaint = Paint()
      ..color = (isHome ? const Color(0xFFFAF7F2) : accentColor).withValues(
        alpha: depthAlpha,
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinPos, (isSelected ? 4.5 : 3.0), corePaint);

    // Selected city chip badge
    if (isSelected) {
      final textSpan = TextSpan(
        text: city.name,
        style: TextStyle(
          color: const Color(0xFFF4EFE8).withValues(alpha: depthAlpha),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = Rect.fromLTWH(
        pinPos.dx - textPainter.width / 2 - 6,
        pinPos.dy - 22,
        textPainter.width + 12,
        18,
      );
      final badgePaint = Paint()
        ..color = const Color(0xFF0F0D0B).withValues(alpha: 0.85 * depthAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(9)),
        badgePaint,
      );

      final borderPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.6 * depthAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(9)),
        borderPaint,
      );

      textPainter.paint(canvas, Offset(badgeRect.left + 6, badgeRect.top + 2));
    }
  }

  void _drawGreatCircleArc(
    Canvas canvas,
    Offset center,
    double radius,
    GlobeCity from,
    GlobeCity to,
  ) {
    final p1 = _projectLatLonTo3D(from.latitude, from.longitude);
    final p2 = _projectLatLonTo3D(to.latitude, to.longitude);

    final path = Path();
    var isPathStarted = false;

    const segments = 30;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      // Spherical interpolation
      final interpolated = _slerp(p1, p2, t);
      final rot = _rotate3D(interpolated, lonRotation, latTilt);

      if (rot[2] > 0.02) {
        final sx = center.dx + rot[0] * radius;
        final sy = center.dy - rot[1] * radius;
        if (!isPathStarted) {
          path.moveTo(sx, sy);
          isPathStarted = true;
        } else {
          path.lineTo(sx, sy);
        }
      } else {
        isPathStarted = false;
      }
    }

    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, arcPaint);
  }

  List<double> _projectLatLonTo3D(double latDeg, double lonDeg) {
    final lat = latDeg * math.pi / 180.0;
    final lon = lonDeg * math.pi / 180.0;
    return [
      math.cos(lat) * math.cos(lon),
      math.sin(lat),
      math.cos(lat) * math.sin(lon),
    ];
  }

  List<double> _rotate3D(List<double> p, double lonAngle, double latAngle) {
    // Y-axis rotation (longitude)
    final cy = math.cos(lonAngle);
    final sy = math.sin(lonAngle);
    final x1 = cy * p[0] + sy * p[2];
    final y1 = p[1];
    final z1 = -sy * p[0] + cy * p[2];

    // X-axis tilt (latitude)
    final cx = math.cos(latAngle);
    final sx = math.sin(latAngle);
    final x2 = x1;
    final y2 = cx * y1 - sx * z1;
    final z2 = sx * y1 + cx * z1;

    return [x2, y2, z2];
  }

  List<double> _slerp(List<double> v0, List<double> v1, double t) {
    var dot = v0[0] * v1[0] + v0[1] * v1[1] + v0[2] * v1[2];
    dot = dot.clamp(-1.0, 1.0);
    final theta0 = math.acos(dot);
    final sinTheta0 = math.sin(theta0);

    if (sinTheta0.abs() < 0.001) {
      return [
        v0[0] * (1 - t) + v1[0] * t,
        v0[1] * (1 - t) + v1[1] * t,
        v0[2] * (1 - t) + v1[2] * t,
      ];
    }

    final s0 = math.sin((1.0 - t) * theta0) / sinTheta0;
    final s1 = math.sin(t * theta0) / sinTheta0;
    return [
      v0[0] * s0 + v1[0] * s1,
      v0[1] * s0 + v1[1] * s1,
      v0[2] * s0 + v1[2] * s1,
    ];
  }

  @override
  bool shouldRepaint(covariant _Globe3DPainter oldDelegate) {
    return oldDelegate.lonRotation != lonRotation ||
        oldDelegate.latTilt != latTilt ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.sunSphere != sunSphere ||
        oldDelegate.style != style ||
        oldDelegate.selectedCity != selectedCity;
  }
}
