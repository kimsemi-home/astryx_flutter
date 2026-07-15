import 'package:flutter/material.dart';

import 'astryx_palette.dart';
import 'astryx_tokens.dart';

/// Material 3 bridge for the Astryx neutral token set.
abstract final class AstryxTheme {
  static ThemeData light() => fromPalette(
        AstryxTokens.light,
        brightness: Brightness.light,
      );

  static ThemeData dark() => fromPalette(
        AstryxTokens.dark,
        brightness: Brightness.dark,
      );

  static ThemeData fromPalette(
    AstryxPalette palette, {
    required Brightness brightness,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        secondary: palette.accentMuted,
        onSecondary: palette.textPrimary,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: palette.error,
        onError: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF171717),
        outline: palette.borderEmphasized,
        outlineVariant: palette.border,
      ),
      scaffoldBackgroundColor: palette.body,
      dividerColor: palette.border,
      disabledColor: palette.textDisabled,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AstryxRadii.element),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AstryxRadii.element),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AstryxRadii.element),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: palette.textPrimary,
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
          height: 1.45,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
          height: 1.4,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
