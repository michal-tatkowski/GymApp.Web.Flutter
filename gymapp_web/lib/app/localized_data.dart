import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/gym/exercises/presentation/exercises_providers.dart';
import '../features/gym/goals/goals_data.dart';
import '../features/gym/plans/presentation/plan_providers.dart';
import '../features/gym/workouts/presentation/workout_providers.dart';

/// Exercise and template names come from the API in the app's language (Accept-Language).
/// After switching the language everything already loaded is fetched again — otherwise
/// plans, history, favorites and records keep the old language until the next refresh.
void refreshLocalizedData(WidgetRef ref) {
  ref
    ..invalidate(exercisesProvider)
    ..invalidate(favoriteExercisesProvider)
    ..invalidate(plansProvider)
    ..invalidate(planTemplatesProvider)
    ..invalidate(goalsProvider)
    ..invalidate(workoutSummariesProvider)
    ..invalidate(workoutLogProvider)
    ..invalidate(workoutStatsProvider)
    ..invalidate(yearStatsProvider)
    ..invalidate(muscleDaysProvider)
    ..invalidate(trainingDaysProvider)
    ..invalidate(recordsProvider)
    ..invalidate(challengesProvider);
}
