import 'package:flutter/material.dart';

import '../../data/core/transport_registry.dart';
import '../../theme/astryx_palette.dart';
import '../../theme/astryx_tokens.dart';
import '../atoms/astryx_badge.dart';
import '../atoms/astryx_button.dart';
import '../atoms/astryx_status_dot.dart';
import '../atoms/astryx_surface.dart';
import '../molecules/astryx_metric_card.dart';
import '../organisms/astryx_transport_board.dart';
import '../templates/astryx_dashboard_template.dart';

/// Package showcase page assembled through all five Atomic Design layers.
class AstryxShowcasePage extends StatefulWidget {
  const AstryxShowcasePage({
    required this.registry,
    super.key,
    this.onToggleBrightness,
  });

  final TransportRegistry registry;
  final VoidCallback? onToggleBrightness;

  @override
  State<AstryxShowcasePage> createState() => _AstryxShowcasePageState();
}

class _AstryxShowcasePageState extends State<AstryxShowcasePage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AstryxDashboardTemplate(
      title: 'Astryx Flutter',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (value) => setState(() => _selectedIndex = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.widgets_outlined),
          selectedIcon: Icon(Icons.widgets_rounded),
          label: 'Atomic UI',
        ),
        NavigationDestination(
          icon: Icon(Icons.integration_instructions_outlined),
          selectedIcon: Icon(Icons.integration_instructions_rounded),
          label: 'Integrate',
        ),
      ],
      actions: [
        if (widget.onToggleBrightness != null)
          IconButton(
            tooltip: 'Toggle brightness',
            onPressed: widget.onToggleBrightness,
            icon: const Icon(Icons.contrast_rounded),
          ),
        const SizedBox(width: 8),
      ],
      child: IndexedStack(
        index: _selectedIndex,
        children: [_overview(), _atomicUi(), _integrate()],
      ),
    );
  }

  Widget _overview() {
    return _ScrollablePage(
      children: [
        _hero(),
        const SizedBox(height: 24),
        Text('Runtime at a glance',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: AstryxMetricCard(
                    label: 'Protocols',
                    value: '${widget.registry.adapters.length}',
                    description: 'One registry, distinct capabilities',
                    icon: Icons.cable_rounded,
                    badge: const AstryxBadge(
                      'ready',
                      tone: AstryxBadgeTone.success,
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const AstryxMetricCard(
                    label: 'Atomic layers',
                    value: '5',
                    description: 'Atoms through production pages',
                    icon: Icons.layers_outlined,
                    badge: AstryxBadge(
                      'composable',
                      tone: AstryxBadgeTone.info,
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: const AstryxMetricCard(
                    label: 'Theme modes',
                    value: '2',
                    description: 'Neutral light and dark token maps',
                    icon: Icons.brightness_6_outlined,
                    badge: AstryxBadge('tokenized'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Transport registry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const AstryxBadge(
              'injected clients',
              tone: AstryxBadgeTone.categorical,
              category: AstryxCategory.teal,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AstryxTransportBoard(adapters: widget.registry.adapters),
      ],
    );
  }

  Widget _hero() {
    return AstryxSurface(
      elevation: AstryxSurfaceElevation.medium,
      radius: AstryxRadii.page,
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AstryxBadge(
                    'agent-ready',
                    tone: AstryxBadgeTone.categorical,
                    category: AstryxCategory.purple,
                    icon: Icons.auto_awesome_rounded,
                  ),
                  AstryxBadge(
                    'v0.1.0',
                    tone: AstryxBadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Atomic UI.\nAny backend shape.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'A Flutter-first Astryx neutral port with explicit adapters '
                'for REST, GraphQL, SSE, and hypermedia navigation.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.astryx.textSecondary,
                    ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AstryxButton(
                    label: 'Explore UI',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => setState(() => _selectedIndex = 1),
                  ),
                  AstryxButton(
                    label: 'Integration',
                    variant: AstryxButtonVariant.secondary,
                    onPressed: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ],
          );
          final signal = Container(
            width: compact ? double.infinity : 220,
            height: 220,
            decoration: BoxDecoration(
              color: context.astryx.muted,
              border: Border.all(color: context.astryx.border),
              borderRadius: BorderRadius.circular(AstryxRadii.container),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final size in [168.0, 116.0, 64.0])
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: context.astryx.borderEmphasized),
                    ),
                  ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: context.astryx.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const Positioned(
                  top: 24,
                  right: 28,
                  child: AstryxStatusDot(
                    status: AstryxStatus.streaming,
                    size: 10,
                  ),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 24), signal],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 32),
              signal,
            ],
          );
        },
      ),
    );
  }

  Widget _atomicUi() {
    return _ScrollablePage(
      children: [
        Text('Atomic UI catalog',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Small semantic primitives compose into backend-aware screens.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.astryx.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        _catalogSection(
          title: 'Atoms · badges',
          child: const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AstryxBadge('neutral'),
              AstryxBadge('info', tone: AstryxBadgeTone.info),
              AstryxBadge('success', tone: AstryxBadgeTone.success),
              AstryxBadge('warning', tone: AstryxBadgeTone.warning),
              AstryxBadge('error', tone: AstryxBadgeTone.error),
              AstryxBadge(
                'teal',
                tone: AstryxBadgeTone.categorical,
                category: AstryxCategory.teal,
              ),
              AstryxBadge(
                'purple',
                tone: AstryxBadgeTone.categorical,
                category: AstryxCategory.purple,
              ),
              AstryxBadge(
                'pink',
                tone: AstryxBadgeTone.categorical,
                category: AstryxCategory.pink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _catalogSection(
          title: 'Atoms · actions',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AstryxButton(label: 'Primary', onPressed: () {}),
              AstryxButton(
                label: 'Secondary',
                variant: AstryxButtonVariant.secondary,
                onPressed: () {},
              ),
              AstryxButton(
                label: 'Destructive',
                variant: AstryxButtonVariant.destructive,
                onPressed: () {},
              ),
              AstryxButton(
                label: 'Ghost',
                variant: AstryxButtonVariant.ghost,
                onPressed: () {},
              ),
              const AstryxButton(label: 'Disabled', onPressed: null),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _catalogSection(
          title: 'Molecules → organisms',
          child: AstryxTransportBoard(adapters: widget.registry.adapters),
        ),
      ],
    );
  }

  Widget _catalogSection({required String title, required Widget child}) {
    return AstryxSurface(
      elevation: AstryxSurfaceElevation.flat,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _integrate() {
    return _ScrollablePage(
      children: [
        Text('One composition root',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Use protocol-specific APIs directly, or route neutral commands '
          'through the registry.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.astryx.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        const _CodePanel(
          title: 'Bootstrap',
          code: r'''final framework = AstryxFramework.standard(
  restBaseUri: Uri.parse('https://api.example.com/'),
  graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
);

final users = await framework.rest.get('/users');
final result = await framework.graphql.execute(
  const GraphqlOperation(document: r'query { viewer { id } }'),
);''',
        ),
        const SizedBox(height: 12),
        const _CodePanel(
          title: 'SSE + HATEOAS',
          code:
              r'''await for (final event in framework.sse.connect('/events')) {
  print(event.decodeJson());
}

final root = await framework.hateoas.send(request);
final document = framework.hateoas.document(root);
final next = await framework.hateoas.follow(document, 'next');''',
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AstryxBadge(
              'self',
              tone: AstryxBadgeTone.categorical,
              category: AstryxCategory.gray,
              icon: Icons.link_rounded,
            ),
            AstryxBadge(
              'next',
              tone: AstryxBadgeTone.categorical,
              category: AstryxCategory.blue,
              icon: Icons.arrow_forward_rounded,
            ),
            AstryxBadge(
              'update',
              tone: AstryxBadgeTone.categorical,
              category: AstryxCategory.orange,
              icon: Icons.edit_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _ScrollablePage extends StatelessWidget {
  const _ScrollablePage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width >= 700 ? 32 : 16,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.title, required this.code});

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    return AstryxSurface(
      elevation: AstryxSurfaceElevation.flat,
      padding: EdgeInsets.zero,
      color: palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
          Divider(height: 1, color: palette.border),
          Container(
            color: palette.muted,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
