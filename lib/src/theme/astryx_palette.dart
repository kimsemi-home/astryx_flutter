import 'package:flutter/material.dart';

/// Categorical hues exposed by the Astryx neutral theme.
enum AstryxCategory {
  red,
  orange,
  yellow,
  green,
  teal,
  cyan,
  blue,
  purple,
  pink,
  gray,
}

@immutable
class AstryxCategoryColors {
  const AstryxCategoryColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  static AstryxCategoryColors lerp(
    AstryxCategoryColors a,
    AstryxCategoryColors b,
    double t,
  ) {
    return AstryxCategoryColors(
      background: Color.lerp(a.background, b.background, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      icon: Color.lerp(a.icon, b.icon, t)!,
      text: Color.lerp(a.text, b.text, t)!,
    );
  }
}

/// Flutter theme extension mirroring Astryx neutral semantic tokens.
@immutable
class AstryxPalette extends ThemeExtension<AstryxPalette> {
  const AstryxPalette({
    required this.surface,
    required this.body,
    required this.card,
    required this.popover,
    required this.muted,
    required this.accent,
    required this.accentMuted,
    required this.neutral,
    required this.overlay,
    required this.overlayHover,
    required this.overlayPressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.onAccent,
    required this.success,
    required this.error,
    required this.warning,
    required this.successMuted,
    required this.errorMuted,
    required this.warningMuted,
    required this.border,
    required this.borderEmphasized,
    required this.categories,
  });

  final Color surface;
  final Color body;
  final Color card;
  final Color popover;
  final Color muted;
  final Color accent;
  final Color accentMuted;
  final Color neutral;
  final Color overlay;
  final Color overlayHover;
  final Color overlayPressed;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color onAccent;
  final Color success;
  final Color error;
  final Color warning;
  final Color successMuted;
  final Color errorMuted;
  final Color warningMuted;
  final Color border;
  final Color borderEmphasized;
  final Map<AstryxCategory, AstryxCategoryColors> categories;

  AstryxCategoryColors category(AstryxCategory category) =>
      categories[category] ??
      (throw StateError('Missing Astryx category: ${category.name}'));

  @override
  AstryxPalette copyWith({
    Color? surface,
    Color? body,
    Color? card,
    Color? popover,
    Color? muted,
    Color? accent,
    Color? accentMuted,
    Color? neutral,
    Color? overlay,
    Color? overlayHover,
    Color? overlayPressed,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? onAccent,
    Color? success,
    Color? error,
    Color? warning,
    Color? successMuted,
    Color? errorMuted,
    Color? warningMuted,
    Color? border,
    Color? borderEmphasized,
    Map<AstryxCategory, AstryxCategoryColors>? categories,
  }) {
    return AstryxPalette(
      surface: surface ?? this.surface,
      body: body ?? this.body,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      neutral: neutral ?? this.neutral,
      overlay: overlay ?? this.overlay,
      overlayHover: overlayHover ?? this.overlayHover,
      overlayPressed: overlayPressed ?? this.overlayPressed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      successMuted: successMuted ?? this.successMuted,
      errorMuted: errorMuted ?? this.errorMuted,
      warningMuted: warningMuted ?? this.warningMuted,
      border: border ?? this.border,
      borderEmphasized: borderEmphasized ?? this.borderEmphasized,
      categories: categories ?? this.categories,
    );
  }

  @override
  AstryxPalette lerp(covariant AstryxPalette? other, double t) {
    if (other == null) return this;
    return copyWith(
      surface: Color.lerp(surface, other.surface, t),
      body: Color.lerp(body, other.body, t),
      card: Color.lerp(card, other.card, t),
      popover: Color.lerp(popover, other.popover, t),
      muted: Color.lerp(muted, other.muted, t),
      accent: Color.lerp(accent, other.accent, t),
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t),
      neutral: Color.lerp(neutral, other.neutral, t),
      overlay: Color.lerp(overlay, other.overlay, t),
      overlayHover: Color.lerp(overlayHover, other.overlayHover, t),
      overlayPressed: Color.lerp(overlayPressed, other.overlayPressed, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t),
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t),
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t),
      onAccent: Color.lerp(onAccent, other.onAccent, t),
      success: Color.lerp(success, other.success, t),
      error: Color.lerp(error, other.error, t),
      warning: Color.lerp(warning, other.warning, t),
      successMuted: Color.lerp(successMuted, other.successMuted, t),
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t),
      warningMuted: Color.lerp(warningMuted, other.warningMuted, t),
      border: Color.lerp(border, other.border, t),
      borderEmphasized: Color.lerp(
        borderEmphasized,
        other.borderEmphasized,
        t,
      ),
      categories: {
        for (final category in AstryxCategory.values)
          category: AstryxCategoryColors.lerp(
            this.category(category),
            other.category(category),
            t,
          ),
      },
    );
  }
}

extension AstryxPaletteContext on BuildContext {
  AstryxPalette get astryx =>
      Theme.of(this).extension<AstryxPalette>() ??
      (throw StateError('AstryxTheme is not installed in this context.'));
}
