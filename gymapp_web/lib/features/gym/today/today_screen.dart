import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../exercises/presentation/exercises_providers.dart';
import '../plans/presentation/plan_providers.dart';
import '../plans/presentation/plans_section.dart';
import '../session/session_providers.dart';
import '../session/session_screen.dart';
import '../workouts/data/workout_models.dart';
import 'week_summary.dart';
import '../workouts/presentation/exercise_workouts_screen.dart';
import '../workouts/presentation/pending_workouts.dart';
import '../goals/goals_card.dart';
import '../progress/compare_challenges.dart';
import '../onboarding/onboarding.dart';
import '../history/history_screen.dart';
import '../workouts/presentation/workout_providers.dart';

/// Start tab: quick log from favorites + what was done today.
/// Designed for use at the gym: one tap on "+" opens the form prefilled with
/// the last workout of that exercise.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static bool _isToday(DateTime d) => DateUtils.isSameDay(d, DateTime.now());

  Future<void> _quickLog(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final t = AppLocalizations.of(context)!;
    // Nothing on this screen watches the exercise's log, so keep it alive while the
    // sheet is open — otherwise Riverpod disposes it mid-save and the refresh of
    // "Done today" / the chart never happens.
    final keepAlive = ref.listenManual(workoutLogProvider(exercise.id), (_, __) {});
    try {
      List<WorkoutSet>? prefill = _lastQueued(ref, exercise.id);
      try {
        prefill ??= (await ref.read(workoutLogProvider(exercise.id).future)).entries.firstOrNull?.sets;
      } catch (e) {
        // Offline the form still opens (empty, or with what was logged offline);
        // the workout then goes to the queue.
        if (!isOfflineFailure(e)) rethrow;
      }
      if (!context.mounted) return;
      await ExerciseWorkoutsScreen.openEntrySheet(context, ref, exercise.id, prefill: prefill, tracking: exercise.tracking);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(t, e))));
      }
    } finally {
      keepAlive.close();
    }
  }

  /// One tap: the last workout of this exercise again, today (with "Undo").
  Future<void> _repeat(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final keepAlive = ref.listenManual(workoutLogProvider(exercise.id), (_, __) {});
    try {
      var sets = _lastQueued(ref, exercise.id);
      try {
        sets ??= (await ref.read(workoutLogProvider(exercise.id).future)).entries.firstOrNull?.sets;
      } catch (e) {
        if (!isOfflineFailure(e)) rethrow;
      }
      if (sets != null && context.mounted) {
        await ExerciseWorkoutsScreen.repeatLast(context, ref, exercise.id, sets);
      }
    } finally {
      keepAlive.close();
    }
  }

  /// Sets of the newest workout of [exerciseId] still waiting in the offline queue.
  static List<WorkoutSet>? _lastQueued(WidgetRef ref, String exerciseId) =>
      ref.read(pendingWorkoutsProvider).where((p) => p.exerciseId == exerciseId).lastOrNull?.request.sets;

  /// [exercise] when known (favorites) — the screen then also shows the star and description.
  void _openLog(BuildContext context, String id, String name, [Exercise? exercise]) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExerciseWorkoutsScreen(exerciseId: id, exerciseName: name, exercise: exercise),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final weights = ref.watch(weightFormatProvider);
    final session = ref.watch(activeSessionProvider);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final favorites = ref.watch(favoriteExercisesProvider);
    final summaries = ref.watch(workoutSummariesProvider);
    final byExercise = {for (final s in summaries.value ?? <WorkoutSummary>[]) s.exerciseId: s};
    final doneToday = (summaries.value ?? <WorkoutSummary>[]).where((s) => _isToday(s.lastDate)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.today),
            Text(DateFormat.MMMMEEEEd(locale).format(DateTime.now()), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteExercisesProvider);
          ref.invalidate(workoutSummariesProvider);
          ref.invalidate(plansProvider);
          ref.invalidate(workoutStatsProvider);
          ref.invalidate(challengesProvider);
          await ref.read(favoriteExercisesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Workout in progress ────────────────────────────────────
            if (session != null)
              Card(
                key: const Key('today.session'),
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(t.sessionActive(
                    session.planName,
                    session.exercises.where((e) => e.saved || e.allDone).length,
                    session.exercises.length,
                  )),
                  trailing: FilledButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SessionScreen())),
                    child: Text(t.sessionResume),
                  ),
                ),
              ),

            const OnboardingGate(),
            // ── This week ──────────────────────────────────────────────
            const WeekSummaryCard(),
            const GoalsCard(),

            // ── Plans ──────────────────────────────────────────────────
            PlansSection(onStart: (plan) => startSession(context, ref, plan)),
            if (session == null) const RepeatLastCard(),
            const SizedBox(height: 8),

            // ── Done today ─────────────────────────────────────────────
            if (doneToday.isNotEmpty) ...[
              _SectionTitle(t.doneToday),
              Card(
                child: Column(
                  children: [
                    for (final s in doneToday)
                      ListTile(
                        leading: Icon(Icons.check_circle, color: context.appColors.success),
                        title: Text(s.exerciseName),
                        trailing: Text(
                          s.lastVolume == 0 ? t.repsValue(s.lastTotalReps) : weights.withUnit(s.lastVolume),
                          style: theme.textTheme.labelLarge,
                        ),
                        onTap: () => _openLog(
                          context,
                          s.exerciseId,
                          s.exerciseName,
                          favorites.value?.where((e) => e.id == s.exerciseId).firstOrNull,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Quick log from favorites ───────────────────────────────
            _SectionTitle(t.quickLog),
            favorites.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
                  title: Text(describeError(t, e)),
                  trailing: TextButton(
                    onPressed: () => ref.invalidate(favoriteExercisesProvider),
                    child: Text(t.retry),
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.star_border, size: 40, color: context.appColors.favorite),
                            const SizedBox(height: 8),
                            Text(t.noFavoritesYet, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () => context.go(AppRoutes.exercises),
                              child: Text(t.browseExercises),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Card(
                      child: Column(
                        children: [
                          for (final e in items)
                            _QuickLogTile(
                              exercise: e,
                              summary: byExercise[e.id],
                              historyKnown: summaries.hasValue,
                              weights: weights,
                              locale: locale,
                              onOpen: () => _openLog(context, e.id, e.name, e),
                              onLog: () => _quickLog(context, ref, e),
                              onRepeat: () => _repeat(context, ref, e),
                            ),
                        ],
                      ),
                    ),
            ),

            // ── Monthly challenges ─────────────────────────────────────
            const SizedBox(height: 16),
            const ChallengesCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _QuickLogTile extends StatelessWidget {
  const _QuickLogTile({
    required this.exercise,
    required this.summary,
    required this.historyKnown,
    required this.weights,
    required this.locale,
    required this.onOpen,
    required this.onLog,
    required this.onRepeat,
  });

  final Exercise exercise;
  final WorkoutSummary? summary;

  /// False while offline: no summary does not mean "not trained yet".
  final bool historyKnown;
  final WeightFormat weights;
  final String locale;
  final VoidCallback onOpen;
  final VoidCallback onLog;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final s = summary;
    return ListTile(
      leading: Icon(categoryIcon(exercise.category)),
      title: Text(exercise.name),
      subtitle: s == null
          ? (historyKnown ? Text(t.notTrainedYet) : null)
          : Text(
              '${t.lastWorkout(DateFormat.MMMd(locale).format(s.lastDate))} · '
              '${s.lastVolume == 0 ? t.repsValue(s.lastTotalReps) : weights.withUnit(s.lastVolume)}',
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s != null)
            IconButton(
              key: Key('today.repeat.${exercise.id}'),
              tooltip: t.repeatLastShort,
              icon: const Icon(Icons.replay),
              onPressed: onRepeat,
            ),
          IconButton.filledTonal(
            key: Key('today.log.${exercise.id}'),
            tooltip: t.logWorkout,
            icon: const Icon(Icons.add),
            onPressed: onLog,
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}
