enum GlobeStyleType {
  atlas, // Dotted Atlas: Ember / terracotta Fibonacci points on obsidian sphere
  earth, // Realistic Earth: NASA Blue Marble day + Black Marble night blended along terminator
  ink, // Ink: Minimalist line-art contours on warm paper for editorial light mode
}

/// Central configuration for Kairos 3D interactive Earth Globe.
class GlobeConfig {
  const GlobeConfig({
    this.style = GlobeStyleType.atlas,
    this.dotDensity = 16200,
    this.rotationSpeedRadPerSec = 0.0698, // 1 rev per ~90s
    this.axialTiltRad = 0.288, // ~16.5 degrees
    this.atmosphereStrength = 0.35,
    this.showArcs = true,
    this.showCityLights = true,
    this.autoOrientToSun = false,
    this.enableParallaxStars = true,
    this.cardHeight = 340.0,
    this.globeScaleRatio = 0.74, // 74% of card height
  });

  final GlobeStyleType style;
  final int dotDensity;
  final double rotationSpeedRadPerSec;
  final double axialTiltRad;
  final double atmosphereStrength;
  final bool showArcs;
  final bool showCityLights;
  final bool autoOrientToSun;
  final bool enableParallaxStars;
  final double cardHeight;
  final double globeScaleRatio;

  GlobeConfig copyWith({
    GlobeStyleType? style,
    int? dotDensity,
    double? rotationSpeedRadPerSec,
    double? axialTiltRad,
    double? atmosphereStrength,
    bool? showArcs,
    bool? showCityLights,
    bool? autoOrientToSun,
    bool? enableParallaxStars,
    double? cardHeight,
    double? globeScaleRatio,
  }) {
    return GlobeConfig(
      style: style ?? this.style,
      dotDensity: dotDensity ?? this.dotDensity,
      rotationSpeedRadPerSec:
          rotationSpeedRadPerSec ?? this.rotationSpeedRadPerSec,
      axialTiltRad: axialTiltRad ?? this.axialTiltRad,
      atmosphereStrength: atmosphereStrength ?? this.atmosphereStrength,
      showArcs: showArcs ?? this.showArcs,
      showCityLights: showCityLights ?? this.showCityLights,
      autoOrientToSun: autoOrientToSun ?? this.autoOrientToSun,
      enableParallaxStars: enableParallaxStars ?? this.enableParallaxStars,
      cardHeight: cardHeight ?? this.cardHeight,
      globeScaleRatio: globeScaleRatio ?? this.globeScaleRatio,
    );
  }
}
