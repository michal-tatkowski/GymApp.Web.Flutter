import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/theme/app_theme.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

class WeekSummary {
  const WeekSummary({
    required this.weekStart,
    required this.trainedDays,
    required this.workouts,
    required this.sets,
    required this.volumeKg,
    required this.weekStreak,
    required this.records,
  });

  final DateTime weekStart;

  /// 0 = [weekStart], … 6 = last day of the week.
  final Set<int> trainedDays;
  final int workouts;
  final int sets;
  final double volumeKg;

  /// Weeks in a row with at least one workout. The current week counts once it
  /// has a workout; until then the streak of earlier weeks is kept (not broken yet).
  final int weekStreak;
  final List<PersonalRecord> records;
}

/// [firstDayOfWeek]: 0 = Sunday … 6 = Saturday (MaterialLocalizations.firstDayOfWeekIndex).
WeekSummary summarizeWeek(WorkoutStats stats, DateTime now, int firstDayOfWeek) {
  final today = DateUtils.dateOnly(now);
  DateTime startOf(DateTime d) => DateUtils.addDaysToDate(d, -((d.weekday % 7 - firstDayOfWeek + 7) % 7));
  final weekStart = startOf(today);
  final thisWeek = stats.days.where((d) => !d.date.isBefore(weekStart)).toList();

  final trainedWeeks = {for (final d in stats.days) startOf(d.date)};
  var streak = 0;
  var week = trainedWeeks.contains(weekStart) ? weekStart : DateUtils.addDaysToDate(weekStart, -7);
  while (trainedWeeks.contains(week)) {
    streak++;
    week = DateUtils.addDaysToDate(week, -7);
  }

  return WeekSummary(
    weekStart: weekStart,
    trainedDays: {for (final d in thisWeek) d.date.difference(weekStart).inDays},
    workouts: thisWeek.length,
    sets: thisWeek.fold(0, (n, d) => n + d.sets),
    volumeKg: thisWeek.fold(0.0, (v, d) => v + d.volume),
    weekStreak: streak,
    records: stats.records.where((r) => !r.date.isBefore(weekStart)).toList(),
  );
}

/// "This week": a dot per day, workouts / sets / volume, week streak and records.
/// Hidden until there is any history (a new user sees plans and quick log first).
class WeekSummaryCard extends ConsumerWidget {
  const WeekSummaryCard({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider).value;
    if (stats == null || stats.days.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weights = ref.watch(weightFormatProvider);
    final locale = Localizations.localeOf(context).toString();
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final s = summarizeWeek(stats, today, MaterialLocalizations.of(context).firstDayOfWeekIndex);

    return Card(
      key: const Key('today.week'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.thisWeek, style: theme.textTheme.titleMedium)),
                if (s.weekStreak > 1)
                  Text('🔥 ${t.weekStreak(s.weekStreak)}', key: const Key('today.streak'), style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayDot(
                    label: DateFormat.E(locale).format(DateUtils.addDaysToDate(s.weekStart, i)).characters.first.toUpperCase(),
                    trained: s.trainedDays.contains(i),
                    today: DateUtils.addDaysToDate(s.weekStart, i) == today,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.workouts == 0
                  ? t.weekNothingYet
                  : [
                      t.weekWorkouts(s.workouts),
                      t.weekSets(s.sets),
                      if (s.volumeKg > 0) weights.withUnit(s.volumeKg),
                    ].join(' · '),
              key: const Key('today.weekStats'),
            ),
            if (s.records.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '🏆 ${t.weekRecords(s.records.map((r) => r.exerciseName).toSet().join(', '))}',
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.favorite),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.trained, required this.today});

  final String label;
  final bool trained;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: trained ? colors.primary : colors.surfaceContainerHighest,
            border: today ? Border.all(color: colors.primary, width: 2) : null,
          ),
          child: trained ? Icon(Icons.check, size: 16, color: colors.onPrimary) : null,
        ),
      ],
    );
  }
}
