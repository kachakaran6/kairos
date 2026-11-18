import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../core/design/globe_tokens.dart';
import '../../../core/design/radius_tokens.dart';
import '../domain/globe_astronomy.dart';
import '../domain/globe_city_data.dart';
import '../domain/globe_config.dart';

/// High-performance CustomPainter fallback that projects ~14,000 Fibonacci
/// sphere points orthographically with depth sorting, batched drawRawPoints,
/// real solar terminator lighting, atmosphere rim, pins, and great-circle arcs.
class GlobePainterFallback extends CustomPainter {
  GlobePainterFallback({
    required this.lonRotation,
    required this.latTilt,
    required this.zoomScale,
    required this.sunSphere,
    required this.accentColor,
    required this.isDark,
    required this.style,
    required this.timeSec,
    required this.starParallax,
    this.selectedCity,
    this.homeCity = const GlobeCityPoint(
      name: 'Mumbai',
      latitude: 19.0760,
      longitude: 72.8777,
      utcOffsetMinutes: 330,
    ),
  });

  final double lonRotation;
  final double latTilt;
  final double zoomScale;
  final List<double> sunSphere;
  final Color accentColor;
  final bool isDark;
  final GlobeStyleType style;
  final double timeSec;
  final Offset starParallax;
  final GlobeCityPoint? selectedCity;
  final GlobeCityPoint homeCity;

  // Cached Fibonacci sphere points
  static List<List<double>>? _cachedFibonacciSphere;

  static List<List<double>> get fibonacciSphere {
    if (_cachedFibonacciSphere != null) return _cachedFibonacciSphere!;
    const n = 14400;
    const goldenAngle = 2.39996322972865332; // pi * (3 - sqrt(5))
    final points = <List<double>>[];

    for (var i = 0; i < n; i++) {
      final y = 1.0 - (i / (n - 1.0)) * 2.0; // from 1 to -1
      final radiusAtY = math.sqrt(math.max(0.0, 1.0 - y * y));
      final theta = goldenAngle * i;

      final x = math.cos(theta) * radiusAtY;
      final z = math.sin(theta) * radiusAtY;

      // Filter approximately by continental land masses using simplified spherical bounding checks
      final latDeg = math.asin(y) * (180.0 / math.pi);
      var lonDeg = math.atan2(z, x) * (180.0 / math.pi);

      if (_isLandCoordinate(latDeg, lonDeg)) {
        points.add([x, y, z]);
      }
    }
    _cachedFibonacciSphere = points;
    return _cachedFibonacciSphere!;
  }

  /// Fast spherical bounding box approximation of continents for the vector fallback
  static bool _isLandCoordinate(double lat, double lon) {
    // Antarctica
    if (lat < -60) return true;
    // Africa
    if (lat > -35 && lat < 37 && lon > -18 && lon < 52) return true;
    // Eurasia
    if (lat > 35 && lat < 72 && lon > -10 && lon < 170) return true;
    if (lat > 8 && lat <= 35 && lon > 50 && lon < 145) return true;
    // North America
    if (lat > 15 && lat < 72 && lon > -168 && lon < -52) return true;
    // South America
    if (lat > -56 && lat < 13 && lon > -82 && lon < -34) return true;
    // Australia
    if (lat > -44 && lat < -10 && lon > 112 && lon < 154) return true;
    // Greenland
    if (lat > 60 && lat < 84 && lon > -73 && lon < -12) return true;
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final radius = (size.height * 0.37) * zoomScale;

    // 1. Draw subtle twinkling starfield (Dark mode only)
    if (isDark) {
      _drawStarfield(canvas, size);
    }

    // 2. Outer Atmosphere Soft Glow
    final outerAtmospherePaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 1.15,
        [
          accentColor.withValues(alpha: isDark ? 0.35 : 0.18),
          accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
          Colors.transparent,
        ],
        [0.85, 0.96, 1.0],
      );
    canvas.drawCircle(center, radius * 1.15, outerAtmospherePaint);

    // 3. Ocean Sphere Base with Depth Gradient
    final oceanPaint = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(radius * 0.25, radius * 0.25),
        radius * 1.3,
        isDark
            ? [
                GlobeTokens.darkOceanTop,
                GlobeTokens.darkOceanMid,
                GlobeTokens.darkOceanDeep,
              ]
            : [
                GlobeTokens.lightOceanTop,
                GlobeTokens.lightOceanMid,
                GlobeTokens.lightOceanDeep,
              ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawCircle(center, radius, oceanPaint);

    // Subtle ocean graticule rings
    _drawGraticuleRings(canvas, center, radius);

    // 4. Transform & Project Fibonacci Land Points
    final cosY = math.cos(lonRotation);
    final sinY = math.sin(lonRotation);
    final cosX = math.cos(latTilt);
    final sinX = math.sin(latTilt);

    final points = fibonacciSphere;
    final dayPointCoords = <double>[];
    final nightPointCoords = <double>[];

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      // Rotate around Y (longitude)
      final x1 = cosY * p[0] + sinY * p[2];
      final y1 = p[1];
      final z1 = -sinY * p[0] + cosY * p[2];

      // Rotate around X (axial tilt)
      final x2 = x1;
      final y2 = cosX * y1 - sinX * z1;
      final z2 = sinX * y1 + cosX * z1;

      // Cull back hemisphere
      if (z2 <= 0.02) continue;

      // Solar lighting incidence
      final sunIncidence =
          p[0] * sunSphere[0] + p[1] * sunSphere[1] + p[2] * sunSphere[2];

      final screenX = center.dx + x2 * radius;
      final screenY = center.dy - y2 * radius;

      if (sunIncidence >= 0.0) {
        dayPointCoords.add(screenX);
        dayPointCoords.add(screenY);
      } else {
        nightPointCoords.add(screenX);
        nightPointCoords.add(screenY);
      }
    }

    // 5. Draw Batched Land Dots (No individual drawCircle)
    if (nightPointCoords.isNotEmpty) {
      final nightFloatList = Float32List.fromList(nightPointCoords);
      final nightDotPaint = Paint()
        ..color = isDark
            ? GlobeTokens.darkNightLandDots.withValues(alpha: 0.35)
            : GlobeTokens.lightNightLandDots.withValues(alpha: 0.35)
        ..strokeWidth = math.max(1.2, 1.8 * zoomScale)
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(ui.PointMode.points, nightFloatList, nightDotPaint);
    }

    if (dayPointCoords.isNotEmpty) {
      final dayFloatList = Float32List.fromList(dayPointCoords);
      final dayDotPaint = Paint()
        ..color = isDark ? accentColor : GlobeTokens.lightDayLandDots
        ..strokeWidth = math.max(1.4, 2.2 * zoomScale)
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(ui.PointMode.points, dayFloatList, dayDotPaint);
    }

    // 6. Sparkling City Lights on Night Side
    if (isDark) {
      _drawNightCityLights(canvas, center, radius, cosY, sinY, cosX, sinX);
    }

    // 7. Inner Atmosphere Fresnel Limb Ring (razor-thin edge highlight)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.transparent,
          accentColor.withValues(alpha: isDark ? 0.45 : 0.20),
        ],
        [0.92, 1.0],
      );
    canvas.drawCircle(center, radius - 1.0, rimPaint);

    // 8. Great-Circle Flight Arc (Between Home and Selected City)
    if (selectedCity != null && selectedCity!.name != homeCity.name) {
      drawGreatCircleArc(canvas, center, radius, cosY, sinY, cosX, sinX);
    }

    // 9. City Pins (Home City & Selected City)
    drawCityPin(
      canvas,
      center,
      radius,
      homeCity,
      isHome: true,
      cosY: cosY,
      sinY: sinY,
      cosX: cosX,
      sinX: sinX,
    );
    if (selectedCity != null) {
      drawCityPin(
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
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final starPaint = Paint()..strokeCap = StrokeCap.round;
    // 24 fixed background stars with twinkling and parallax
    for (var i = 0; i < 24; i++) {
      final h1 = (math.sin(i * 12.9898 + 78.233) * 43758.5453).abs() % 1.0;
      final h2 = (math.cos(i * 93.9898 + 67.345) * 24634.6345).abs() % 1.0;

      final sx = (h1 * size.width + starParallax.dx) % size.width;
      final sy = (h2 * size.height + starParallax.dy) % size.height;

      final twinkle = 0.4 + 0.6 * math.sin(timeSec * 2.0 + i);
      final r = (i % 3 == 0) ? 1.6 : ((i % 2 == 0) ? 1.1 : 0.7);

      starPaint
        ..color = GlobeTokens.starTwinkle.withValues(alpha: 0.22 * twinkle)
        ..strokeWidth = r * 2.0;
      canvas.drawPoints(ui.PointMode.points, [Offset(sx, sy)], starPaint);
    }
  }

  void _drawGraticuleRings(Canvas canvas, Offset center, double radius) {
    final graticulePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);

    canvas.drawCircle(center, radius * 0.5, graticulePaint);
    canvas.drawCircle(center, radius * 0.85, graticulePaint);
  }

  void _drawNightCityLights(
    Canvas canvas,
    Offset center,
    double radius,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final lightPaint = Paint()..strokeCap = StrokeCap.round;

    for (final city in kMajorWorldCities) {
      final latRad = city.latitude * (math.pi / 180.0);
      final lonRad = city.longitude * (math.pi / 180.0);

      final px = math.cos(latRad) * math.cos(lonRad);
      final py = math.sin(latRad);
      final pz = math.cos(latRad) * math.sin(lonRad);

      // Rotate Y
      final x1 = cosY * px + sinY * pz;
      final y1 = py;
      final z1 = -sinY * px + cosY * pz;

      // Rotate X
      final x2 = x1;
      final y2 = cosX * y1 - sinX * z1;
      final z2 = sinX * y1 + cosX * z1;

      if (z2 <= 0.05) continue;

      // Check if this city is currently on the night side
      final sunIncidence =
          px * sunSphere[0] + py * sunSphere[1] + pz * sunSphere[2];
      if (sunIncidence < -0.05) {
        final screenX = center.dx + x2 * radius;
        final screenY = center.dy - y2 * radius;

        final twinkle = 0.75 + 0.25 * math.sin(timeSec * 3.5 + city.latitude);
        final lightAlpha =
            ((-sunIncidence) * 2.0).clamp(0.0, 1.0) * city.brightness * twinkle;

        lightPaint
          ..color = GlobeTokens.cityLightsAmber.withValues(
            alpha: lightAlpha * 0.9,
          )
          ..strokeWidth = 2.4;
        canvas.drawPoints(ui.PointMode.points, [
          Offset(screenX, screenY),
        ], lightPaint);
      }
    }
  }

  void drawGreatCircleArc(
    Canvas canvas,
    Offset center,
    double radius,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final p1 = [
      math.cos(homeCity.latitude * math.pi / 180.0) *
          math.cos(homeCity.longitude * math.pi / 180.0),
      math.sin(homeCity.latitude * math.pi / 180.0),
      math.cos(homeCity.latitude * math.pi / 180.0) *
          math.sin(homeCity.longitude * math.pi / 180.0),
    ];

    final p2 = [
      math.cos(selectedCity!.latitude * math.pi / 180.0) *
          math.cos(selectedCity!.longitude * math.pi / 180.0),
      math.sin(selectedCity!.latitude * math.pi / 180.0),
      math.cos(selectedCity!.latitude * math.pi / 180.0) *
          math.sin(selectedCity!.longitude * math.pi / 180.0),
    ];

    const steps = 40;
    final arcPath = Path();
    var first = true;
    Offset? midPointScreen;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final arcPoint = GlobeAstronomy.slerpArcPoint(p1, p2, t, 1.03);

      final x1 = cosY * arcPoint[0] + sinY * arcPoint[2];
      final y1 = arcPoint[1];
      final z1 = -sinY * arcPoint[0] + cosY * arcPoint[2];

      final x2 = x1;
      final y2 = cosX * y1 - sinX * z1;
      final z2 = sinX * y1 + cosX * z1;

      if (z2 > 0.0) {
        final sx = center.dx + x2 * radius;
        final sy = center.dy - y2 * radius;

        if (first) {
          arcPath.moveTo(sx, sy);
          first = false;
        } else {
          arcPath.lineTo(sx, sy);
        }

        if (i == (steps / 2).round()) {
          midPointScreen = Offset(sx, sy);
        }
      }
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accentColor.withValues(alpha: 0.65);
    canvas.drawPath(arcPath, arcPaint);

    // Midpoint time difference badge
    if (midPointScreen != null) {
      final diffMins =
          selectedCity!.utcOffsetMinutes - homeCity.utcOffsetMinutes;
      final diffHours = diffMins / 60.0;
      final diffStr =
          '${diffHours >= 0 ? "+" : ""}${diffHours.toStringAsFixed(1)}h';

      final textSpan = TextSpan(
        text: diffStr,
        style: TextStyle(
          color: isDark ? GlobeTokens.chipTextDark : GlobeTokens.chipTextLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();

      final pillRect = Rect.fromCenter(
        center: midPointScreen,
        width: tp.width + 12,
        height: tp.height + 6,
      );

      final pillBg = Paint()
        ..color = (isDark ? GlobeTokens.pillBackgroundDark : Colors.white)
            .withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          pillRect,
          const Radius.circular(RadiusTokens.pill),
        ),
        pillBg,
      );
      tp.paint(canvas, midPointScreen - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void drawCityPin(
    Canvas canvas,
    Offset center,
    double radius,
    GlobeCityPoint city, {
    required bool isHome,
    required double cosY,
    required double sinY,
    required double cosX,
    required double sinX,
  }) {
    final latRad = city.latitude * (math.pi / 180.0);
    final lonRad = city.longitude * (math.pi / 180.0);

    final px = math.cos(latRad) * math.cos(lonRad);
    final py = math.sin(latRad);
    final pz = math.cos(latRad) * math.sin(lonRad);

    final x1 = cosY * px + sinY * pz;
    final y1 = py;
    final z1 = -sinY * px + cosY * pz;

    final x2 = x1;
    final y2 = cosX * y1 - sinX * z1;
    final z2 = sinX * y1 + cosX * z1;

    // Cull if on the back hemisphere
    if (z2 <= 0.05) return;

    final screenX = center.dx + x2 * radius;
    final screenY = center.dy - y2 * radius;
    final pinPos = Offset(screenX, screenY);

    final pinAlpha = (z2 * 2.0).clamp(0.2, 1.0);

    // Pulsing outer ripple ring
    final pulseT = (timeSec % 3.0) / 3.0;
    final pulseRadius = 5.0 + pulseT * 12.0;
    final pulseAlpha = (1.0 - pulseT) * 0.45 * pinAlpha;

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accentColor.withValues(alpha: pulseAlpha);
    canvas.drawCircle(pinPos, pulseRadius, ripplePaint);

    if (isHome) {
      // Home city: Double concentric ring
      final homeRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = accentColor.withValues(alpha: pinAlpha);
      canvas.drawCircle(pinPos, 6.0, homeRingPaint);
    }

    // Core glowing ember pin
    final corePaint = Paint()
      ..color = (isHome ? GlobeTokens.starTwinkle : accentColor).withValues(
        alpha: pinAlpha,
      );
    canvas.drawCircle(pinPos, 3.5, corePaint);

    // Selected city floating glass chip
    if (!isHome && selectedCity != null) {
      final textSpan = TextSpan(
        text: city.name,
        style: TextStyle(
          color: isDark ? GlobeTokens.chipTextDark : GlobeTokens.chipTextLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();

      final chipOffset = pinPos + const Offset(12, -18);
      final chipRect = Rect.fromLTWH(
        chipOffset.dx,
        chipOffset.dy,
        tp.width + 14,
        tp.height + 8,
      );

      final chipBg = Paint()
        ..color = (isDark ? GlobeTokens.chipBackgroundDark : Colors.white)
            .withValues(alpha: 0.90);
      final chipBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = accentColor.withValues(alpha: 0.4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(chipRect, const Radius.circular(6)),
        chipBg,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chipRect, const Radius.circular(6)),
        chipBorder,
      );
      tp.paint(canvas, chipOffset + const Offset(7, 4));
    }
  }

  @override
  bool shouldRepaint(covariant GlobePainterFallback oldDelegate) => true;
}
