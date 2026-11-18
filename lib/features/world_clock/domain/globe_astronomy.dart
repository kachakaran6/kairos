import 'dart:math' as math;

/// Physical and astronomical calculations for the Kairos Earth Globe.
/// Computes accurate sub-solar points (solar declination, equation of time),
/// day/night terminator angles, twilight bands, and great-circle geometry.
class GlobeAstronomy {
  const GlobeAstronomy._();

  static const double pi = math.pi;
  static const double degToRad = pi / 180.0;
  static const double radToDeg = 180.0 / pi;

  /// Earth's axial tilt / obliquity (approximately 23.44 degrees).
  static const double earthObliquityDeg = 23.4392911;

  /// Computes the sub-solar coordinates (latitude and longitude in radians)
  /// for a given UTC timestamp, plus an optional simulated time offset in minutes.
  static ({double latRad, double lonRad}) computeSubSolarPoint(
    DateTime utc, [
    int offsetMinutes = 0,
  ]) {
    final adjusted = utc.add(Duration(minutes: offsetMinutes));

    // Julian Date calculation
    final y = adjusted.year;
    final m = adjusted.month;
    final d =
        adjusted.day +
        adjusted.hour / 24.0 +
        adjusted.minute / 1440.0 +
        adjusted.second / 86400.0;

    int yCalc = y;
    int mCalc = m;
    if (m <= 2) {
      yCalc -= 1;
      mCalc += 12;
    }

    final a = (yCalc / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd =
        (365.25 * (yCalc + 4716)).floor() +
        (30.6001 * (mCalc + 1)).floor() +
        d +
        b -
        1524.5;

    // Julian centuries since J2000.0
    final t = (jd - 2451545.0) / 36525.0;

    // Geometric mean longitude of the Sun (degrees)
    var l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
    l0 = l0 % 360.0;
    if (l0 < 0) l0 += 360.0;

    // Mean anomaly of the Sun (degrees)
    var mSun = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    mSun = mSun % 360.0;
    if (mSun < 0) mSun += 360.0;

    // Equation of the center (degrees)
    final mRad = mSun * degToRad;
    final c =
        math.sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * mRad) * (0.019993 - 0.000101 * t) +
        math.sin(3 * mRad) * 0.000289;

    // Sun's true longitude (degrees)
    final sunTrueLon = l0 + c;

    // Apparent longitude of the Sun (correcting for nutation and aberration)
    final omega = (125.04 - 1934.136 * t) * degToRad;
    final lambda =
        (sunTrueLon - 0.00569 - 0.00478 * math.sin(omega)) * degToRad;

    // Obliquity of the ecliptic
    final eps0 =
        23.0 +
        (26.0 +
                (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) /
                    60.0) /
            60.0;
    final eps = (eps0 + 0.00256 * math.cos(omega)) * degToRad;

    // Solar Declination (latitude of sub-solar point)
    final declinationRad = math.asin(math.sin(eps) * math.sin(lambda));

    // Equation of Time (minutes of time)
    final yTan = math.tan(eps / 2.0);
    final y2 = yTan * yTan;
    final l0Rad = l0 * degToRad;
    final eTimeMin =
        4.0 *
        radToDeg *
        (y2 * math.sin(2.0 * l0Rad) -
            2.0 * 0.016708634 * math.sin(mRad) +
            4.0 * 0.016708634 * y2 * math.sin(mRad) * math.cos(2.0 * l0Rad) -
            0.5 * y2 * y2 * math.sin(4.0 * l0Rad) -
            1.25 * 0.016708634 * 0.016708634 * math.sin(2.0 * mRad));

    // Sub-solar longitude from UTC fractional day and equation of time
    final fracHours =
        adjusted.hour +
        adjusted.minute / 60.0 +
        adjusted.second / 3600.0 +
        adjusted.millisecond / 3600000.0;
    // Greenwich Solar Hour Angle (solar noon is at 12:00 + eTime)
    final solarHourAngleDeg = 15.0 * (12.0 - (fracHours + eTimeMin / 60.0));
    var subSolarLonDeg = solarHourAngleDeg % 360.0;
    if (subSolarLonDeg > 180.0) subSolarLonDeg -= 360.0;
    if (subSolarLonDeg < -180.0) subSolarLonDeg += 360.0;

    return (latRad: declinationRad, lonRad: subSolarLonDeg * degToRad);
  }

  /// Converts sub-solar latitude & longitude into a 3D unit normal vector.
  static List<double> computeSubSolarVector(
    DateTime utc, [
    int offsetMinutes = 0,
  ]) {
    final pt = computeSubSolarPoint(utc, offsetMinutes);
    final lat = pt.latRad;
    final lon = pt.lonRad;

    final x = math.cos(lat) * math.cos(lon);
    final y = math.sin(lat);
    final z = math.cos(lat) * math.sin(lon);
    return [x, y, z];
  }

  /// Computes day factor (0.0 = deep night, 0.5 = twilight terminator, 1.0 = noon)
  /// for any point on the sphere given its surface normal and the sub-solar vector.
  /// Twilight band spans approx 16 degrees (~0.28 rad).
  static double computeDayFactor(
    List<double> surfaceNormal,
    List<double> sunVector,
  ) {
    final dot =
        surfaceNormal[0] * sunVector[0] +
        surfaceNormal[1] * sunVector[1] +
        surfaceNormal[2] * sunVector[2];

    // Smoothstep across twilight (-0.14 to +0.14 incidence angle)
    const edge0 = -0.14;
    const edge1 = 0.14;
    final t = ((dot - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Calculates great-circle angular distance (in radians) between two geographic points.
  static double greatCircleDistanceRad(
    double lat1Deg,
    double lon1Deg,
    double lat2Deg,
    double lon2Deg,
  ) {
    final phi1 = lat1Deg * degToRad;
    final phi2 = lat2Deg * degToRad;
    final dPhi = (lat2Deg - lat1Deg) * degToRad;
    final dLam = (lon2Deg - lon1Deg) * degToRad;

    final sinDPhi2 = math.sin(dPhi / 2);
    final sinDLam2 = math.sin(dLam / 2);

    final a =
        sinDPhi2 * sinDPhi2 +
        math.cos(phi1) * math.cos(phi2) * sinDLam2 * sinDLam2;
    return 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
  }

  /// Interpolates a great-circle arc between two points at parameter t [0, 1]
  /// using Slerp (Spherical Linear Interpolation).
  static List<double> slerpArcPoint(
    List<double> p1,
    List<double> p2,
    double t, [
    double liftRadius = 1.04,
  ]) {
    var dot = p1[0] * p2[0] + p1[1] * p2[1] + p1[2] * p2[2];
    dot = dot.clamp(-1.0, 1.0);

    final theta = math.acos(dot);
    if (theta.abs() < 1e-5) {
      return [p1[0] * liftRadius, p1[1] * liftRadius, p1[2] * liftRadius];
    }

    final sinTheta = math.sin(theta);
    final a = math.sin((1.0 - t) * theta) / sinTheta;
    final b = math.sin(t * theta) / sinTheta;

    // Slight parabolic arc lift in the middle so the flight path hovers above the surface
    final arcLift = liftRadius + 0.05 * math.sin(t * pi);

    final x = (a * p1[0] + b * p2[0]) * arcLift;
    final y = (a * p1[1] + b * p2[1]) * arcLift;
    final z = (a * p1[2] + b * p2[2]) * arcLift;
    return [x, y, z];
  }
}
