import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';
import '../../theme/astryx_tokens.dart';

enum AstryxBadgeTone { neutral, info, success, warning, error, categorical }

/// Atomic semantic or categorical status badge.
class AstryxBadge extends StatelessWidget {
  const AstryxBadge(
    this.label, {
    super.key,
    this.tone = AstryxBadgeTone.neutral,
    this.category = AstryxCategory.gray,
    this.icon,
  });

  const AstryxBadge.info(String label, {Key? key, IconData? icon})
      : this(label, key: key, tone: AstryxBadgeTone.info, icon: icon);

  const AstryxBadge.success(String label, {Key? key, IconData? icon})
      : this(label, key: key, tone: AstryxBadgeTone.success, icon: icon);

  const AstryxBadge.warning(String label, {Key? key, IconData? icon})
      : this(label, key: key, tone: AstryxBadgeTone.warning, icon: icon);

  const AstryxBadge.error(String label, {Key? key, IconData? icon})
      : this(label, key: key, tone: AstryxBadgeTone.error, icon: icon);

  const AstryxBadge.categorical(
    String label, {
    required AstryxCategory category,
    Key? key,
    IconData? icon,
  }) : this(
          label,
          key: key,
          tone: AstryxBadgeTone.categorical,
          category: category,
          icon: icon,
        );

  final String label;
  final AstryxBadgeTone tone;
  final AstryxCategory category;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.$1,
          border: Border.all(color: colors.$2),
          borderRadius: BorderRadius.circular(AstryxRadii.full),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: icon == null ? 10 : 8,
            vertical: 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: colors.$3),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.$3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _colors(BuildContext context) {
    final palette = context.astryx;
    switch (tone) {
      case AstryxBadgeTone.neutral:
        final colors = palette.category(AstryxCategory.gray);
        return (colors.background, colors.border, colors.text);
      case AstryxBadgeTone.info:
        final colors = palette.category(AstryxCategory.blue);
        return (colors.background, colors.border, colors.text);
      case AstryxBadgeTone.success:
        return (palette.successMuted, palette.success, palette.success);
      case AstryxBadgeTone.warning:
        return (palette.warningMuted, palette.warning, palette.warning);
      case AstryxBadgeTone.error:
        return (palette.errorMuted, palette.error, palette.error);
      case AstryxBadgeTone.categorical:
        final colors = palette.category(category);
        return (colors.background, colors.border, colors.text);
    }
  }
}
