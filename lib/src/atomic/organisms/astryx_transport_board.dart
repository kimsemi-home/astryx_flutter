import 'package:flutter/material.dart';

import '../../data/core/transport.dart';
import '../../theme/astryx_palette.dart';
import '../molecules/astryx_protocol_tile.dart';

/// Organism that lays registered protocol molecules out responsively.
class AstryxTransportBoard extends StatelessWidget {
  const AstryxTransportBoard({required this.adapters, super.key});

  final Iterable<TransportAdapter> adapters;

  @override
  Widget build(BuildContext context) {
    final items = adapters.toList(growable: false);
    if (items.isEmpty) {
      return Text(
        'No transport adapters registered.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.astryx.textSecondary,
            ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 650
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final adapter in items)
              SizedBox(
                width: width,
                height: 184,
                child: AstryxProtocolTile(adapter: adapter),
              ),
          ],
        );
      },
    );
  }
}
