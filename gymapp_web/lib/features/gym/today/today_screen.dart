import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../exercises/presentation/exercises_providers.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/exercise_workouts_screen.dart';
import '../workouts/presentation/widgets/progress_chart.dart';
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
      final log = await ref.read(workoutLogProvider(exercise.id).future);
      if (!context.mounted) return;
      await ExerciseWorkoutsScreen.openEntrySheet(context, ref, exercise.id,
          prefill: log.entries.firstOrNull?.sets);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(t, e))));
      }
    } finally {
      keepAlive.close();
    }
  }

  void _openLog(BuildContext context, String id, String name) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ExerciseWorkoutsScreen(exerciseId: id, exerciseName: name)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
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
          await ref.read(favoriteExercisesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Done today ─────────────────────────────────────────────
            if (doneToday.isNotEmpty) ...[
              _SectionTitle(t.doneToday),
              Card(
                child: Column(
                  children: [
                    for (final s in doneToday)
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(s.exerciseName),
                        trailing: Text(
                          s.lastVolume == 0 ? t.repsValue(s.lastTotalReps) : t.volumeValue(formatValue(s.lastVolume)),
                          style: theme.textTheme.labelLarge,
                        ),
                        onTap: () => _openLog(context, s.exerciseId, s.exerciseName),
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
                            Icon(Icons.star_border, size: 40, color: Colors.amber.shade700),
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
                              locale: locale,
                              onOpen: () => _openLog(context, e.id, e.name),
                              onLog: () => _quickLog(context, ref, e),
                            ),
                        ],
                      ),
                    ),
            ),
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
    required this.locale,
    required this.onOpen,
    required this.onLog,
  });

  final Exercise exercise;
  final WorkoutSummary? summary;
  final String locale;
  final VoidCallback onOpen;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final s = summary;
    return ListTile(
      leading: Icon(categoryIcon(exercise.category)),
      title: Text(exercise.name),
      subtitle: Text(s == null
          ? t.notTrainedYet
          : '${t.lastWorkout(DateFormat.MMMd(locale).format(s.lastDate))} · '
              '${s.lastVolume == 0 ? t.repsValue(s.lastTotalReps) : t.volumeValue(formatValue(s.lastVolume))}'),
      trailing: IconButton.filledTonal(
        key: Key('today.log.${exercise.id}'),
        tooltip: t.logWorkout,
        icon: const Icon(Icons.add),
        onPressed: onLog,
      ),
      onTap: onOpen,
    );
  }
}
