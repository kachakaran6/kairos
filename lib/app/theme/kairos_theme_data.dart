import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/colour_tokens.dart';
import '../../core/design/radius_tokens.dart';
import '../../core/design/spacing_tokens.dart';
import '../../core/design/type_scale_tokens.dart';
import '../../core/theme/theme_extension.dart';

/// Builds the two first-class Kairos themes from tokens only.
abstract final class KairosThemeData {
  static ThemeData dark({Color? accentOverride, String? fontFamily}) => _build(
    accentOverride != null
        ? KairosColourTokens.dark.withAccent(accentOverride)
        : KairosColourTokens.dark,
    fontFamily: fontFamily,
  );

  static ThemeData light({Color? accentOverride, String? fontFamily}) => _build(
    accentOverride != null
        ? KairosColourTokens.light.withAccent(accentOverride)
        : KairosColourTokens.light,
    fontFamily: fontFamily,
  );

  static ThemeData _build(KairosColourTokens c, {String? fontFamily}) {
    final baseScale = KairosTypeScale.standard;
    final scale = fontFamily != null
        ? baseScale.withFontFamily(fontFamily, 'Georgia')
        : baseScale;
    final textTheme = scale.toTextTheme(
      c.textPrimary,
      c.textSecondary,
      c.textTertiary,
    );

    final scheme = ColorScheme(
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accentMuted,
      onSecondary: c.textPrimary,
      error: c.danger,
      onError: c.background,
      surface: c.surface,
      onSurface: c.textPrimary,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.surfaceElevated,
      onSurfaceVariant: c.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        KairosTheme(colours: c, typeScale: scale),
      ],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: c.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.lgRadius,
          side: BorderSide(color: c.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, Space.touchTargetAndroid),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.accentMuted,
          disabledForegroundColor: c.textTertiary,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: RadiusTokens.mdRadius,
          ),
          textStyle: scale.section,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Space.touchTargetIos, Space.touchTargetIos),
          foregroundColor: c.textPrimary,
          textStyle: scale.section,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: scale.body.copyWith(color: c.textTertiary),
        labelStyle: scale.caption.copyWith(color: c.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: RadiusTokens.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.inputRadius,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: scale.body.copyWith(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: RadiusTokens.mdRadius,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.xl),
          ),
        ),
      ),
    );
  }
}
