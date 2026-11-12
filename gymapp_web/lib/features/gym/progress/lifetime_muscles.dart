import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/units/measures.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

// ─── All time ──────────────────────────────────────────────────────────────

/// "All time": days, sets, reps, kilos, hours… since the first logged workout.
/// Hidden while loading, offline, or before the first workout.
class LifetimeCard extends ConsumerWidget {
  const LifetimeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(lifetimeStatsProvider).value;
    if (stats == null || stats.trainingDates.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weights = ref.watch(weightFormatProvider);
    final count = NumberFormat.decimalPattern(locale);
    final hours = stats.durationSeconds ~/ 3600;

    final tiles = [
      (t.lifetimeDays, count.format(stats.trainingDates.length)),
      (t.lifetimeSets, count.format(stats.sets)),
      (t.lifetimeReps, count.format(stats.reps)),
      if (stats.volumeKg > 0) (t.lifetimeVolume, '${count.format(weights.fromKg(stats.volumeKg).round())} ${weights.label}'),
      if (stats.durationSeconds > 0)
        (t.lifetimeTime, hours > 0 ? t.hoursShort(hours) : t.durationMinutes(stats.durationSeconds ~/ 60)),
      if (stats.distanceMeters > 0) (t.lifetimeDistance, formatDistance(stats.distanceMeters)),
      (t.lifetimeRecords, count.format(stats.records)),
      (t.lifetimeExercises, count.format(stats.exercises)),
    ];

    return Card(
      key: const Key('progress.lifetime'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.lifetimeTitle, style: theme.textTheme.titleMedium),
            Text(t.lifetimeSince(DateFormat.yMMMMd(locale).format(stats.trainingDates.first)), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                // Two columns on a phone, more when there is room.
                final columns = (box.maxWidth / 150).floor().clamp(2, 4);
                final width = (box.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (label, value) in tiles)
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                            Text(label, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sets per muscle group ─────────────────────────────────────────────────

/// Sets per category: this week and the average of the [kMuscleWeeks] - 1 full weeks
/// before it. [firstDayOfWeek]: 0 = Sunday … 6 = Saturday.
({Map<ExerciseCategory, int> thisWeek, Map<ExerciseCategory, double> average}) muscleSets(
  List<TrainingDayDetails> days,
  int firstDayOfWeek,
  DateTime today,
) {
  final day = DateUtils.dateOnly(today);
  final weekStart = DateUtils.addDaysToDate(day, -((day.weekday % 7 - firstDayOfWeek + 7) % 7));
  const pastWeeks = kMuscleWeeks - 1;
  final pastStart = DateUtils.addDaysToDate(weekStart, -7 * pastWeeks);
  final thisWeek = <ExerciseCategory, int>{};
  final past = <ExerciseCategory, int>{};
  for (final d in days) {
    final date = DateUtils.dateOnly(d.date);
    final target = !date.isBefore(weekStart) ? thisWeek : (!date.isBefore(pastStart) ? past : null);
    if (target == null) continue;
    for (final e in d.exercises) {
      target[e.category] = (target[e.category] ?? 0) + e.sets.length;
    }
  }
  return (thisWeek: thisWeek, average: past.map((k, v) => MapEntry(k, v / pastWeeks)));
}

/// One hint about the balance, or null when it looks fine (or there is too little to judge).
String? muscleHint(AppLocalizations t, Map<ExerciseCategory, num> sets) {
  final push = sets[ExerciseCategory.push] ?? 0, pull = sets[ExerciseCategory.pull] ?? 0;
  final total = sets.values.fold<num>(0, (a, b) => a + b);
  if (total < 6) return null;
  if (push >= 6 && push >= pull * 1.5) return t.musclesMorePush;
  if (pull >= 6 && pull >= push * 1.5) return t.musclesMorePull;
  if ((sets[ExerciseCategory.legs] ?? 0) == 0) return t.musclesNoLegs;
  return null;
}

/// Bars of sets per muscle group (push / pull / legs / core / cardio / other) for this
/// week or the recent average, with a hint when one side clearly dominates.
class MuscleBalanceCard extends ConsumerStatefulWidget {
  const MuscleBalanceCard({super.key});

  @override
  ConsumerState<MuscleBalanceCard> createState() => _MuscleBalanceCardState();
}

class _MuscleBalanceCardState extends ConsumerState<MuscleBalanceCard> {
  bool _average = false;

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(muscleDaysProvider).value;
    if (days == null || days.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final data = muscleSets(days, MaterialLocalizations.of(context).firstDayOfWeekIndex, DateTime.now());
    final Map<ExerciseCategory, num> sets = _average ? data.average : data.thisWeek;
    final max = sets.values.fold<num>(0, (a, b) => b > a ? b : a);
    final hint = muscleHint(t, sets);
    final number = NumberFormat('0.#', locale);

    return Card(
      key: const Key('progress.muscles'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.musclesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              key: const Key('muscles.period'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(t.musclesThisWeek)),
                ButtonSegment(value: true, label: Text(t.musclesAverage)),
              ],
              selected: {_average},
              onSelectionChanged: (v) => setState(() => _average = v.single),
            ),
            const SizedBox(height: 12),
            if (max == 0)
              Text(t.musclesEmpty, style: theme.textTheme.bodyMedium)
            else
              for (final cat in ExerciseCategory.values)
                if ((sets[cat] ?? 0) > 0)
                  Padding(
                    key: Key('muscles.${cat.name}'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(categoryIcon(cat), size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        SizedBox(width: 96, child: Text(categoryLabel(context, cat), overflow: TextOverflow.ellipsis)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sets[cat]! / max,
                              minHeight: 12,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(number.format(sets[cat]), textAlign: TextAlign.end, style: theme.textTheme.labelLarge),
                        ),
                      ],
                    ),
                  ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hint, key: const Key('muscles.hint'), style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
