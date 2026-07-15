import 'package:flutter/material.dart';

import '../../data/core/transport.dart';
import '../../theme/astryx_palette.dart';
import '../atoms/astryx_badge.dart';
import '../atoms/astryx_status_dot.dart';
import '../atoms/astryx_surface.dart';

/// Molecule that describes one registered transport and its capabilities.
class AstryxProtocolTile extends StatelessWidget {
  const AstryxProtocolTile({required this.adapter, super.key});

  final TransportAdapter adapter;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    return AstryxSurface(
      elevation: AstryxSurfaceElevation.flat,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _category(context).background,
                  border: Border.all(color: _category(context).border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _icon,
                  size: 19,
                  color: _category(context).icon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adapter.protocol.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const AstryxStatusDot(status: AstryxStatus.ready),
            ],
          ),
          const Spacer(),
          Divider(color: palette.border, height: 28),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final capability in adapter.capabilities)
                AstryxBadge(
                  _capabilityLabel(capability),
                  tone: AstryxBadgeTone.categorical,
                  category: _categoryName,
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (adapter.protocol) {
        AstryxProtocol.rest => Icons.swap_horiz_rounded,
        AstryxProtocol.graphql => Icons.hub_outlined,
        AstryxProtocol.sse => Icons.waves_rounded,
        AstryxProtocol.hateoas => Icons.link_rounded,
      };

  String get _description => switch (adapter.protocol) {
        AstryxProtocol.rest => 'Resource requests',
        AstryxProtocol.graphql => 'Typed operations',
        AstryxProtocol.sse => 'Live event stream',
        AstryxProtocol.hateoas => 'Link navigation',
      };

  AstryxCategory get _categoryName => switch (adapter.protocol) {
        AstryxProtocol.rest => AstryxCategory.teal,
        AstryxProtocol.graphql => AstryxCategory.pink,
        AstryxProtocol.sse => AstryxCategory.blue,
        AstryxProtocol.hateoas => AstryxCategory.purple,
      };

  AstryxCategoryColors _category(BuildContext context) =>
      context.astryx.category(_categoryName);

  String _capabilityLabel(TransportCapability value) => switch (value) {
        TransportCapability.requestResponse => 'request / response',
        TransportCapability.streaming => 'streaming',
        TransportCapability.hypermedia => 'hypermedia',
      };
}
