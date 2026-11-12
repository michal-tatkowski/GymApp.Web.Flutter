import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/storage/secure_storage_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/reminders.dart';
import '../goals/goals_data.dart';
import '../plans/data/plan_models.dart';
import '../plans/presentation/plan_providers.dart';
import '../workouts/presentation/workout_providers.dart';

enum TrainingGoal { strength, muscle, fitness, fatLoss }

enum TrainingPlace { gym, home }

/// Ready-made plans (api/Plans/templates keys) for the answers:
/// home → bodyweight circuit; gym 2–3 days → 5×5 for strength, full body otherwise;
/// 4 days → upper/lower; 5–6 days → push/pull/legs.
List<String> recommendTemplates(TrainingGoal goal, TrainingPlace place, int daysPerWeek) {
  if (place == TrainingPlace.home) return const ['home-bodyweight'];
  if (daysPerWeek <= 3) return [goal == TrainingGoal.strength ? 'five-by-five' : 'fbw-beginner'];
  if (daysPerWeek == 4) return const ['upper', 'lower'];
  return const ['push', 'pull', 'legs'];
}

/// Training days spread over the week (DateTime.monday = 1 …) for the reminders.
Set<int> spreadDays(int daysPerWeek) => switch (daysPerWeek) {
      <= 2 => {DateTime.monday, DateTime.thursday},
      3 => {DateTime.monday, DateTime.wednesday, DateTime.friday},
      4 => {DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday},
      5 => {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday},
      _ => {DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday},
    };

/// Shown once per account on this phone; cleared on logout like other account data.
Future<bool> onboardingDone() async => (await SharedPreferences.getInstance()).getBool(StorageKeys.onboardingDone) ?? false;

Future<void> markOnboardingDone() async => (await SharedPreferences.getInstance()).setBool(StorageKeys.onboardingDone, true);

/// Three questions → a ready-made plan (or a split of 2–3 plans), a weekly goal and
/// optional reminders. "Skip" at any time.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  TrainingGoal? _goal;
  TrainingPlace? _place;
  int _days = 3;
  bool _reminders = true;
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  Future<void> _skip() async {
    final navigator = Navigator.of(context);
    await markOnboardingDone();
    navigator.pop();
  }

  Future<void> _finish(List<PlanTemplate> templates) async {
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      for (final template in templates) {
        await ref.read(planActionsProvider).save(null, PlanRequest(name: template.name, items: template.items));
      }
      await ref.read(goalRepositoryProvider).create(Goal(id: '', kind: GoalKind.weeklyWorkouts, target: _days.toDouble()));
      ref.invalidate(goalsProvider);
      if (_reminders) {
        final current = ref.read(remindersProvider);
        await ref.read(remindersProvider.notifier).update(current.copyWith(enabled: true, weekdays: spreadDays(_days)));
      }
      await markOnboardingDone();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.onboardingReady)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget question(String title, List<(String, IconData, VoidCallback, bool)> options) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final (label, icon, onTap, selected) in options)
              Card(
                color: selected ? theme.colorScheme.primaryContainer : null,
                child: ListTile(leading: Icon(icon), title: Text(label), selected: selected, onTap: onTap),
              ),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.onboardingTitle),
        automaticallyImplyLeading: false,
        actions: [TextButton(key: const Key('onboarding.skip'), onPressed: _saving ? null : _skip, child: Text(t.skip))],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / 4),
          Expanded(
            child: PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(), // forward by answering, back with the button
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                question(t.onboardingGoal, [
                  for (final (g, label, icon) in [
                    (TrainingGoal.strength, t.goalStrength, Icons.fitness_center),
                    (TrainingGoal.muscle, t.goalMuscle, Icons.accessibility_new),
                    (TrainingGoal.fitness, t.goalFitness, Icons.directions_run),
                    (TrainingGoal.fatLoss, t.goalFatLoss, Icons.local_fire_department_outlined),
                  ])
                    (label, icon, () {
                      setState(() => _goal = g);
                      _next();
                    }, _goal == g),
                ]),
                question(t.onboardingPlace, [
                  (t.placeGym, Icons.store_mall_directory_outlined, () {
                    setState(() => _place = TrainingPlace.gym);
                    _next();
                  }, _place == TrainingPlace.gym),
                  (t.placeHome, Icons.home_outlined, () {
                    setState(() => _place = TrainingPlace.home);
                    _next();
                  }, _place == TrainingPlace.home),
                ]),
                ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(t.onboardingDays, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    SegmentedButton<int>(
                      key: const Key('onboarding.days'),
                      showSelectedIcon: false,
                      segments: [for (var d = 2; d <= 6; d++) ButtonSegment(value: d, label: Text('$d'))],
                      selected: {_days},
                      onSelectionChanged: (v) => setState(() => _days = v.single),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(key: const Key('onboarding.daysNext'), onPressed: _next, child: Text(t.sessionNext)),
                  ],
                ),
                _Recommendation(
                  templateKeys: _goal == null || _place == null ? const [] : recommendTemplates(_goal!, _place!, _days),
                  days: _days,
                  reminders: _reminders,
                  saving: _saving,
                  onReminders: (v) => setState(() => _reminders = v),
                  onAccept: _finish,
                ),
              ],
            ),
          ),
          if (_page > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: _saving ? null : () => _pages.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(t.sessionPrevious),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Recommendation extends ConsumerWidget {
  const _Recommendation({
    required this.templateKeys,
    required this.days,
    required this.reminders,
    required this.saving,
    required this.onReminders,
    required this.onAccept,
  });

  final List<String> templateKeys;
  final int days;
  final bool reminders;
  final bool saving;
  final ValueChanged<bool> onReminders;
  final void Function(List<PlanTemplate>) onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final all = ref.watch(planTemplatesProvider);
    return all.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(describeError(t, e)))),
      data: (templates) {
        final chosen = [for (final key in templateKeys) ...templates.where((x) => x.key == key)];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(t.onboardingPlanTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(chosen.length > 1 ? t.onboardingSplitHint(chosen.length) : t.onboardingPlanHint),
            const SizedBox(height: 12),
            for (final template in chosen)
              Card(
                key: Key('onboarding.plan.${template.key}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name, style: theme.textTheme.titleMedium),
                      Text(template.description, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      for (final i in template.items) Text('• ${i.exerciseName} · ${i.target}'),
                    ],
                  ),
                ),
              ),
            SwitchListTile(
              key: const Key('onboarding.reminders'),
              contentPadding: EdgeInsets.zero,
              value: reminders,
              onChanged: onReminders,
              title: Text(t.onboardingReminders),
              subtitle: Text(t.onboardingRemindersHint(days)),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('onboarding.accept'),
              onPressed: saving || chosen.isEmpty ? null : () => onAccept(chosen),
              icon: const Icon(Icons.check),
              label: Text(t.onboardingAccept),
            ),
          ],
        );
      },
    );
  }
}

/// Off in widget tests that are not about the onboarding (an empty test account would get it).
final onboardingEnabledProvider = Provider<bool>((ref) => true);

/// Invisible, on Today: opens the onboarding once for a new account — no plans and
/// no workouts yet. An account that already has either is marked done silently.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key});

  /// One check per app run (Today rebuilds often).
  static bool checked = false;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  @override
  Widget build(BuildContext context) {
    if (!ref.watch(onboardingEnabledProvider)) return const SizedBox.shrink();
    final plans = ref.watch(plansProvider);
    final stats = ref.watch(workoutStatsProvider);
    if (!OnboardingGate.checked && plans.hasValue && stats.hasValue) {
      OnboardingGate.checked = true;
      final fresh = plans.value!.isEmpty && stats.value!.days.isEmpty;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (await onboardingDone() || !mounted) return;
        if (!fresh) return markOnboardingDone();
        if (mounted) {
          await Navigator.of(this.context)
              .push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen(), fullscreenDialog: true));
        }
      });
    }
    return const SizedBox.shrink();
  }
}
