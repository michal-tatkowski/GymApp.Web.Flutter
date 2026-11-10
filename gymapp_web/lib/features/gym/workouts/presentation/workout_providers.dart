import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/retry.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(dioProvider)),
);

/// "My workouts": exercises the user has trained, newest first.
final workoutSummariesProvider = FutureProvider.autoDispose<List<WorkoutSummary>>(
  (ref) => ref.watch(workoutRepositoryProvider).getSummaries(),
  retry: noRetry,
);

/// Chart points for one exercise (one per training day, ascending).
final workoutProgressProvider = FutureProvider.autoDispose.family<List<ProgressPoint>, String>(
  (ref, exerciseId) => ref.watch(workoutRepositoryProvider).getProgress(exerciseId),
  retry: noRetry,
);

/// Entries of one exercise + add / edit / delete. Every change refreshes the chart
/// and the "My workouts" list, which are computed by the API.
final workoutLogProvider =
    AsyncNotifierProvider.autoDispose.family<WorkoutLogController, WorkoutLog, String>(
  WorkoutLogController.new,
  retry: noRetry,
);

class WorkoutLogController extends AsyncNotifier<WorkoutLog> {
  WorkoutLogController(this.exerciseId);

  final String exerciseId;

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  @override
  Future<WorkoutLog> build() => ref.watch(workoutRepositoryProvider).getLog(exerciseId);

  /// Throws a Failure (the form shows it and stays open).
  Future<void> add(WorkoutEntryRequest req) async {
    await _repo.addEntry(exerciseId, req);
    await _reload();
  }

  Future<void> edit(String entryId, WorkoutEntryRequest req) async {
    await _repo.updateEntry(exerciseId, entryId, req);
    await _reload();
  }

  Future<void> delete(String entryId) async {
    await _repo.deleteEntry(exerciseId, entryId);
    await _reload();
  }

  Future<void> _reload() async {
    ref.invalidate(workoutProgressProvider(exerciseId));
    ref.invalidate(workoutSummariesProvider);
    final log = await _repo.getLog(exerciseId);
    if (ref.mounted) state = AsyncData(log);
  }
}
