import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/errors/failure_messages.dart';
import '../../../core/units/measures.dart';
import '../../../core/units/weight_unit.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/exercise_workouts_screen.dart';
import '../workouts/presentation/workout_providers.dart';

/// Personal records: for every trained exercise its bests and the day each was set.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final records = ref.watch(recordsProvider);
    final weights = ref.watch(weightFormatProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.records)),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: describeError(t, e), onRetry: () => ref.invalidate(recordsProvider)),
        data: (items) => items.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(t.noWorkoutsYet, textAlign: TextAlign.center)))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(recordsProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [for (final r in items) _RecordsCard(records: r, weights: weights)],
                ),
              ),
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records, required this.weights});

  final ExerciseRecords records;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final sep = locale.startsWith('pl') ? ',' : '.';
    String set(RecordValue v) => v.reps == null ? '' : ' (${v.reps} × ${weights.withUnit(v.weight ?? 0)})';

    final rows = <(String, RecordValue?, String Function(RecordValue))>[
      if (records.tracking == Tracking.weight) ...[
        (t.recordOneRepMax, records.bestOneRepMax, (v) => '${weights.withUnit(v.value)}${set(v)}'),
        (t.recordHeaviest, records.heaviestWeight, (v) => '${weights.withUnit(v.value)} × ${v.reps}'),
        (t.recordDayVolume, records.bestDayVolume, (v) => weights.withUnit(v.value)),
        (t.recordMostReps, records.mostReps, (v) => v.weight == null || v.weight == 0 ? '${v.value.round()}' : '${v.value.round()} × ${weights.withUnit(v.weight!)}'),
      ],
      if (records.tracking != Tracking.weight) (t.recordLongest, records.longestDuration, (v) => formatDuration(v.value.round())),
      if (records.tracking == Tracking.distance)
        (t.recordDistance, records.longestDistance, (v) => formatDistance(v.value, decimalSeparator: sep)),
    ].where((r) => r.$2 != null).toList();

    return Card(
      key: Key('records.${records.exerciseId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ExerciseWorkoutsScreen(exerciseId: records.exerciseId, exerciseName: records.exerciseName),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categoryIcon(records.category), color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(records.exerciseName, style: theme.textTheme.titleMedium)),
                  Text(t.trainingDays(records.trainingDays), style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              for (final (label, value, format) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                      Text(format(value!), style: theme.textTheme.labelLarge),
                      const SizedBox(width: 8),
                      Text(DateFormat.yMMMd(locale).format(value.date), style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
