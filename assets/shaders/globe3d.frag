#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uRotation;        // x: lon (rad), y: lat (rad)
uniform vec3 uSunSphere;       // Sub-solar point unit vector
uniform vec4 uAccentColor;     // App theme accent (Ember/Terracotta)
uniform vec4 uSphereBgColor;   // Ocean/canvas background
uniform float uStyle;          // 0.0: Atlas, 1.0: Earth, 2.0: Ink
uniform float uRadius;         // Globe sphere pixel radius
uniform float uTime;           // Animation time in seconds
uniform vec2 uParallax;        // Parallax star shift
uniform sampler2D uLandMask;   // Texture 0: Land mask / Day map
uniform sampler2D uNightMap;   // Texture 1: Night map

out vec4 fragColor;

const float PI = 3.14159265358979323846;
const float TWO_PI = 6.28318530717958647692;

mat3 rotateY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

mat3 rotateX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// High quality pseudo-random hash for stars
float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 center = uResolution * 0.5;
    vec2 p = fragCoord - center;
    float dist = length(p);
    float R = uRadius;

    bool isLightMode = (uSphereBgColor.r + uSphereBgColor.g + uSphereBgColor.b) > 1.5;

    // -------------------------------------------------------------
    // 1. SPACE BACKGROUND & ATMOSPHERE GLOW
    // -------------------------------------------------------------
    if (dist > R) {
        float outerAtmosphereDist = R * 1.12;
        if (dist < outerAtmosphereDist) {
            // Soft atmospheric fresnel glow fading exponentially outward
            float dRatio = (dist - R) / (outerAtmosphereDist - R);
            float haloAlpha = exp(-3.8 * dRatio) * 0.38;

            vec3 atmosColor = isLightMode 
                ? mix(vec3(0.92, 0.88, 0.82), uAccentColor.rgb, 0.25)
                : mix(uAccentColor.rgb, vec3(0.95, 0.75, 0.55), 0.35);

            fragColor = vec4(atmosColor, haloAlpha);
            return;
        }

        // Tiny, refined circular starfield with 3 distinct sizes and twinkling (Dark mode only)
        if (!isLightMode) {
            vec2 starCoord = fragCoord + uParallax * 15.0;
            vec2 gridId = floor(starCoord / 18.0);
            float h = hash21(gridId);

            if (h > 0.965) {
                vec2 localPos = fract(starCoord / 18.0) * 18.0 - 9.0;
                float starRadius = (h > 0.992) ? 1.4 : ((h > 0.980) ? 1.0 : 0.7);
                float d = length(localPos);

                if (d < starRadius) {
                    float twinkle = 0.5 + 0.5 * sin(uTime * 2.5 + h * 6.28);
                    float starAlpha = (1.0 - d / starRadius) * (0.25 + 0.45 * twinkle);
                    fragColor = vec4(0.96, 0.94, 0.90, starAlpha);
                    return;
                }
            }
        }

        fragColor = vec4(0.0);
        return;
    }

    // -------------------------------------------------------------
    // 2. RAY-SPHERE INTERSECTION & COORDINATES
    // -------------------------------------------------------------
    float nx = p.x / R;
    float ny = -p.y / R;
    float nz = sqrt(max(0.0, 1.0 - nx * nx - ny * ny));
    vec3 N = vec3(nx, ny, nz);

    // Apply Camera 3D Rotation
    mat3 rot = rotateY(uRotation.x) * rotateX(uRotation.y);
    vec3 Nrot = rot * N;

    // Spherical coordinates
    float lat = asin(clamp(Nrot.y, -1.0, 1.0));
    float lon = atan(Nrot.z, Nrot.x);

    // Normalized equirectangular UV for texture sampling
    vec2 uv = vec2((lon + PI) / TWO_PI, 0.5 - lat / PI);
    uv = fract(uv);

    // -------------------------------------------------------------
    // 3. ASTRONOMY SOLAR TERMINATOR
    // -------------------------------------------------------------
    float sunIncidence = dot(Nrot, uSunSphere);
    // 16-degree twilight band (civil to nautical twilight)
    float dayFactor = smoothstep(-0.14, 0.14, sunIncidence);

    // Golden dawn / dusk twilight edge glow along the terminator
    float twilightGlint = exp(-40.0 * sunIncidence * sunIncidence);

    // Fresnel rim factor (brighter at grazing angles / limb)
    float fresnel = pow(1.0 - nz, 3.5);

    // Subtle ocean graticule lines (every 30 degrees latitude & longitude)
    float gratLat = abs(sin(lat * 6.0));
    float gratLon = abs(sin(lon * 6.0));
    float graticule = smoothstep(0.98, 1.0, max(gratLat, gratLon)) * 0.06;

    // -------------------------------------------------------------
    // 4. STYLE RENDERING
    // -------------------------------------------------------------
    vec4 finalColor;

    if (uStyle < 0.5) {
        // --- STYLE 0: "DOTTED ATLAS" (Obsidian & Ember) ---
        float maskVal = texture(uLandMask, uv).r;

        // Equal-area spherical dot distribution (prevents polar stretching & moiré)
        float cosLat = max(0.10, cos(lat));
        float dotsInLat = floor(360.0 * cosLat);
        float dotCellX = fract((lon + PI) / TWO_PI * dotsInLat) - 0.5;
        float dotCellY = fract((lat + PI * 0.5) / PI * 180.0) - 0.5;
        float distToDotCenter = length(vec2(dotCellX, dotCellY));

        // Foreshortening: dots become smaller and compress near the limb
        float dotRadius = 0.28 * clamp(nz, 0.35, 1.0);
        float dotMask = smoothstep(dotRadius, dotRadius - 0.08, distToDotCenter);

        vec3 oceanBase = isLightMode
            ? mix(vec3(0.98, 0.96, 0.93), vec3(0.92, 0.89, 0.85), 1.0 - nz)
            : mix(vec3(0.045, 0.040, 0.035), vec3(0.075, 0.068, 0.060), nz);

        // Graticule on ocean
        oceanBase += isLightMode ? vec3(-graticule) : vec3(graticule * 0.4);

        vec3 surfaceColor = oceanBase;

        if (maskVal > 0.42 && dotMask > 0.05) {
            // Land dot present
            if (isLightMode) {
                // Light mode: Ink to terracotta dots
                vec3 dayDot = mix(vec3(0.18, 0.15, 0.13), uAccentColor.rgb, 0.45);
                vec3 nightDot = vec3(0.45, 0.40, 0.38);
                vec3 dotCol = mix(nightDot, dayDot, dayFactor);
                surfaceColor = mix(surfaceColor, dotCol, dotMask * 0.95);
            } else {
                // Dark mode: Glowing ember terracotta dots on day side, muted slate on night side
                vec3 dayDot = mix(uAccentColor.rgb, vec3(0.98, 0.92, 0.82), 0.25);
                vec3 nightDot = vec3(0.18, 0.16, 0.15); // 25% cool slate
                vec3 dotCol = mix(nightDot, dayDot, dayFactor);

                // Dawn golden blush along terminator
                dotCol += vec3(0.95, 0.65, 0.25) * twilightGlint * 0.45;

                surfaceColor = mix(surfaceColor, dotCol, dotMask * 0.96);
            }
        } else if (maskVal > 0.42) {
            // Very subtle ambient continent fill for depth
            vec3 fillTint = isLightMode
                ? vec3(0.93, 0.90, 0.86)
                : vec3(0.07, 0.062, 0.055);
            surfaceColor = mix(surfaceColor, fillTint, 0.35);
        }

        // Night side city lights (twinkling warm amber points)
        if (dayFactor < 0.65 && maskVal > 0.45 && !isLightMode) {
            float nightLightMask = texture(uNightMap, uv).r;
            if (nightLightMask > 0.40) {
                float twinkle = 0.8 + 0.2 * sin(uTime * 3.0 + lon * 10.0);
                vec3 cityLightCol = vec3(1.0, 0.85, 0.48) * (1.0 - dayFactor) * twinkle * 1.35;
                surfaceColor += cityLightCol * nightLightMask;
            }
        }

        // Atmosphere Fresnel rim
        vec3 rimColor = isLightMode ? vec3(0.85, 0.75, 0.65) : uAccentColor.rgb;
        surfaceColor += rimColor * fresnel * (isLightMode ? 0.20 : 0.35);

        // Dawn golden arc on the limb near terminator
        surfaceColor += vec3(0.98, 0.70, 0.30) * twilightGlint * fresnel * 0.6;

        finalColor = vec4(surfaceColor, 1.0);

    } else if (uStyle < 1.5) {
        // --- STYLE 1: "REALISTIC EARTH" (NASA Day / Night blend) ---
        vec3 dayTex = texture(uLandMask, uv).rgb;
        vec3 nightTex = texture(uNightMap, uv).rgb;

        // Clean blend across solar terminator
        vec3 earthSurface = mix(nightTex * 1.55, dayTex * (0.25 + 0.75 * max(0.0, sunIncidence)), dayFactor);

        // Golden twilight atmospheric wash
        earthSurface += vec3(0.95, 0.60, 0.20) * twilightGlint * 0.28;

        // Thin atmosphere Fresnel glow
        earthSurface += uAccentColor.rgb * fresnel * 0.38;

        finalColor = vec4(earthSurface, 1.0);

    } else {
        // --- STYLE 2: "INK" (Editorial minimal line art on paper) ---
        float maskVal = texture(uLandMask, uv).r;
        vec3 paperBase = vec3(0.97, 0.95, 0.92);
        vec3 inkLine = vec3(0.16, 0.14, 0.12);

        // High contrast continent boundary contour via UV neighbor sampling (SkSL + Impeller compatible)
        vec2 dUV = vec2(0.0012, 0.0024);
        float mRight = texture(uLandMask, uv + vec2(dUV.x, 0.0)).r;
        float mTop = texture(uLandMask, uv + vec2(0.0, dUV.y)).r;
        float edge = abs(mRight - maskVal) + abs(mTop - maskVal);
        float continentContour = smoothstep(0.04, 0.18, edge);

        vec3 surfaceColor = paperBase;
        if (maskVal > 0.45) {
            surfaceColor = mix(paperBase, uAccentColor.rgb, 0.12);
        }
        surfaceColor = mix(surfaceColor, inkLine, continentContour * 0.85);

        // Subtle twilight shading
        surfaceColor *= mix(0.78, 1.0, dayFactor);
        // Soft paper rim shadow
        surfaceColor -= vec3(0.08) * fresnel;

        finalColor = vec4(surfaceColor, 1.0);
    }

    fragColor = finalColor;
}
