import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'presentation/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Ciemny motyw'),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Język'),
              subtitle: Text(locale.languageCode.toUpperCase()),
              onTap: () => ref.read(localeProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}
