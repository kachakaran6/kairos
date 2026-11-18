import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/world_clock/domain/globe_astronomy.dart';

void main() {
  group('GlobeAstronomy Tests', () {
    test(
      'Summer Solstice (around June 21): Solar declination near +23.44 degrees',
      () {
        final summerSolstice = DateTime.utc(2026, 6, 21, 12, 0);
        final pt = GlobeAstronomy.computeSubSolarPoint(summerSolstice);
        final declinationDeg = pt.latRad * (180.0 / math.pi);

        // Should be near +23.44° within 0.5 degrees tolerance
        expect(declinationDeg, closeTo(23.44, 0.5));
      },
    );

    test(
      'Winter Solstice (around Dec 21): Solar declination near -23.44 degrees',
      () {
        final winterSolstice = DateTime.utc(2026, 12, 21, 12, 0);
        final pt = GlobeAstronomy.computeSubSolarPoint(winterSolstice);
        final declinationDeg = pt.latRad * (180.0 / math.pi);

        // Should be near -23.44° within 0.5 degrees tolerance
        expect(declinationDeg, closeTo(-23.44, 0.5));
      },
    );

    test(
      'Vernal Equinox (around March 20): Solar declination near 0 degrees',
      () {
        final equinox = DateTime.utc(2026, 3, 20, 12, 0);
        final pt = GlobeAstronomy.computeSubSolarPoint(equinox);
        final declinationDeg = pt.latRad * (180.0 / math.pi);

        // Should be very close to equator (within 0.5 degrees)
        expect(declinationDeg, closeTo(0.0, 0.5));
      },
    );

    test('Solar noon at Greenwich (0 degrees lon) occurs near 12:00 UTC', () {
      final noonGmt = DateTime.utc(2026, 6, 21, 12, 0);
      final pt = GlobeAstronomy.computeSubSolarPoint(noonGmt);
      final lonDeg = pt.lonRad * (180.0 / math.pi);

      // Due to equation of time, solar noon is within ~5 degrees of Greenwich meridian
      expect(lonDeg, closeTo(0.0, 5.0));
    });

    test('Time travel offset smoothly shifts solar longitude', () {
      final base = DateTime.utc(2026, 11, 17, 10, 30);
      final pt1 = GlobeAstronomy.computeSubSolarPoint(base, 0);
      final pt2 = GlobeAstronomy.computeSubSolarPoint(base, 120); // +2 hours

      // Longitude rotates by ~30 degrees in 2 hours (15°/hour)
      var diffDeg = (pt1.lonRad - pt2.lonRad) * (180.0 / math.pi);
      if (diffDeg < 0) diffDeg += 360.0;
      expect(diffDeg, closeTo(30.0, 1.0));
    });

    test('Sub-solar vector is a valid unit vector with norm 1.0', () {
      final vec = GlobeAstronomy.computeSubSolarVector(
        DateTime.utc(2026, 4, 15, 14, 25),
      );
      final norm = math.sqrt(
        vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2],
      );
      expect(norm, closeTo(1.0, 1e-6));
    });

    test(
      'Great-circle distance between Mumbai and London is accurate (~7,200 km / ~1.13 rad)',
      () {
        // Mumbai: 19.0760° N, 72.8777° E
        // London: 51.5074° N, 0.1278° W
        final distRad = GlobeAstronomy.greatCircleDistanceRad(
          19.0760,
          72.8777,
          51.5074,
          -0.1278,
        );
        // Earth radius is ~6,371 km -> 1.13 rad * 6371 ~= 7,200 km
        expect(distRad, closeTo(1.13, 0.05));
      },
    );
  });
}
