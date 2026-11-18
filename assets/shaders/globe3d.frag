#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uRotation;        // x: lon (rad), y: lat (rad)
uniform vec3 uSunSphere;      // Sub-solar point on sphere
uniform vec4 uAccentColor;
uniform vec4 uSphereBgColor;
uniform float uStyle;         // 0.0: Dotted Atlas, 1.0: Realistic Earth
uniform float uRadius;
uniform sampler2D uLandMask;  // Texture 0 (Land mask or Day map)
uniform sampler2D uNightMap;  // Texture 1 (Night map)

out vec4 fragColor;

const float PI = 3.141592653589793;

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

// Pseudo-random star hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 center = uResolution * 0.5;
    vec2 p = fragCoord - center;
    float dist = length(p);
    float R = uRadius;

    // Background & Atmosphere outer halo
    if (dist > R) {
        float haloRadius = R * 1.16;
        if (dist < haloRadius) {
            float haloAlpha = pow(1.0 - (dist - R) / (haloRadius - R), 3.0) * 0.28;
            fragColor = vec4(uAccentColor.rgb, haloAlpha);
            return;
        }

        // Faint background star field
        float star = step(0.9982, hash(floor(fragCoord * 0.8)));
        if (star > 0.0) {
            float starAlpha = hash(fragCoord) * 0.35;
            fragColor = vec4(0.96, 0.94, 0.90, starAlpha);
            return;
        }

        fragColor = vec4(0.0);
        return;
    }

    // Ray-sphere intersection normal
    float nx = p.x / R;
    float ny = -p.y / R;
    float nz = sqrt(max(0.0, 1.0 - nx * nx - ny * ny));
    vec3 N = vec3(nx, ny, nz);

    // Apply 3D rotation
    mat3 rot = rotateY(uRotation.x) * rotateX(uRotation.y);
    vec3 Nrot = rot * N;

    // Equirectangular UV coordinates
    float lat = asin(clamp(Nrot.y, -1.0, 1.0));
    float lon = atan(Nrot.z, Nrot.x);
    vec2 uv = vec2((lon + PI) / (2.0 * PI), 0.5 - lat / PI);
    uv = fract(uv);

    // Solar angle incidence
    float sunIncidence = dot(Nrot, uSunSphere);
    float dayFactor = smoothstep(-0.10, 0.10, sunIncidence);

    // Fresnel rim glow
    float fresnel = pow(1.0 - nz, 3.2);

    // Specular reflection
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfVec = normalize(uSunSphere + viewDir);
    float spec = pow(max(0.0, dot(Nrot, halfVec)), 28.0) * dayFactor;

    vec4 finalColor;

    if (uStyle < 0.5) {
        // STYLE 1: "Dotted Atlas"
        float maskVal = texture(uLandMask, uv).r;

        // Procedural dot matrix sampling
        float dotGridX = sin(uv.x * 2.0 * PI * 180.0);
        float dotGridY = sin(uv.y * PI * 90.0);
        float dotShape = step(0.12, dotGridX * dotGridY);

        vec3 sphereBase = uSphereBgColor.rgb;
        // Subtle ambient shadow on night side
        float ambientLight = mix(0.18, 1.0, dayFactor);

        vec3 surfaceColor = sphereBase;

        if (maskVal > 0.4 && dotShape > 0.5) {
            // Land dot
            vec3 dotCol = uAccentColor.rgb * ambientLight;
            surfaceColor = mix(surfaceColor, dotCol, 0.92);
        } else if (maskVal > 0.4) {
            // Subtle land tint
            surfaceColor = mix(surfaceColor, uAccentColor.rgb, 0.12 * ambientLight);
        }

        // Atmosphere rim & specular glint
        surfaceColor += uAccentColor.rgb * fresnel * 0.45;
        surfaceColor += vec3(1.0, 0.95, 0.88) * spec * 0.40;

        finalColor = vec4(surfaceColor, 1.0);
    } else {
        // STYLE 2: "Realistic Earth"
        vec3 dayTex = texture(uLandMask, uv).rgb;
        vec3 nightTex = texture(uNightMap, uv).rgb;

        vec3 earthSurface = mix(nightTex * 1.6, dayTex * (0.2 + 0.8 * max(0.0, sunIncidence)), dayFactor);

        // Atmosphere rim
        earthSurface += uAccentColor.rgb * fresnel * 0.50;
        // Sun specular glint on ocean
        earthSurface += vec3(1.0, 0.95, 0.85) * spec * 0.55;

        finalColor = vec4(earthSurface, 1.0);
    }

    fragColor = finalColor;
}
