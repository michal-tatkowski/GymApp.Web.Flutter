import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/app_routes.dart';
import '../auth/presentation/auth_providers.dart';
import '../settings/presentation/settings_providers.dart';

class HomeMenu extends ConsumerWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);

    final items = <_MenuItem>[
      _MenuItem(Icons.group, t.social, AppRoutes.social),
      _MenuItem(Icons.person, t.profile, AppRoutes.profile),
      _MenuItem(Icons.fitness_center, t.gym, AppRoutes.gym),
      _MenuItem(Icons.notifications, t.notifications, AppRoutes.notifications),
      _MenuItem(Icons.settings, t.settings, AppRoutes.settings),
      _MenuItem(Icons.info, t.info, AppRoutes.info),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymApp'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: items
                    .map((item) => _MenuTile(item: item))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(t.logout),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(item.label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
