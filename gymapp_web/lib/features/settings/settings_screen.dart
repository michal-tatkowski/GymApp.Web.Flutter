import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/units/weight_unit.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_providers.dart';
import '../gym/workouts/presentation/pending_workouts.dart';
import '../gym/workouts/presentation/rest_alarm.dart';
import '../gym/workouts/presentation/rest_timer.dart';
import 'presentation/reminders.dart';
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
            ListTile(leading: const Icon(Icons.palette_outlined), title: Text(t.theme)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<ThemeMode>(
                key: const Key('settings.theme'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto), label: Text(t.themeSystem)),
                  ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(t.themeLight)),
                  ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(t.themeDark)),
                ],
                selected: {themeMode},
                onSelectionChanged: (v) => ref.read(themeProvider.notifier).set(v.single),
              ),
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.fitness_center), title: Text(t.weightUnit), subtitle: Text(t.weightUnitHint)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<WeightUnit>(
                key: const Key('settings.unit'),
                showSelectedIcon: false,
                segments: [
                  for (final u in WeightUnit.values) ButtonSegment(value: u, label: Text(u.label)),
                ],
                selected: {ref.watch(weightUnitProvider)},
                onSelectionChanged: (v) => ref.read(weightUnitProvider.notifier).set(v.single),
              ),
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
            const _RemindersSection(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(t.logout, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Workouts saved offline belong to this account; logging out drops them, so ask first.
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final pending = ref.read(pendingWorkoutsProvider);
    if (pending.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.logoutPendingTitle),
          content: Text('${t.pendingCount(pending.length)}.\n\n${t.logoutPendingBody}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.logout)),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(pendingWorkoutsProvider.notifier).clear();
    await ref.read(authControllerProvider.notifier).logout();
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

/// "Workout reminders": on/off, then the days and the time.
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  Future<void> _update(BuildContext context, WidgetRef ref, ReminderSettings next) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(remindersProvider.notifier).update(next)) {
      messenger.showSnackBar(SnackBar(content: Text(t.reminderPermissionDenied)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final s = ref.watch(remindersProvider);
    final localizations = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    // Week in the order of the locale (Monday first in Poland, Sunday first in the US).
    final first = localizations.firstDayOfWeekIndex; // 0 = Sunday
    final days = [for (var i = 0; i < 7; i++) (first + i) % 7 == 0 ? DateTime.sunday : (first + i) % 7];
    String dayName(int weekday) => DateFormat.E(locale).format(DateTime(2024, 1, weekday)); // 2024-01-01 is a Monday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('settings.reminders'),
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(t.reminders),
          subtitle: Text(t.remindersHint),
          value: s.enabled,
          onChanged: (on) => _update(context, ref, s.copyWith(enabled: on)),
        ),
        if (s.enabled) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              spacing: 6,
              children: [
                for (final d in days)
                  FilterChip(
                    key: Key('settings.reminders.day$d'),
                    label: Text(dayName(d)),
                    selected: s.weekdays.contains(d),
                    onSelected: (on) => _update(
                      context,
                      ref,
                      s.copyWith(weekdays: on ? {...s.weekdays, d} : ({...s.weekdays}..remove(d))),
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(t.reminderTime),
            trailing: Text(localizations.formatTimeOfDay(s.time), style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: s.time);
              if (picked != null && context.mounted) await _update(context, ref, s.copyWith(time: picked));
            },
          ),
        ],
      ],
    );
  }
}
