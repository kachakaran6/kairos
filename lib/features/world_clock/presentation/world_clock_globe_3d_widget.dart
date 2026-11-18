import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design/globe_tokens.dart';
import '../../../core/design/radius_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/globe_astronomy.dart';
import '../domain/globe_city_data.dart';
import '../domain/globe_config.dart';
import 'globe_controller.dart';
import 'globe_painter_fallback.dart';

typedef GlobeStyle = GlobeStyleType;

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

const GlobeCity kDefaultHomeCity = GlobeCity(
  name: 'Mumbai',
  utcOffsetMinutes: 330,
  latitude: 19.0760,
  longitude: 72.8777,
);

/// Luxury 3D Earth Globe ("Obsidian & Ember") featuring:
/// - Real-time GLSL ray-sphere fragment shader with Impeller support
/// - Spherical Fibonacci land points with zero moiré & correct foreshortening
/// - Accurate solar terminator twilight astronomy & sparkling night city lights
/// - Soft Fresnel atmosphere rim & star field with drag parallax
/// - Card height 340dp with 74% globe scale, never overlapping UI chrome
/// - Segmented style switcher (Atlas / Earth / Ink)
/// - Great-circle flight arcs & glowing ember city pins
/// - High-performance batched CustomPainter fallback
class WorldClockGlobe3DWidget extends StatefulWidget {
  const WorldClockGlobe3DWidget({
    super.key,
    required this.nowUtc,
    required this.selectedOffsetMinutes,
    this.selectedCity,
    this.onCitySelected,
    this.globeStyle = GlobeStyleType.atlas,
    this.onGlobeStyleChanged,
    this.onResetOffset,
    this.config = const GlobeConfig(),
  });

  final DateTime nowUtc;
  final int selectedOffsetMinutes;
  final GlobeCity? selectedCity;
  final ValueChanged<GlobeCity>? onCitySelected;
  final GlobeStyleType globeStyle;
  final ValueChanged<GlobeStyleType>? onGlobeStyleChanged;
  final VoidCallback? onResetOffset;
  final GlobeConfig config;

  @override
  State<WorldClockGlobe3DWidget> createState() =>
      WorldClockGlobe3DWidgetState();

  /// Static snapshot renderer to export globe artwork for home screen widgets.
  static Future<Uint8List?> renderGlobeSnapshot({
    required DateTime nowUtc,
    int offsetMinutes = 0,
    GlobeCity? selectedCity,
    GlobeStyleType style = GlobeStyleType.atlas,
    double size = 400,
    bool isDark = true,
    Color accentColor = GlobeTokens.defaultAccentTerracotta,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
      final sunSphere = GlobeAstronomy.computeSubSolarVector(
        nowUtc,
        offsetMinutes,
      );

      final painter = GlobePainterFallback(
        lonRotation: -0.5,
        latTilt: 0.288,
        zoomScale: 1.0,
        sunSphere: sunSphere,
        accentColor: accentColor,
        isDark: isDark,
        style: style,
        timeSec: 0,
        starParallax: Offset.zero,
        selectedCity: selectedCity != null
            ? GlobeCityPoint(
                name: selectedCity.name,
                latitude: selectedCity.latitude,
                longitude: selectedCity.longitude,
                utcOffsetMinutes: selectedCity.utcOffsetMinutes,
              )
            : null,
      );

      painter.paint(canvas, Size(size, size));
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

class WorldClockGlobe3DWidgetState extends State<WorldClockGlobe3DWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late GlobeController _controller;
  double _elapsedTime = 0.0;
  bool _hasInteracted = false;
  static const String _hintSeenKey = 'kairos_globe_hint_seen';

  // GLSL Shader & Textures
  ui.FragmentShader? _shader;
  ui.Image? _landMaskImage;
  ui.Image? _dayImage;
  ui.Image? _nightImage;
  bool _shaderFailed = false;

  // FPS Debug Overlay
  int _frameCount = 0;
  double _fps = 60.0;
  DateTime _fpsLastTime = DateTime.now();

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = GlobeController(
      vsync: this,
      config: widget.config,
      disableAnimations: _isTest,
    );
    _controller.addListener(_onControllerUpdate);

    _checkHintSeen();
    _loadShaderAndTextures();
  }

  Future<void> _checkHintSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_hintSeenKey) == true && mounted) {
        setState(() => _hasInteracted = true);
      }
    } catch (_) {}
  }

  void _markHintSeen() {
    if (_hasInteracted) return;
    setState(() => _hasInteracted = true);
    SharedPreferences.getInstance().then((p) => p.setBool(_hintSeenKey, true));
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || _isTest;
    _controller.disableAnimations = disableMotion;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final disableMotion =
          (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || _isTest;
      _controller.disableAnimations = disableMotion;
    } else {
      _controller.disableAnimations = true;
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
      if (mounted) setState(() => _shaderFailed = true);
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

  void spinToCity(GlobeCity city) {
    _markHintSeen();
    HapticFeedback.selectionClick();
    _controller.flyToCoordinates(city.latitude, city.longitude);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
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
    final isDark = colours.isDark;

    // Calculate sub-solar lighting vector
    final sunVector = GlobeAstronomy.computeSubSolarVector(
      widget.nowUtc,
      widget.selectedOffsetMinutes,
    );

    // Track FPS in debug mode
    if (kDebugMode) {
      _frameCount++;
      final now = DateTime.now();
      final diff = now.difference(_fpsLastTime).inMilliseconds;
      if (diff >= 1000) {
        _fps = (_frameCount * 1000.0) / diff;
        _frameCount = 0;
        _fpsLastTime = now;
      }
    }

    _elapsedTime += 0.016;

    final selectedCityPoint = widget.selectedCity != null
        ? GlobeCityPoint(
            name: widget.selectedCity!.name,
            latitude: widget.selectedCity!.latitude,
            longitude: widget.selectedCity!.longitude,
            utcOffsetMinutes: widget.selectedCity!.utcOffsetMinutes,
          )
        : null;

    final cardHeight = widget.config.cardHeight; // 340.0 dp

    return Semantics(
      label:
          'Interactive 3D Earth Globe showing solar terminator and planetary time. '
          'Selected city: ${widget.selectedCity?.name ?? "None"}. Drag with one finger to rotate, pinch to zoom.',
      child: SurfaceCard(
        height: cardHeight,
        padding: EdgeInsets.zero,
        borderRadius: RadiusTokens.cardRadius, // 28dp squircle
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Internal radial vignette for lit-from-within depth
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.05),
                    radius: 0.85,
                    colors: [
                      colours.accent.withValues(alpha: isDark ? 0.07 : 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 1. Gesture Listener & Globe Canvas
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _markHintSeen();
                  _controller.handlePanStart(details.focalPoint);
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    _controller.handlePinchZoom(details.scale);
                  }
                  _controller.handlePanUpdate(
                    details.focalPoint,
                    Size(MediaQuery.of(context).size.width, cardHeight),
                  );
                },
                onScaleEnd: (details) {
                  _controller.handlePanEnd();
                },
                onDoubleTap: () {
                  HapticFeedback.mediumImpact();
                  _controller.resetToHome();
                },
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: CustomPaint(
                    painter: _GlobeRenderDelegator(
                      shader: _shader,
                      landMask: _landMaskImage,
                      dayMap: _dayImage,
                      nightMap: _nightImage,
                      useShader: _shader != null && !_shaderFailed && !_isTest,
                      style: widget.globeStyle,
                      lonRotation: _controller.lonRotation,
                      latTilt: _controller.latTilt,
                      zoomScale: _controller.zoomScale,
                      sunSphere: sunVector,
                      accentColor: colours.accent,
                      sphereBgColor: colours.background,
                      isDark: isDark,
                      timeSec: _elapsedTime,
                      starParallax: _controller.starParallax,
                      selectedCity: selectedCityPoint,
                      cardHeight: cardHeight,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Top Bar: Segmented Style Switcher (Atlas / Earth / Ink) + Sun Offset Pill
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Segmented Style Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colours.surfaceElevated.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(color: colours.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStyleSegment(
                          'Atlas',
                          GlobeStyleType.atlas,
                          LucideIcons.disc,
                          colours,
                        ),
                        _buildStyleSegment(
                          'Earth',
                          GlobeStyleType.earth,
                          LucideIcons.globe,
                          colours,
                        ),
                        _buildStyleSegment(
                          'Ink',
                          GlobeStyleType.ink,
                          LucideIcons.feather,
                          colours,
                        ),
                      ],
                    ),
                  ),

                  // Sun Offset Interactive Pill
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onResetOffset?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colours.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                        border: Border.all(
                          color: colours.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sun,
                            size: 12,
                            color: colours.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.selectedOffsetMinutes >= 0 ? "+" : ""}${(widget.selectedOffsetMinutes / 60).toStringAsFixed(1)}h Sun',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colours.accent,
                            ),
                          ),
                          if (widget.selectedOffsetMinutes != 0) ...[
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.rotateCcw,
                              size: 10,
                              color: colours.accent,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom Bar: Drag hint (fades after first drag) & Selected City info chip
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Fading "Drag to rotate" hint pill
                  AnimatedOpacity(
                    opacity: _hasInteracted ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colours.surfaceElevated.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                        border: Border.all(color: colours.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.move,
                            size: 11,
                            color: colours.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Drag to rotate',
                            style: TextStyle(
                              fontSize: 10,
                              color: colours.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected City Glass Pill
                  if (widget.selectedCity != null)
                    _buildSelectedCityPill(
                      widget.selectedCity!,
                      colours,
                      isDark,
                    ),

                  // Debug FPS counter
                  if (kDebugMode)
                    Text(
                      '${_fps.toStringAsFixed(0)} FPS',
                      style: TextStyle(
                        fontSize: 9,
                        color: colours.textTertiary.withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSegment(
    String label,
    GlobeStyleType style,
    IconData icon,
    dynamic colours,
  ) {
    final isSelected = widget.globeStyle == style;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onGlobeStyleChanged?.call(style);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colours.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusTokens.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? colours.onAccent : colours.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colours.onAccent : colours.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCityPill(GlobeCity city, dynamic colours, bool isDark) {
    final cityTime = widget.nowUtc.add(
      Duration(minutes: widget.selectedOffsetMinutes + city.utcOffsetMinutes),
    );
    final hour = cityTime.hour.toString().padLeft(2, '0');
    final minute = cityTime.minute.toString().padLeft(2, '0');
    final isDay = cityTime.hour >= 6 && cityTime.hour < 18;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colours.surfaceElevated.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: colours.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDay ? LucideIcons.sun : LucideIcons.moon,
            size: 12,
            color: colours.accent,
          ),
          const SizedBox(width: 6),
          Text(
            city.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colours.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$hour:$minute',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: colours.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dispatches rendering between the GLSL fragment shader and the CustomPainter fallback.
class _GlobeRenderDelegator extends CustomPainter {
  const _GlobeRenderDelegator({
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
    required this.isDark,
    required this.timeSec,
    required this.starParallax,
    required this.selectedCity,
    required this.cardHeight,
  });

  final ui.FragmentShader? shader;
  final ui.Image? landMask;
  final ui.Image? dayMap;
  final ui.Image? nightMap;
  final bool useShader;
  final GlobeStyleType style;
  final double lonRotation;
  final double latTilt;
  final double zoomScale;
  final List<double> sunSphere;
  final Color accentColor;
  final Color sphereBgColor;
  final bool isDark;
  final double timeSec;
  final Offset starParallax;
  final GlobeCityPoint? selectedCity;
  final double cardHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0 - 4.0);
    // Globe diameter is ~74% of card height (radius = cardHeight * 0.37)
    final radius = (cardHeight * 0.37) * zoomScale;

    if (useShader && shader != null && landMask != null) {
      // 1. Ray-cast GLSL fragment shader on canvas
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
      shader!.setFloat(
        15,
        style == GlobeStyleType.atlas
            ? 0.0
            : (style == GlobeStyleType.earth ? 1.0 : 2.0),
      );
      shader!.setFloat(16, radius);
      shader!.setFloat(17, timeSec);
      shader!.setFloat(18, starParallax.dx);
      shader!.setFloat(19, starParallax.dy);

      if (style == GlobeStyleType.earth && dayMap != null && nightMap != null) {
        shader!.setImageSampler(0, dayMap!);
        shader!.setImageSampler(1, nightMap!);
      } else {
        shader!.setImageSampler(0, landMask!);
        if (nightMap != null) {
          shader!.setImageSampler(1, nightMap!);
        } else {
          shader!.setImageSampler(1, landMask!);
        }
      }

      final paint = Paint()..shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // 2. Draw great-circle flight arcs and glowing pins over the sphere
      final fallbackPainter = GlobePainterFallback(
        lonRotation: lonRotation,
        latTilt: latTilt,
        zoomScale: zoomScale,
        sunSphere: sunSphere,
        accentColor: accentColor,
        isDark: isDark,
        style: style,
        timeSec: timeSec,
        starParallax: starParallax,
        selectedCity: selectedCity,
      );

      // Render pins and arcs
      if (selectedCity != null) {
        final cosY = math.cos(lonRotation);
        final sinY = math.sin(lonRotation);
        final cosX = math.cos(latTilt);
        final sinX = math.sin(latTilt);

        fallbackPainter.drawGreatCircleArc(
          canvas,
          center,
          radius,
          cosY,
          sinY,
          cosX,
          sinX,
        );
        fallbackPainter.drawCityPin(
          canvas,
          center,
          radius,
          fallbackPainter.homeCity,
          isHome: true,
          cosY: cosY,
          sinY: sinY,
          cosX: cosX,
          sinX: sinX,
        );
        fallbackPainter.drawCityPin(
          canvas,
          center,
          radius,
          selectedCity!,
          isHome: false,
          cosY: cosY,
          sinY: sinY,
          cosX: cosX,
          sinX: sinX,
        );
      }
    } else {
      // Complete CustomPainter fallback
      final fallback = GlobePainterFallback(
        lonRotation: lonRotation,
        latTilt: latTilt,
        zoomScale: zoomScale,
        sunSphere: sunSphere,
        accentColor: accentColor,
        isDark: isDark,
        style: style,
        timeSec: timeSec,
        starParallax: starParallax,
        selectedCity: selectedCity,
      );
      fallback.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobeRenderDelegator oldDelegate) => true;
}
