import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/time/regional_calendar_service.dart';

void main() {
  const service = RegionalCalendarService();

  group('RegionalCalendarService', () {
    test('calculates Vikram Samvat year accurately', () {
      final nov2026 = DateTime.utc(2026, 11, 16);
      final vs = service.getVikramSamvat(nov2026);
      expect(vs.year, 2083);
      expect(vs.formatted, '2083 VS');

      final jan2026 = DateTime.utc(2026, 1, 15);
      final vsJan = service.getVikramSamvat(jan2026);
      expect(vsJan.year, 2082);
    });

    test('calculates Hijri Islamic calendar date accurately', () {
      final nov2026 = DateTime.utc(2026, 11, 16);
      final hijri = service.getHijriDate(nov2026);
      expect(hijri.year, 1448);
      expect(hijri.month, inInclusiveRange(1, 12));
      expect(hijri.monthName, isNotEmpty);
      expect(hijri.day, inInclusiveRange(1, 30));
      expect(hijri.formatted, contains('1448 AH'));
    });

    test(
      'calculates astronomical MoonPhase with glyphs and illumination percentage',
      () {
        final date = DateTime.utc(2026, 11, 16);
        final moon = service.getMoonPhase(date);

        expect(moon.type.label, isNotEmpty);
        expect(moon.type.glyph, isNotEmpty);
        expect(moon.fractionIlluminated, inInclusiveRange(0.0, 1.0));
        expect(moon.ageInDays, inInclusiveRange(0.0, 30.0));
      },
    );
  });
}
