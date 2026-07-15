import 'package:flutter/material.dart';

import '../../theme/astryx_palette.dart';

/// Responsive page template with a rail on large screens and bottom nav below.
class AstryxDashboardTemplate extends StatelessWidget {
  const AstryxDashboardTemplate({
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
    this.actions = const [],
  });

  final String title;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.astryx;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: palette.onAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            backgroundColor: palette.card,
            surfaceTintColor: Colors.transparent,
            actions: actions,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: palette.border),
            ),
          ),
          body: Row(
            children: [
              if (wide) ...[
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: palette.card,
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon ?? item.icon,
                        label: Text(item.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: palette.border),
              ],
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: destinations,
                  backgroundColor: palette.card,
                ),
        );
      },
    );
  }
}
