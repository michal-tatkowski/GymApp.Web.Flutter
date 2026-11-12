import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/errors/failure_messages.dart';
import '../../../core/units/weight_unit.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../plans/data/plan_models.dart';
import '../session/session_screen.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/exercise_workouts_screen.dart';
import '../workouts/presentation/workout_providers.dart';

/// The day's exercises as a one-off plan: same exercises, same number of sets, the reps
/// that were done as the target range. Starting it fills the sets from that workout.
WorkoutPlan planFromDay(TrainingDayDetails day, String name) => WorkoutPlan(
      id: '',
      name: name,
      items: [
        for (final e in day.exercises)
          PlanItem(
            exerciseId: e.exerciseId,
            exerciseName: e.exerciseName,
            category: e.category,
            tracking: e.tracking,
            sets: e.sets.length.clamp(1, kPlanMaxSets),
            repsMin: e.sets.map((s) => s.reps).fold(kPlanMaxReps, (a, b) => b < a ? b : a).clamp(1, kPlanMaxReps),
            repsMax: e.sets.map((s) => s.reps).fold(1, (a, b) => b > a ? b : a).clamp(1, kPlanMaxReps),
          ),
      ],
    );

/// Name for a repeated workout: the session's plan name, else "Workout of 12 Nov".
String repeatName(BuildContext context, TrainingDayDetails day) {
  final t = AppLocalizations.of(context)!;
  final session = day.sessions.firstOrNull;
  return session?.name ?? t.workoutOfDay(DateFormat.MMMd(Localizations.localeOf(context).toString()).format(day.date));
}

Future<void> repeatWorkout(BuildContext context, WidgetRef ref, TrainingDayDetails day) =>
    startSession(context, ref, planFromDay(day, repeatName(context, day)));

/// Training history: one card per day (newest first) with the exercises and sets,
/// the session's duration, and "Repeat".
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final history = ref.watch(trainingDaysProvider);
    final weights = ref.watch(weightFormatProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.history)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: describeError(t, e), onRetry: () => ref.invalidate(trainingDaysProvider)),
        data: (h) => RefreshIndicator(
          onRefresh: () => ref.refresh(trainingDaysProvider.future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: h.days.length + 1,
            itemBuilder: (context, i) {
              if (i == h.days.length) {
                if (!h.hasMore) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(h.days.isEmpty ? t.historyEmpty : t.historyEnd, textAlign: TextAlign.center),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: h.loadingMore
                        ? const CircularProgressIndicator()
                        : OutlinedButton.icon(
                            key: const Key('history.more'),
                            onPressed: () => ref.read(trainingDaysProvider.notifier).loadMore().catchError((Object e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(t, e))));
                              }
                            }),
                            icon: const Icon(Icons.expand_more),
                            label: Text(t.historyLoadMore),
                          ),
                  ),
                );
              }
              final day = h.days[i];
              final newMonth = i == 0 || h.days[i - 1].date.month != day.date.month || h.days[i - 1].date.year != day.date.year;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (newMonth)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
                      child: Text(
                        DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(day.date),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  HistoryDayCard(day: day, weights: weights),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class HistoryDayCard extends ConsumerWidget {
  const HistoryDayCard({super.key, required this.day, required this.weights});

  final TrainingDayDetails day;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final session = day.sessions.firstOrNull;
    final minutes = day.sessions.fold(Duration.zero, (d, s) => d + s.duration).inMinutes;

    return Card(
      key: Key('history.day.${toApiDate(day.date)}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.MMMMEEEEd(locale).format(day.date), style: theme.textTheme.titleMedium),
                      Text(
                        [
                          ?session?.name,
                          if (minutes > 0) t.durationMinutes(minutes),
                          t.setsCount(day.sets),
                          if (day.volumeKg > 0) weights.withUnit(day.volumeKg),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: Key('history.repeat.${toApiDate(day.date)}'),
                  onPressed: () => repeatWorkout(context, ref, day),
                  icon: const Icon(Icons.replay),
                  label: Text(t.repeatWorkout),
                ),
              ],
            ),
            const Divider(),
            for (final e in day.exercises)
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ExerciseWorkoutsScreen(exerciseId: e.exerciseId, exerciseName: e.exerciseName),
                )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(categoryIcon(e.category), size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.exerciseName, style: theme.textTheme.bodyLarge),
                            Text(
                              ExerciseWorkoutsScreen.describeSets(e.sets, weights),
                              style: theme.textTheme.bodySmall,
                            ),
                            for (final note in [
                              ...e.entries.map((x) => x.notes).whereType<String>(),
                              ...e.sets.map((s) => s.note).whereType<String>(),
                            ])
                              Text('„$note”', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      if (e.tracking == Tracking.weight && e.sets.any((s) => s.weight > 0))
                        Text(weights.withUnit(e.sets.fold(0.0, (v, s) => v + s.reps * s.weight)), style: theme.textTheme.labelMedium),
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

/// On Today: "Repeat last workout · Tue, 3 exercises" — one tap starts it again.
class RepeatLastCard extends ConsumerWidget {
  const RepeatLastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(trainingDaysProvider).value?.days.firstOrNull;
    if (last == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Card(
      key: const Key('today.repeatLast'),
      child: ListTile(
        leading: const Icon(Icons.replay),
        title: Text(t.repeatLastWorkout),
        subtitle: Text(
          [
            DateFormat.MMMEd(locale).format(last.date),
            ?last.sessions.firstOrNull?.name,
            t.planExercises(last.exercises.length),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => repeatWorkout(context, ref, last),
      ),
    );
  }
}
