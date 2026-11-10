import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/retry.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) => WorkoutRepository(ref.watch(dioProvider)));

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

/// Entries of one exercise, newest first. Changes go through [WorkoutActions].
final workoutLogProvider = FutureProvider.autoDispose.family<WorkoutLog, String>(
  (ref, exerciseId) => ref.watch(workoutRepositoryProvider).getLog(exerciseId),
  retry: noRetry,
);

/// Add / edit / delete entries, then refresh everything computed from them
/// (log, chart, "My workouts", "Today").
///
/// Works on the app's ProviderContainer, not on a widget's ref or a notifier:
/// "Undo" in a snackbar runs after the form closed or the screen was left, and
/// a provider nobody watches may already be disposed by then.
class WorkoutActions {
  WorkoutActions(this._container);

  factory WorkoutActions.of(BuildContext context) => WorkoutActions(ProviderScope.containerOf(context, listen: false));

  final ProviderContainer _container;

  WorkoutRepository get _repo => _container.read(workoutRepositoryProvider);

  /// Throws a Failure. Returns the created entry (for "Undo").
  Future<WorkoutEntry> add(String exerciseId, WorkoutEntryRequest req) async {
    final created = await _repo.addEntry(exerciseId, req);
    _refresh(exerciseId);
    return created;
  }

  Future<WorkoutEntry> edit(String exerciseId, String entryId, WorkoutEntryRequest req) async {
    final updated = await _repo.updateEntry(exerciseId, entryId, req);
    _refresh(exerciseId);
    return updated;
  }

  Future<void> delete(String exerciseId, String entryId) async {
    await _repo.deleteEntry(exerciseId, entryId);
    _refresh(exerciseId);
  }

  void _refresh(String exerciseId) {
    _container.invalidate(workoutLogProvider(exerciseId));
    _container.invalidate(workoutProgressProvider(exerciseId));
    _container.invalidate(workoutSummariesProvider);
  }
}
