import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/secure_storage_keys.dart';
import '../../../core/units/weight_unit.dart';
import '../../../core/utils/uuid.dart';
import '../exercises/data/models/exercise.dart';
import '../plans/data/plan_models.dart';
import '../workouts/data/workout_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_providers.dart';
import '../workouts/presentation/exercise_workouts_screen.dart' show describeTimedOrPlain;
import '../workouts/presentation/rest_alarm.dart';
import '../workouts/presentation/rest_timer.dart';
import '../workouts/presentation/workout_providers.dart';
import 'session_models.dart';
import 'routines.dart';

/// The workout in progress (null = none). Persisted on every change, so closing
/// the app — or the phone killing it between sets — does not lose it.
///
/// Each exercise is saved as a normal log entry when the user moves on from it
/// (or finishes), through [WorkoutActions] — so history, charts and the offline
/// queue work exactly as for single entries.
final activeSessionProvider = NotifierProvider<SessionNotifier, WorkoutSession?>(SessionNotifier.new);

class SessionNotifier extends Notifier<WorkoutSession?> {
  bool _changedBeforeRestore = false;
  final _records = <String>{};

  @override
  WorkoutSession? build() {
    _restore();
    // In the background a notification shows what is next, with "Set done".
    final lifecycle = AppLifecycleListener(onHide: _showNotification, onShow: _clearNotification);
    final actions = ref.read(restAlarmProvider).actions.listen((action) {
      if (action == kSessionDoneAction) tickNext();
    });
    ref.onDispose(() {
      lifecycle.dispose();
      actions.cancel();
    });
    return null;
  }

  /// "Set done" from the notification: the first open set of the current exercise.
  void tickNext() {
    final s = state;
    if (s == null) return;
    final set = s.currentExercise.saved ? -1 : s.currentExercise.sets.indexWhere((x) => !x.done);
    if (set >= 0) toggleDone(s.current, set);
  }

  /// "Push A · Bench press" / "Set 2 of 3 · 8 × 100 kg".
  void _showNotification() {
    final s = state;
    if (s == null) return;
    final t = lookupAppLocalizations(ref.read(localeProvider));
    final e = s.currentExercise;
    final next = e.saved ? -1 : e.sets.indexWhere((x) => !x.done);
    final weights = ref.read(weightFormatProvider);
    final body = next < 0
        ? t.sessionNotificationDone
        : '${t.sessionNotificationSet(next + 1, e.sets.length)} · ${describeTimedOrPlain(e.sets[next].toWorkoutSet(), weights)}';
    ref.read(restAlarmProvider).showSession(title: '${s.planName} · ${e.name}', body: body, t: t);
  }

  void _clearNotification() => ref.read(restAlarmProvider).clearSession();

  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(StorageKeys.activeSession);
    if (!ref.mounted || _changedBeforeRestore || raw == null) return;
    try {
      state = WorkoutSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      log.w('Unreadable saved session, dropped: $e');
    }
  }

  void _set(WorkoutSession? session) {
    _changedBeforeRestore = true;
    state = session;
    SharedPreferences.getInstance().then((prefs) => session == null
        ? prefs.remove(StorageKeys.activeSession)
        : prefs.setString(StorageKeys.activeSession, jsonEncode(session.toJson())));
  }

  /// Starts [plan]: loads the last workout of each exercise (for the hints); offline
  /// the exercises simply start without hints.
  Future<void> start(WorkoutPlan plan) async {
    // In context: the workout notification (and the rest alerts) need it, and leaving
    // the app before the first rest — the timer's own ask — would show nothing.
    unawaited(ref.read(restAlarmProvider).requestPermission());
    final repo = ref.read(workoutRepositoryProvider);
    final weights = ref.read(weightFormatProvider);
    final last = await Future.wait(plan.items.map((item) async {
      try {
        return (await repo.getLog(item.exerciseId)).entries.firstOrNull?.sets;
      } catch (e) {
        if (isOfflineFailure(e)) return null;
        rethrow;
      }
    }));
    _records.clear();
    ref.read(routineChecksProvider.notifier).clear();
    _set(WorkoutSession(
      planId: plan.id.isEmpty ? null : plan.id, // "" = a repeated workout, not a saved plan
      planName: plan.name,
      startedAt: DateTime.now(),
      exercises: [for (var i = 0; i < plan.items.length; i++) SessionExercise.fromPlan(plan.items[i], last[i], weights)],
    ));
  }

  void _updateExercise(int index, SessionExercise Function(SessionExercise) update) {
    final s = state;
    if (s == null) return;
    _set(s.copyWith(exercises: [for (var i = 0; i < s.exercises.length; i++) i == index ? update(s.exercises[i]) : s.exercises[i]]));
  }

  /// Changes one set. A new weight or rep count is carried over to the later sets
  /// that are not done yet and still had the old value — set the weight once, not
  /// three times; sets the user already changed on purpose are left alone.
  void updateSet(int exercise, int set, SessionSet value) => _updateExercise(exercise, (e) {
        final old = e.sets[set];
        return e.copyWith(sets: [
          for (var i = 0; i < e.sets.length; i++)
            if (i == set)
              value
            else if (i > set && !e.sets[i].done)
              e.sets[i].copyWith(
                weightKg: e.sets[i].weightKg == old.weightKg ? value.weightKg : null,
                reps: e.sets[i].reps == old.reps ? value.reps : null,
              )
            else
              e.sets[i],
        ]);
      });

  /// Ticks a set off (starts the rest timer) or un-ticks it.
  ///
  /// In a superset/circuit a ticked set moves straight on to the next exercise of
  /// the group that still has sets to do — no rest in between. The rest comes after
  /// the last exercise of the round, and then the round starts over from the first.
  void toggleDone(int exercise, int set) {
    final s = state;
    if (s == null) return;
    final value = s.exercises[exercise].sets[set];
    updateSet(exercise, set, value.copyWith(done: !value.done));
    if (value.done) return;
    HapticFeedback.mediumImpact();

    final now = state!;
    // A drop set comes next: straight on, no rest (and no moving to a superset partner).
    final sets = now.exercises[exercise].sets;
    if (set + 1 < sets.length && sets[set + 1].drop && !sets[set + 1].done) return;
    final group = now.groupOf(exercise);
    bool hasWork(int i) => !now.exercises[i].saved && now.exercises[i].sets.any((x) => !x.done);
    final later = [for (var i = exercise + 1; i <= group.end; i++) if (hasWork(i)) i];
    if (later.isNotEmpty) {
      _set(now.copyWith(current: later.first));
      return;
    }
    ref.read(restTimerProvider.notifier).startAfterSet();
    final again = [for (var i = group.start; i < exercise; i++) if (hasWork(i)) i];
    if (again.isNotEmpty) _set(now.copyWith(current: again.first));
  }

  /// A timed set held for [seconds] (the timer): only this set gets that time — finishing
  /// early once does not shorten the next ones — and it is ticked off.
  void completeTimedSet(int exercise, int set, int seconds) {
    _updateExercise(exercise, (e) => e.copyWith(sets: [
          for (var i = 0; i < e.sets.length; i++) i == set ? e.sets[i].copyWith(durationSeconds: seconds) : e.sets[i],
        ]));
    if (!(state?.exercises[exercise].sets[set].done ?? true)) toggleDone(exercise, set);
  }

  /// One more set, same as the last one.
  void addSet(int exercise) => _updateExercise(exercise, (e) {
        final last = e.sets.lastOrNull ?? SessionSet(reps: e.repsMin, weightKg: 0);
        return e.copyWith(sets: [...e.sets, SessionSet(reps: last.reps, weightKg: last.weightKg)]);
      });

  void removeSet(int exercise, int set) =>
      _updateExercise(exercise, (e) => e.copyWith(sets: [...e.sets]..removeAt(set)));

  /// Adds an exercise that was not in the plan (after the current one) and goes to it.
  Future<void> addExercise(Exercise exercise, WorkoutActions actions) async {
    final s = state;
    if (s == null) return;
    final item = PlanItem(exerciseId: exercise.id, exerciseName: exercise.name, category: exercise.category, tracking: exercise.tracking);
    List<WorkoutSet>? last;
    try {
      last = (await ref.read(workoutRepositoryProvider).getLog(exercise.id)).entries.firstOrNull?.sets;
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
    }
    final added = SessionExercise.fromPlan(item, last, ref.read(weightFormatProvider));
    final at = s.groupOf(s.current).end + 1; // never splits a superset
    final latest = state;
    if (latest == null) return;
    _set(latest.copyWith(exercises: [...latest.exercises]..insert(at, added)));
    await goTo(at, actions);
  }

  /// Puts [exercise] in place of the one at [index] (not started yet): same number of
  /// sets, rep range and superset link; its own last workout for the hint.
  Future<void> replaceExercise(int index, Exercise exercise) async {
    final s = state;
    if (s == null || index < 0 || index >= s.exercises.length) return;
    final old = s.exercises[index];
    final item = PlanItem(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      category: exercise.category,
      tracking: exercise.tracking,
      sets: old.sets.isEmpty ? 3 : old.sets.length,
      repsMin: old.repsMin,
      repsMax: old.repsMax,
      supersetWithNext: old.supersetWithNext,
    );
    List<WorkoutSet>? last;
    try {
      last = (await ref.read(workoutRepositoryProvider).getLog(exercise.id)).entries.firstOrNull?.sets;
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
    }
    final latest = state;
    if (latest == null) return;
    _updateExercise(index, (_) => SessionExercise.fromPlan(item, last, ref.read(weightFormatProvider)));
  }

  /// Moves to another exercise. Leaving a group (a single exercise, or a whole
  /// superset) saves its done sets first; moving inside a superset saves nothing,
  /// since its exercises are still being done in turns.
  /// Throws a Failure when saving fails (offline is not a failure — it is queued).
  Future<void> goTo(int index, WorkoutActions actions) async {
    final s = state;
    if (s == null || index < 0 || index >= s.exercises.length) return;
    final group = s.groupOf(s.current);
    if (index < group.start || index > group.end) {
      for (var i = group.start; i <= group.end; i++) {
        await _save(i, actions);
      }
    }
    final now = state;
    if (now != null) _set(now.copyWith(current: index));
  }

  Future<void> _save(int index, WorkoutActions actions) async {
    final exercise = state?.exercises[index];
    if (exercise == null || exercise.saved || exercise.doneSets.isEmpty) return;
    final now = DateTime.now();
    final (created, record) = await actions.addAndCheckRecord(
      exercise.exerciseId,
      WorkoutEntryRequest(
        date: DateTime(now.year, now.month, now.day),
        sets: [for (final s in exercise.doneSets) s.toWorkoutSet()],
      ),
    );
    if (record != null) _records.add(exercise.name);
    _updateExercise(index, (e) => e.copyWith(savedEntryId: created.id));
  }

  /// Saves everything not saved yet and ends the session.
  Future<SessionSummary?> finish(WorkoutActions actions) async {
    final s = state;
    if (s == null) return null;
    for (var i = 0; i < s.exercises.length; i++) {
      await _save(i, actions);
    }
    final done = state!.exercises.where((e) => e.doneSets.isNotEmpty).toList();
    final sessionId = done.isEmpty ? null : newUuid();
    final summary = SessionSummary(
      sessionId: sessionId,
      recorded: sessionId == null ? null : _recordSession(s, sessionId),
      planName: s.planName,
      duration: DateTime.now().difference(s.startedAt),
      exercises: done.length,
      sets: done.fold(0, (n, e) => n + e.doneSets.length),
      volumeKg: done.fold(0.0, (v, e) => v + e.doneSets.fold(0.0, (w, s) => w + s.reps * s.weightKg)),
      records: _records.toList(),
    );
    _clearNotification();
    _set(null);
    ref.read(restTimerProvider.notifier).stop();
    return summary;
  }

  /// Duration and name for the history. Best effort: without a connection the history
  /// simply shows the day without its duration (the sets themselves are queued).
  Future<bool> _recordSession(WorkoutSession s, String id) async {
    final now = DateTime.now();
    try {
      await ref.read(workoutRepositoryProvider).saveSession(
            id: id,
            planId: s.planId == null || s.planId!.isEmpty ? null : s.planId,
            name: s.planName,
            date: DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day),
            startedAt: s.startedAt,
            finishedAt: now,
          );
      if (ref.mounted) ref.invalidate(trainingDaysProvider);
      return true;
    } catch (e) {
      log.w('Session not recorded: $e');
      return false;
    }
  }

  /// Ends without saving the remaining sets (exercises already saved stay in the history).
  void discard() {
    _set(null);
    _clearNotification();
    ref.read(restTimerProvider.notifier).stop();
  }
}
