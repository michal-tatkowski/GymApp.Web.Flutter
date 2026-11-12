import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/errors/failure_messages.dart';
import '../../core/units/weight_unit.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_providers.dart';
import '../gym/progress/badges.dart';
import '../gym/session/session_providers.dart';
import 'privacy_policy_screen.dart';
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
              key: const Key('settings.privacy'),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(t.privacyPolicy),
              onTap: () => PrivacyPolicyScreen.open(context),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(t.logout, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => _logout(context, ref),
            ),
            ListTile(
              key: const Key('settings.deleteAccount'),
              leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
              title: Text(t.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: Text(t.deleteAccountHint),
              onTap: () => _deleteAccount(context, ref),
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
    await _forgetLocalData(ref);
    await ref.read(authControllerProvider.notifier).logout();
  }

  /// The password dialog calls the API itself, so a wrong password is shown
  /// in place and the user can retry without starting over.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (deleted == true) await _forgetLocalData(ref);
  }

  /// What this device keeps for the signed-in account: the offline queue,
  /// an unfinished session and earned badges. Device settings (theme, unit, reminders) stay.
  static Future<void> _forgetLocalData(WidgetRef ref) async {
    await ref.read(pendingWorkoutsProvider.notifier).clear();
    if (ref.read(activeSessionProvider) != null) ref.read(activeSessionProvider.notifier).discard();
    await ref.read(earnedBadgesProvider.notifier).clear();
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(AppLocalizations.of(context)!, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pending = ref.watch(pendingWorkoutsProvider);
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: error),
      title: Text(t.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.deleteAccountBody),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${t.pendingCount(pending.length)}. ${t.logoutPendingBody}'),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('deleteAccount.password'),
              controller: _password,
              obscureText: true,
              autofocus: true,
              enabled: !_busy,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: t.deleteAccountPassword, errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(t.cancel)),
        FilledButton(
          key: const Key('deleteAccount.confirm'),
          style: FilledButton.styleFrom(backgroundColor: error, foregroundColor: Theme.of(context).colorScheme.onError),
          onPressed: _busy || _password.text.isEmpty ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.deleteAccountConfirm),
        ),
      ],
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
