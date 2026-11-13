import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/providers/retry.dart';
import '../../../../core/utils/uuid.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../data/workout_models.dart';
import '../data/workout_repository.dart';
import 'pending_workouts.dart';
import 'widgets/progress_chart.dart';

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

/// Training days and records of the last 12 weeks (API default) — the weekly summary on Today.
final workoutStatsProvider = FutureProvider.autoDispose<WorkoutStats>(
  (ref) => ref.watch(workoutRepositoryProvider).getStats(),
  retry: noRetry,
);

/// Training days and records of the whole period the API allows (400 days) —
/// the activity map and badges on Progress.
final yearStatsProvider = FutureProvider.autoDispose<WorkoutStats>(
  (ref) {
    final now = DateTime.now();
    return ref.watch(workoutRepositoryProvider).getStats(since: DateTime(now.year, now.month, now.day - kStatsMaxDays));
  },
  retry: noRetry,
);

/// Totals over the whole account (no 400-day limit): the "All time" card and lifetime badges.
/// Null while offline / unavailable — the badges then fall back to [yearStatsProvider].
final lifetimeStatsProvider = FutureProvider.autoDispose<LifetimeStats?>(
  (ref) async {
    try {
      return await ref.watch(workoutRepositoryProvider).getLifetime();
    } catch (_) {
      return null; // an older API without the endpoint, or offline
    }
  },
  retry: noRetry,
);

/// Days with exercises and sets of the last [kMuscleWeeks] weeks (this one included): sets per muscle group.
final muscleDaysProvider = FutureProvider.autoDispose<List<TrainingDayDetails>>(
  (ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ref.watch(workoutRepositoryProvider).getDays(from: DateTime(now.year, now.month, now.day - 7 * kMuscleWeeks), to: today);
  },
  retry: noRetry,
);

const kMuscleWeeks = 5;

/// This month's challenges from the API — the same on every device, proposed by the server on
/// the first look of the month and fixed until it ends. Null offline (with nothing cached) or
/// with an older API: the card then just stays away.
final challengesProvider = FutureProvider.autoDispose<MonthChallenges?>(
  (ref) async {
    try {
      return await ref.watch(workoutRepositoryProvider).getChallenges();
    } catch (_) {
      return null;
    }
  },
  retry: noRetry,
);

/// Must match the API (GetWorkoutStatsQuery.MaxDays).
const kStatsMaxDays = 400;

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

  /// Returns the created entry (for "Undo"). Without a connection the workout is
  /// kept on the phone and sent later — the result then has `pending: true`.
  /// Throws a Failure for anything else (e.g. validation).
  Future<WorkoutEntry> add(String exerciseId, WorkoutEntryRequest req) async {
    // The app picks the id, so a retry from the offline queue cannot duplicate it.
    final withId = req.id == null ? req.withId(newUuid()) : req;
    try {
      final created = await _repo.addEntry(exerciseId, withId);
      _refresh(exerciseId);
      return created;
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
      await _container
          .read(pendingWorkoutsProvider.notifier)
          .enqueue(PendingWorkout(exerciseId: exerciseId, request: withId));
      return WorkoutEntry.pending(withId);
    }
  }

  /// Like [add], plus whether the entry beats the previous best (volume of the day or
  /// estimated 1RM) — for the "New record!" message. Costs one extra progress request;
  /// offline there is no history to compare with, so no record check.
  Future<(WorkoutEntry, NewRecord?)> addAndCheckRecord(String exerciseId, WorkoutEntryRequest req) async {
    List<ProgressPoint>? before;
    try {
      before = await _repo.getProgress(exerciseId);
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
    }
    final created = await add(exerciseId, req);
    if (before == null || created.pending) return (created, null);
    return (created, newRecordFor(before, created));
  }

  Future<WorkoutEntry> edit(String exerciseId, String entryId, WorkoutEntryRequest req) async {
    final updated = await _repo.updateEntry(exerciseId, entryId, req);
    _refresh(exerciseId);
    return updated;
  }

  Future<void> delete(String exerciseId, String entryId) async {
    final queue = _container.read(pendingWorkoutsProvider.notifier);
    if (_container.read(pendingWorkoutsProvider).any((p) => p.entryId == entryId)) {
      return queue.remove(entryId); // never reached the server
    }
    await _repo.deleteEntry(exerciseId, entryId);
    _refresh(exerciseId);
  }

  void _refresh(String exerciseId) {
    _container.invalidate(workoutLogProvider(exerciseId));
    _container.invalidate(workoutProgressProvider(exerciseId));
    _container.invalidate(workoutSummariesProvider);
    _container.invalidate(workoutStatsProvider);
    _container.invalidate(yearStatsProvider);
    _container.invalidate(challengesProvider);
    _container.invalidate(lifetimeStatsProvider);
    _container.invalidate(muscleDaysProvider);
    _container.invalidate(trainingDaysProvider);
    _container.invalidate(recordsProvider);
  }
}

/// History day by day (newest first), loaded in pages of [TrainingHistoryNotifier.pageDays]
/// going back; "Load more" adds the next page.
final trainingDaysProvider =
    AsyncNotifierProvider.autoDispose<TrainingHistoryNotifier, TrainingHistory>(TrainingHistoryNotifier.new, retry: noRetry);

class TrainingHistory {
  const TrainingHistory({required this.days, required this.loadedFrom, required this.hasMore, this.loadingMore = false});

  final List<TrainingDayDetails> days;

  /// Oldest day already asked for.
  final DateTime loadedFrom;
  final bool hasMore;
  final bool loadingMore;

  TrainingHistory copyWith({List<TrainingDayDetails>? days, DateTime? loadedFrom, bool? hasMore, bool? loadingMore}) =>
      TrainingHistory(
        days: days ?? this.days,
        loadedFrom: loadedFrom ?? this.loadedFrom,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class TrainingHistoryNotifier extends AsyncNotifier<TrainingHistory> {
  static const pageDays = 90;

  /// Older than this with an empty page = nothing more to look for.
  static const searchBackDays = 3 * 365;

  @override
  Future<TrainingHistory> build() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: pageDays));
    final days = await ref.watch(workoutRepositoryProvider).getDays(from: from, to: today.add(const Duration(days: 1)));
    return TrainingHistory(days: days, loadedFrom: from, hasMore: true);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final to = current.loadedFrom.subtract(const Duration(days: 1));
    final from = to.subtract(const Duration(days: pageDays - 1));
    try {
      final older = await ref.read(workoutRepositoryProvider).getDays(from: from, to: to);
      final now = DateTime.now();
      final tooOld = now.difference(from).inDays > searchBackDays;
      state = AsyncData(current.copyWith(
        days: [...current.days, ...older],
        loadedFrom: from,
        hasMore: older.isNotEmpty || !tooOld,
        loadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }
}

/// All-time bests of every trained exercise — the records screen and exercise goals.
final recordsProvider = FutureProvider.autoDispose<List<ExerciseRecords>>(
  (ref) => ref.watch(workoutRepositoryProvider).getRecords(),
  retry: noRetry,
);
