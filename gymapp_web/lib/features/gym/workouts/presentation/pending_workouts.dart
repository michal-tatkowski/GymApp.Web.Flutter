import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage_keys.dart';
import '../data/workout_models.dart';
import 'workout_providers.dart';

/// A workout logged without a connection (basement gyms), waiting to be sent.
class PendingWorkout {
  const PendingWorkout({required this.exerciseId, required this.request});

  final String exerciseId;

  /// Always has an [WorkoutEntryRequest.id] — re-sending it cannot create a duplicate.
  final WorkoutEntryRequest request;

  String get entryId => request.id!;

  Map<String, dynamic> toJson() => {'exerciseId': exerciseId, 'request': request.toJson()};

  factory PendingWorkout.fromJson(Map<String, dynamic> json) => PendingWorkout(
        exerciseId: json['exerciseId'] as String,
        request: WorkoutEntryRequest.fromJson(json['request'] as Map<String, dynamic>),
      );
}

/// Workouts saved on the phone until the API can take them. Persisted, so they
/// survive closing the app. Sent:
/// - every [retryInterval] while something is waiting,
/// - when the app comes back to the foreground,
/// - on demand ("Sync now", pull to refresh).
final pendingWorkoutsProvider =
    NotifierProvider<PendingWorkoutsNotifier, List<PendingWorkout>>(PendingWorkoutsNotifier.new);

class PendingWorkoutsNotifier extends Notifier<List<PendingWorkout>> {
  static const retryInterval = Duration(seconds: 30);

  Timer? _retry;
  AppLifecycleListener? _lifecycle;
  Future<int>? _syncing;
  bool _changedBeforeRestore = false;

  @override
  List<PendingWorkout> build() {
    ref.onDispose(() {
      _retry?.cancel();
      _lifecycle?.dispose();
    });
    _restore();
    return const [];
  }

  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(StorageKeys.pendingWorkouts);
    if (!ref.mounted || raw == null) return;
    try {
      final stored = (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(PendingWorkout.fromJson).toList();
      // Something queued while prefs were loading is kept too.
      state = _changedBeforeRestore ? [...stored, ...state] : stored;
      _scheduleRetry();
    } catch (e) {
      log.w('Unreadable offline workout queue, dropped: $e');
    }
  }

  Future<void> enqueue(PendingWorkout workout) async {
    _changedBeforeRestore = true;
    state = [...state, workout];
    await _save();
    _scheduleRetry();
  }

  /// "Undo" or delete of a workout that never reached the server.
  Future<void> remove(String entryId) async {
    state = state.where((p) => p.entryId != entryId).toList();
    await _save();
    _scheduleRetry();
  }

  /// Explicit logout: the queue belongs to the account that is leaving.
  Future<void> clear() async {
    state = const [];
    await _save();
    _scheduleRetry();
  }

  /// Sends what is waiting, oldest first; stops at the first offline failure.
  /// Returns how many were sent. Concurrent calls share one run.
  Future<int> sync() => _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<int> _sync() async {
    var sent = 0;
    for (final workout in List.of(state)) {
      try {
        await ref.read(workoutRepositoryProvider).addEntry(workout.exerciseId, workout.request);
        sent++;
      } catch (e) {
        if (isOfflineFailure(e)) break;
        if (e is UnauthorizedFailure) break; // session expired — keep it for after login
        // Rejected for good (e.g. the exercise was deleted): retrying would never succeed.
        log.w('Offline workout ${workout.entryId} rejected by the API, dropped: $e');
      }
      if (!ref.mounted) return sent;
      state = state.where((p) => p.entryId != workout.entryId).toList();
      await _save();
      ref
        ..invalidate(workoutLogProvider(workout.exerciseId))
        ..invalidate(workoutProgressProvider(workout.exerciseId));
    }
    if (sent > 0 && ref.mounted) {
      ref
        ..invalidate(workoutSummariesProvider)
        ..invalidate(workoutStatsProvider)
        ..invalidate(yearStatsProvider)
        ..invalidate(trainingDaysProvider);
    }
    if (ref.mounted) _scheduleRetry();
    return sent;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.isEmpty) {
      await prefs.remove(StorageKeys.pendingWorkouts);
    } else {
      await prefs.setString(StorageKeys.pendingWorkouts, jsonEncode(state.map((p) => p.toJson()).toList()));
    }
  }

  void _scheduleRetry() {
    if (state.isEmpty) {
      _retry?.cancel();
      _retry = null;
      return;
    }
    _retry ??= Timer.periodic(retryInterval, (_) => sync());
    _lifecycle ??= AppLifecycleListener(onResume: sync);
  }
}
