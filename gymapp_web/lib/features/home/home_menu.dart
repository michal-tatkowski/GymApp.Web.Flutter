import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../providers/providers.dart';
import '../../routing/routes.dart';
import '../../services/jwt_token_service.dart';

class HomeMenu extends ConsumerStatefulWidget {
  const HomeMenu({super.key});

  @override
  ConsumerState<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends ConsumerState<HomeMenu> {
  @override
  void dispose() {
    super.dispose();
  }

  void logout() {
    JwtTokenService.instance.clearToken();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final items = [
      {'icon': Icons.home, 'label': 'Centrum', 'route': TRoutes.login},
      {'icon': Icons.person, 'label': 'Profil', 'route': TRoutes.login},
      {'icon': Icons.fitness_center, 'label': AppLocalizations.of(context)!.gym, 'route': TRoutes.login},
      {'icon': Icons.notifications, 'label': AppLocalizations.of(context)!.settings, 'route': TRoutes.login},
      {'icon': Icons.settings, 'label': 'Ustawienia', 'route': TRoutes.settings},
      {'icon': Icons.info, 'label': 'Info', 'route': TRoutes.login},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymAppWeb'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: items.map((item) {
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        final route = item['route'] as String?;
                        if (route != null) {
                          navigationService.navigateTo(route);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 48,
                            color: const Color(0xFFEF6C00),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['label'] as String,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Wyloguj'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
