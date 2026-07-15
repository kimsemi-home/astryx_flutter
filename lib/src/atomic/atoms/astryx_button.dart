import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';
import '../../theme/astryx_tokens.dart';

enum AstryxButtonVariant { primary, secondary, destructive, ghost }

/// Atomic button with Astryx neutral visual variants.
class AstryxButton extends StatelessWidget {
  const AstryxButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.variant = AstryxButtonVariant.primary,
  });

  const AstryxButton.primary({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    IconData? icon,
  }) : this(label: label, onPressed: onPressed, key: key, icon: icon);

  const AstryxButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    IconData? icon,
  }) : this(
          label: label,
          onPressed: onPressed,
          key: key,
          icon: icon,
          variant: AstryxButtonVariant.secondary,
        );

  const AstryxButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    IconData? icon,
  }) : this(
          label: label,
          onPressed: onPressed,
          key: key,
          icon: icon,
          variant: AstryxButtonVariant.destructive,
        );

  const AstryxButton.ghost({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
    IconData? icon,
  }) : this(
          label: label,
          onPressed: onPressed,
          key: key,
          icon: icon,
          variant: AstryxButtonVariant.ghost,
        );

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AstryxButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    final (background, foreground, border) = switch (variant) {
      AstryxButtonVariant.primary => (
          palette.accent,
          palette.onAccent,
          palette.accent,
        ),
      AstryxButtonVariant.secondary => (
          palette.surface,
          palette.textPrimary,
          palette.borderEmphasized,
        ),
      AstryxButtonVariant.destructive => (
          palette.errorMuted,
          palette.error,
          palette.error,
        ),
      AstryxButtonVariant.ghost => (
          Colors.transparent,
          palette.textPrimary,
          Colors.transparent,
        ),
    };
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.muted;
        }
        if (states.contains(WidgetState.pressed)) {
          return Color.alphaBlend(palette.overlayPressed, background);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? palette.textDisabled
            : foreground;
      }),
      side: WidgetStatePropertyAll(BorderSide(color: border)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AstryxRadii.element),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700),
      ),
      animationDuration: AstryxMotion.fast,
    );
    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
