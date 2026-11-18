/// Geolocation dataset of world metropolitan cities for night-lights clustering,
/// pin snapping, and great-circle connections.
class GlobeCityPoint {
  const GlobeCityPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.utcOffsetMinutes,
    this.brightness = 0.8,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int utcOffsetMinutes;
  final double brightness;
}

const List<GlobeCityPoint> kMajorWorldCities = [
  // Home City
  GlobeCityPoint(
    name: 'Mumbai',
    latitude: 19.0760,
    longitude: 72.8777,
    utcOffsetMinutes: 330,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Delhi',
    latitude: 28.6139,
    longitude: 77.2090,
    utcOffsetMinutes: 330,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Bengaluru',
    latitude: 12.9716,
    longitude: 77.5946,
    utcOffsetMinutes: 330,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Kolkata',
    latitude: 22.5726,
    longitude: 88.3639,
    utcOffsetMinutes: 330,
    brightness: 0.9,
  ),

  // Europe
  GlobeCityPoint(
    name: 'London',
    latitude: 51.5074,
    longitude: -0.1278,
    utcOffsetMinutes: 0,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Paris',
    latitude: 48.8566,
    longitude: 2.3522,
    utcOffsetMinutes: 60,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Berlin',
    latitude: 52.5200,
    longitude: 13.4050,
    utcOffsetMinutes: 60,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Rome',
    latitude: 41.9028,
    longitude: 12.4964,
    utcOffsetMinutes: 60,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Madrid',
    latitude: 40.4168,
    longitude: -3.7038,
    utcOffsetMinutes: 60,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Amsterdam',
    latitude: 52.3676,
    longitude: 4.9041,
    utcOffsetMinutes: 60,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Zurich',
    latitude: 47.3769,
    longitude: 8.5417,
    utcOffsetMinutes: 60,
    brightness: 0.8,
  ),
  GlobeCityPoint(
    name: 'Vienna',
    latitude: 48.2082,
    longitude: 16.3738,
    utcOffsetMinutes: 60,
    brightness: 0.8,
  ),
  GlobeCityPoint(
    name: 'Stockholm',
    latitude: 59.3293,
    longitude: 18.0686,
    utcOffsetMinutes: 60,
    brightness: 0.75,
  ),
  GlobeCityPoint(
    name: 'Athens',
    latitude: 37.9838,
    longitude: 23.7275,
    utcOffsetMinutes: 120,
    brightness: 0.8,
  ),
  GlobeCityPoint(
    name: 'Istanbul',
    latitude: 41.0082,
    longitude: 28.9784,
    utcOffsetMinutes: 180,
    brightness: 0.95,
  ),

  // Americas
  GlobeCityPoint(
    name: 'New York',
    latitude: 40.7128,
    longitude: -74.0060,
    utcOffsetMinutes: -300,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'San Francisco',
    latitude: 37.7749,
    longitude: -122.4194,
    utcOffsetMinutes: -480,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Los Angeles',
    latitude: 34.0522,
    longitude: -118.2437,
    utcOffsetMinutes: -480,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Chicago',
    latitude: 41.8781,
    longitude: -87.6298,
    utcOffsetMinutes: -360,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Toronto',
    latitude: 43.6532,
    longitude: -79.3832,
    utcOffsetMinutes: -300,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Vancouver',
    latitude: 49.2827,
    longitude: -123.1207,
    utcOffsetMinutes: -480,
    brightness: 0.8,
  ),
  GlobeCityPoint(
    name: 'Mexico City',
    latitude: 19.4326,
    longitude: -99.1332,
    utcOffsetMinutes: -360,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Sao Paulo',
    latitude: -23.5505,
    longitude: -46.6333,
    utcOffsetMinutes: -180,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Buenos Aires',
    latitude: -34.6037,
    longitude: -58.3816,
    utcOffsetMinutes: -180,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Santiago',
    latitude: -33.4489,
    longitude: -70.6693,
    utcOffsetMinutes: -180,
    brightness: 0.8,
  ),

  // Asia & Middle East
  GlobeCityPoint(
    name: 'Tokyo',
    latitude: 35.6762,
    longitude: 139.6503,
    utcOffsetMinutes: 540,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Kyoto',
    latitude: 35.0116,
    longitude: 135.7681,
    utcOffsetMinutes: 540,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Seoul',
    latitude: 37.5665,
    longitude: 126.9780,
    utcOffsetMinutes: 540,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Beijing',
    latitude: 39.9042,
    longitude: 116.4074,
    utcOffsetMinutes: 480,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Shanghai',
    latitude: 31.2304,
    longitude: 121.4737,
    utcOffsetMinutes: 480,
    brightness: 1.0,
  ),
  GlobeCityPoint(
    name: 'Hong Kong',
    latitude: 22.3193,
    longitude: 114.1694,
    utcOffsetMinutes: 480,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Singapore',
    latitude: 1.3521,
    longitude: 103.8198,
    utcOffsetMinutes: 480,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Bangkok',
    latitude: 13.7563,
    longitude: 100.5018,
    utcOffsetMinutes: 420,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
    utcOffsetMinutes: 420,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Dubai',
    latitude: 25.2048,
    longitude: 55.2708,
    utcOffsetMinutes: 240,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Riyadh',
    latitude: 24.7136,
    longitude: 46.6753,
    utcOffsetMinutes: 180,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Tel Aviv',
    latitude: 32.0853,
    longitude: 34.7818,
    utcOffsetMinutes: 120,
    brightness: 0.85,
  ),

  // Africa
  GlobeCityPoint(
    name: 'Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    utcOffsetMinutes: 120,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Johannesburg',
    latitude: -26.2041,
    longitude: 28.0473,
    utcOffsetMinutes: 120,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Nairobi',
    latitude: -1.2921,
    longitude: 36.8219,
    utcOffsetMinutes: 180,
    brightness: 0.75,
  ),
  GlobeCityPoint(
    name: 'Lagos',
    latitude: 6.5244,
    longitude: 3.3792,
    utcOffsetMinutes: 60,
    brightness: 0.85,
  ),
  GlobeCityPoint(
    name: 'Casablanca',
    latitude: 33.5731,
    longitude: -7.5898,
    utcOffsetMinutes: 60,
    brightness: 0.75,
  ),

  // Oceania
  GlobeCityPoint(
    name: 'Sydney',
    latitude: -33.8688,
    longitude: 151.2093,
    utcOffsetMinutes: 600,
    brightness: 0.95,
  ),
  GlobeCityPoint(
    name: 'Melbourne',
    latitude: -37.8136,
    longitude: 144.9631,
    utcOffsetMinutes: 600,
    brightness: 0.9,
  ),
  GlobeCityPoint(
    name: 'Auckland',
    latitude: -36.8485,
    longitude: 174.7633,
    utcOffsetMinutes: 720,
    brightness: 0.8,
  ),
  GlobeCityPoint(
    name: 'Honolulu',
    latitude: 21.3069,
    longitude: -157.8583,
    utcOffsetMinutes: -600,
    brightness: 0.8,
  ),
];
