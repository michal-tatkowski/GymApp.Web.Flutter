import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_providers.dart';
import '../gym/workouts/presentation/rest_alarm.dart';
import '../gym/workouts/presentation/rest_timer.dart';
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
              title: Text(t.darkTheme),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(t.language),
              subtitle: Text(locale.languageCode.toUpperCase()),
              onTap: () => ref.read(localeProvider.notifier).toggle(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(t.restTimer),
              subtitle: Text(t.restTimerHint),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<int>(
                key: const Key('settings.rest'),
                showSelectedIcon: false,
                segments: [
                  for (final s in restTimerOptions)
                    ButtonSegment(
                      value: s,
                      label: Text(s == 0 ? t.off : formatRest(Duration(seconds: s))),
                    ),
                ],
                selected: {ref.watch(restDurationProvider)},
                onSelectionChanged: (v) => ref.read(restDurationProvider.notifier).set(v.single),
              ),
            ),
            const _ExactAlarmTile(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(t.logout, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown only when Android does not allow exact alarms (Android 14 asks the
/// user): without them the end-of-rest alert can come late while the phone is
/// locked. Re-checked when the user comes back from the system settings.
class _ExactAlarmTile extends ConsumerStatefulWidget {
  const _ExactAlarmTile();

  @override
  ConsumerState<_ExactAlarmTile> createState() => _ExactAlarmTileState();
}

class _ExactAlarmTileState extends ConsumerState<_ExactAlarmTile> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: _check);
  bool _onTime = true;

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final onTime = await ref.read(restAlarmProvider).canAlertOnTime();
    if (mounted && onTime != _onTime) setState(() => _onTime = onTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_onTime || ref.watch(restDurationProvider) == 0) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(t.restExactAlarm),
      subtitle: Text(t.restExactAlarmHint),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => ref.read(restAlarmProvider).openExactAlarmSettings(),
    );
  }
}
