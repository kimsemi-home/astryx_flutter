import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';
import '../../theme/astryx_tokens.dart';

enum AstryxSurfaceElevation { flat, low, medium, high }

/// Atomic bordered surface used by cards, popovers, and page sections.
class AstryxSurface extends StatelessWidget {
  const AstryxSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevation = AstryxSurfaceElevation.low,
    this.radius = AstryxRadii.container,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final AstryxSurfaceElevation elevation;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    final surface = AnimatedContainer(
      duration: AstryxMotion.fast,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _shadows(context, palette),
      ),
      child: child,
    );
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: surface,
      ),
    );
  }

  List<BoxShadow> _shadows(BuildContext context, AstryxPalette palette) {
    if (elevation == AstryxSurfaceElevation.flat) return const [];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final values = switch (elevation) {
      AstryxSurfaceElevation.flat => (0.0, 0.0, 0.0),
      AstryxSurfaceElevation.low => (4.0, 8.0, dark ? 0.32 : 0.08),
      AstryxSurfaceElevation.medium => (8.0, 18.0, dark ? 0.42 : 0.10),
      AstryxSurfaceElevation.high => (14.0, 28.0, dark ? 0.58 : 0.14),
    };
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: values.$3),
        blurRadius: values.$2,
        offset: Offset(0, values.$1),
      ),
      if (dark)
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.08),
          blurRadius: 0,
          spreadRadius: -0.25,
        ),
    ];
  }
}
