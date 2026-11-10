import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/workout_models.dart';
import 'widgets/progress_chart.dart';
import 'rest_timer.dart';
import 'widgets/workout_entry_sheet.dart';
import 'workout_providers.dart';

/// Training log of one exercise: progress chart, "Log workout", history.
class ExerciseWorkoutsScreen extends ConsumerWidget {
  const ExerciseWorkoutsScreen({super.key, required this.exerciseId, required this.exerciseName});

  final String exerciseId;
  final String exerciseName;

  static Future<void> openEntrySheet(
    BuildContext context,
    WidgetRef ref,
    String exerciseId, {
    WorkoutEntry? entry,
    List<WorkoutSet>? prefill,
  }) {
    final actions = WorkoutActions.of(context);
    final timer = ref.read(restTimerProvider.notifier);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => WorkoutEntrySheet(
        initial: entry,
        prefillSets: prefill,
        onSave: (req) async {
          if (entry != null) {
            await actions.edit(exerciseId, entry.id, req);
            return;
          }
          await actions.add(exerciseId, req);
          timer.startAfterSet();
        },
      ),
    );
  }

  /// One tap: saves [sets] for today, starts the rest timer, offers "Undo".
  static Future<void> repeatLast(BuildContext context, WidgetRef ref, String exerciseId, List<WorkoutSet> sets) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = WorkoutActions.of(context);
    final timer = ref.read(restTimerProvider.notifier);
    try {
      final created = await actions.add(
        exerciseId,
        WorkoutEntryRequest(date: DateUtils.dateOnly(DateTime.now()), sets: sets),
      );
      timer.startAfterSet();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.workoutSaved),
            action: SnackBarAction(label: t.undo, onPressed: () => actions.delete(exerciseId, created.id)),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  /// "3 × 10 × 100 kg" when all sets are equal, otherwise "10×100, 10×100, 8×105 kg".
  static String describeSets(List<WorkoutSet> sets) {
    String one(WorkoutSet s) => s.weight == 0 ? '${s.reps}' : '${s.reps}×${formatValue(s.weight)}';
    if (sets.length > 1 && sets.every((s) => s == sets.first)) {
      final s = sets.first;
      return s.weight == 0 ? '${sets.length} × ${s.reps}' : '${sets.length} × ${s.reps} × ${formatValue(s.weight)} kg';
    }
    final text = sets.map(one).join(', ');
    return sets.any((s) => s.weight > 0) ? '$text kg' : text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final logAsync = ref.watch(workoutLogProvider(exerciseId));
    final progressAsync = ref.watch(workoutProgressProvider(exerciseId));
    final lastSets = logAsync.value?.entries.firstOrNull?.sets;

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('workout.log'),
        onPressed: logAsync.hasValue ? () => openEntrySheet(context, ref, exerciseId, prefill: lastSets) : null,
        icon: const Icon(Icons.add),
        label: Text(t.logWorkout),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: logAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                ErrorView(message: describeError(t, e), onRetry: () => ref.invalidate(workoutLogProvider(exerciseId))),
            data: (log) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.progress, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        progressAsync.when(
                          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                          error: (e, _) => SizedBox(height: 80, child: Center(child: Text(describeError(t, e)))),
                          data: (points) => ProgressChart(points: points),
                        ),
                      ],
                    ),
                  ),
                ),
                if (lastSets != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('workout.repeat'),
                    onPressed: () => repeatLast(context, ref, exerciseId, lastSets),
                    icon: const Icon(Icons.replay),
                    label: Text(t.repeatLast(describeSets(lastSets))),
                  ),
                ],
                const SizedBox(height: 16),
                Text(t.workoutHistory, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (log.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text(t.noEntriesForExercise)),
                  ),
                for (final entry in log.entries) _EntryTile(exerciseId: exerciseId, entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.exerciseId, required this.entry});

  final String exerciseId;
  final WorkoutEntry entry;

  static String describeSets(List<WorkoutSet> sets) => ExerciseWorkoutsScreen.describeSets(sets);

  /// Deletes right away and offers "Undo" (re-creates the entry) — no confirmation
  /// dialog: the action is reversible, so it should not interrupt.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = WorkoutActions.of(context);
    try {
      await actions.delete(exerciseId, entry.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.entryDeleted),
            action: SnackBarAction(
              label: t.undo,
              onPressed: () =>
                  actions.add(exerciseId, WorkoutEntryRequest(date: entry.date, sets: entry.sets, notes: entry.notes)),
            ),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final bodyweight = entry.volume == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(DateFormat.yMMMEd(locale).format(entry.date)),
        subtitle: Text([describeSets(entry.sets), if (entry.notes != null) entry.notes!].join('\n')),
        isThreeLine: entry.notes != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bodyweight ? t.repsValue(entry.totalReps) : t.volumeValue(formatValue(entry.volume)),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
        onTap: () => ExerciseWorkoutsScreen.openEntrySheet(context, ref, exerciseId, entry: entry),
      ),
    );
  }
}
