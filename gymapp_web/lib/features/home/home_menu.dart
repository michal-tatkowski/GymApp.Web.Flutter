import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/jwt_token_service.dart';
import '../../services/theme_service.dart';

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
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
    final items = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.person, 'label': 'Profile'},
      {'icon': Icons.message, 'label': 'Messages'},
      {'icon': Icons.notifications, 'label': 'Alerts'},
      {'icon': Icons.settings, 'label': 'Settings'},
      {'icon': Icons.info, 'label': 'About'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymAppWeb'),
        automaticallyImplyLeading: false,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, ThemeMode currentMode, __) {
              return IconButton(
                icon: Icon(
                  themeNotifier.value == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () {
                  final newMode = themeNotifier.value == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                  ThemeService.saveTheme(newMode);
                },
              );
            },
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
                        final label = item['label'] as String;
                        switch (label) {
                          case 'Home':
                            Navigator.pushNamed(context, '/login');
                            break;
                          case 'Profile':
                            Navigator.pushNamed(context, '/profile');
                            break;
                          case 'Settings':
                            Navigator.pushNamed(context, '/settings');
                            break;
                          case 'Messages':
                            Navigator.pushNamed(context, '/messages');
                            break;
                          case 'Alerts':
                            Navigator.pushNamed(context, '/alerts');
                            break;
                          case 'About':
                            Navigator.pushNamed(context, '/about');
                            break;
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
