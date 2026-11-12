import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/units/measures.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/app_routes.dart';
import '../../exercises/data/models/exercise.dart';
import '../../exercises/presentation/category_ui.dart';
import '../../history/history_screen.dart';
import '../../progress/progress_cards.dart';
import '../data/workout_models.dart';
import 'exercise_workouts_screen.dart';
import 'workout_providers.dart';

/// "My workouts": exercises the user has trained, newest first.
class MyWorkoutsScreen extends ConsumerWidget {
  const MyWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final summaries = ref.watch(workoutSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.progress),
        actions: [
          IconButton(
            key: const Key('progress.history'),
            tooltip: t.history,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: summaries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              message: describeError(t, e),
              onRetry: () => ref.invalidate(workoutSummariesProvider),
            ),
            data: (items) => RefreshIndicator(
              onRefresh: () {
                ref.invalidate(yearStatsProvider);
                return ref.refresh(workoutSummariesProvider.future);
              },
              child: items.isEmpty
                  // Scrollable even when empty, so pulling down works here too.
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t.noWorkoutsYet, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => context.go(AppRoutes.exercises),
                                    icon: const Icon(Icons.fitness_center),
                                    label: Text(t.exercises),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const ActivityCard(),
                        BadgesCard(distinctExercises: items.length),
                        for (final s in items) _SummaryTile(summary: s, weights: ref.watch(weightFormatProvider)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.summary, required this.weights});

  final WorkoutSummary summary;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final bodyweight = summary.bestVolume == 0;
    final timed = summary.tracking != Tracking.weight;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(categoryIcon(summary.category), color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(summary.exerciseName),
        subtitle: Text(
          '${t.lastWorkout(DateFormat.yMMMd(locale).format(summary.lastDate))} · ${t.trainingDays(summary.trainingDays)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              switch (summary.tracking) {
                Tracking.time => formatDuration(summary.lastDurationSeconds),
                Tracking.distance => formatDistance(summary.lastDistanceMeters, decimalSeparator: locale.startsWith('pl') ? ',' : '.'),
                Tracking.weight => bodyweight ? t.repsValue(summary.lastTotalReps) : weights.withUnit(summary.lastVolume),
              },
              style: theme.textTheme.labelLarge,
            ),
            if (!bodyweight && !timed)
              Text(t.bestValue(weights.withUnit(summary.bestVolume)), style: theme.textTheme.labelSmall),
          ],
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ExerciseWorkoutsScreen(exerciseId: summary.exerciseId, exerciseName: summary.exerciseName),
        )),
      ),
    );
  }
}
