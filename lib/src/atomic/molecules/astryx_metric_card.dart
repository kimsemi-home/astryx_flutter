import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';
import '../atoms/astryx_badge.dart';
import '../atoms/astryx_surface.dart';

/// Molecule combining a label, metric, helper copy, and optional status.
class AstryxMetricCard extends StatelessWidget {
  const AstryxMetricCard({
    required this.label,
    required this.value,
    required this.description,
    super.key,
    this.badge,
    this.icon,
  });

  final String label;
  final String value;
  final String description;
  final AstryxBadge? badge;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    return AstryxSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: palette.textSecondary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ),
              if (badge != null) badge!,
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
