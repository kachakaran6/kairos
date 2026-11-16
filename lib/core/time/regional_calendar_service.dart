import 'dart:math';

/// Spec §10 & §24: Cultural & Regional Calendar calculations for Kairos.
///
/// Implements Vikram Samvat, Islamic (Hijri), and astronomical lunar phase
/// calculations for regional timekeeping.

enum MoonPhaseType {
  newMoon('New Moon', '🌑'),
  waxingCrescent('Waxing Crescent', '🌒'),
  firstQuarter('First Quarter', '🌓'),
  waxingGibbous('Waxing Gibbous', '🌔'),
  fullMoon('Full Moon', '🌕'),
  waningGibbous('Waning Gibbous', '🌖'),
  lastQuarter('Last Quarter', '🌗'),
  waningCrescent('Waning Crescent', '🌘');

  const MoonPhaseType(this.label, this.glyph);
  final String label;
  final String glyph;
}

class MoonPhase {
  const MoonPhase({
    required this.type,
    required this.fractionIlluminated,
    required this.ageInDays,
  });

  final MoonPhaseType type;
  final double fractionIlluminated;
  final double ageInDays;
}

class VikramSamvatDate {
  const VikramSamvatDate({required this.year, required this.era});

  final int year;
  final String era;

  String get formatted => '$year $era';
}

class HijriDate {
  const HijriDate({
    required this.year,
    required this.month,
    required this.monthName,
    required this.day,
  });

  final int year;
  final int month;
  final String monthName;
  final int day;

  String get formatted => '$day $monthName $year AH';
}

class RegionalCalendarService {
  const RegionalCalendarService();

  static const List<String> hijriMonthNames = <String>[
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' ath-Thani",
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  /// Converts UTC instant to Vikram Samvat Hindu calendar year.
  VikramSamvatDate getVikramSamvat(DateTime dateUtc) {
    // Vikram Samvat is approximately 56.7 to 57 years ahead of Gregorian.
    // Chaitra Shukla Pratipada begins in March/April.
    final year = dateUtc.month >= 4 ? dateUtc.year + 57 : dateUtc.year + 56;
    return VikramSamvatDate(year: year, era: 'VS');
  }

  /// Calculates Islamic (Hijri) date using tabular civil algorithm.
  HijriDate getHijriDate(DateTime dateUtc) {
    final jd = _julianDay(dateUtc.year, dateUtc.month, dateUtc.day);
    var l = (jd - 1948440) + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j =
        ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() +
        (l / 5670).floor() * ((43 * l) / 15238).floor();
    l =
        l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = ((24 * l) / 709).floor();
    final day = l - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;

    final safeMonth = month.clamp(1, 12);
    return HijriDate(
      year: year,
      month: safeMonth,
      monthName: hijriMonthNames[safeMonth - 1],
      day: day,
    );
  }

  /// Calculates astronomical lunar phase and illumination percentage.
  MoonPhase getMoonPhase(DateTime dateUtc) {
    // Reference new moon: 2000-01-06 18:14 UTC
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    const synodicMonth = 29.53058867; // average days per lunar cycle

    final diffDays = dateUtc.difference(reference).inSeconds / 86400.0;
    final age = diffDays % synodicMonth;
    final phaseFraction = age / synodicMonth;

    // Illumination fraction (0.0 to 1.0)
    final illumination = (1.0 - cos(phaseFraction * 2 * pi)) / 2.0;

    final MoonPhaseType type;
    if (phaseFraction < 0.03 || phaseFraction >= 0.97) {
      type = MoonPhaseType.newMoon;
    } else if (phaseFraction < 0.22) {
      type = MoonPhaseType.waxingCrescent;
    } else if (phaseFraction < 0.28) {
      type = MoonPhaseType.firstQuarter;
    } else if (phaseFraction < 0.47) {
      type = MoonPhaseType.waxingGibbous;
    } else if (phaseFraction < 0.53) {
      type = MoonPhaseType.fullMoon;
    } else if (phaseFraction < 0.72) {
      type = MoonPhaseType.waningGibbous;
    } else if (phaseFraction < 0.78) {
      type = MoonPhaseType.lastQuarter;
    } else {
      type = MoonPhaseType.waningCrescent;
    }

    return MoonPhase(
      type: type,
      fractionIlluminated: illumination,
      ageInDays: age,
    );
  }

  int _julianDay(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524;
  }
}
