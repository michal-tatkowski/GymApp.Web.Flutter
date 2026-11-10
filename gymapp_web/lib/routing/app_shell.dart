import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Main layout after login: bottom NavigationBar on phones, NavigationRail on
/// wide screens (≥ 840 dp, Material 3 "expanded" width). Each tab keeps its own
/// navigation stack (StatefulShellRoute), so switching tabs does not lose the
/// screen you were on.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const wideBreakpoint = 840.0;

  void _select(int index) => navigationShell.goBranch(
        index,
        // Tapping the active tab again goes back to its first screen.
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final destinations = [
      (Icons.today_outlined, Icons.today, t.today),
      (Icons.fitness_center_outlined, Icons.fitness_center, t.exercises),
      (Icons.show_chart_outlined, Icons.show_chart, t.progress),
      (Icons.person_outline, Icons.person, t.profile),
    ];

    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
