import 'package:dio/dio.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_repository.dart';

/// In-memory api/Workouts with the same volume / per-day rules as the API.
class FakeWorkoutRepository extends WorkoutRepository {
  FakeWorkoutRepository({this.exerciseName = 'Bench press'}) : super(Dio());

  final String exerciseName;
  final entries = <String, List<WorkoutEntry>>{};
  Object? saveError;
  int _id = 0;

  /// No connection: every call throws NetworkFailure (offline queue tests).
  bool offline = false;

  /// Every POST that reached the "server", in order (retries included).
  final posted = <WorkoutEntryRequest>[];

  void _online() {
    if (offline) throw const NetworkFailure();
  }

  static WorkoutEntry entryOf(String id, DateTime date, List<WorkoutSet> sets, String? notes) => WorkoutEntry(
        id: id,
        date: date,
        sets: sets,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(), // like the API
        volume: sets.fold(0.0, (v, s) => v + s.reps * s.weight),
        totalReps: sets.fold(0, (v, s) => v + s.reps),
        maxWeight: sets.map((s) => s.weight).fold(0.0, (a, b) => a > b ? a : b),
        estimatedOneRepMax: sets.map(oneRepMax).fold(0.0, (a, b) => a > b ? a : b),
      );

  /// Epley, like the API.
  static double oneRepMax(WorkoutSet s) =>
      s.weight <= 0 ? 0 : s.reps <= 1 ? s.weight : ((s.weight * (1 + s.reps / 30)) * 10).round() / 10;

  void seed(String exerciseId, DateTime date, List<WorkoutSet> sets) =>
      (entries[exerciseId] ??= []).add(entryOf('e${_id++}', date, sets, null));

  @override
  Future<WorkoutLog> getLog(String exerciseId) async {
    _online();
    final list = [...entries[exerciseId] ?? <WorkoutEntry>[]]..sort((a, b) => b.date.compareTo(a.date));
    return WorkoutLog(exerciseId: exerciseId, exerciseName: exerciseName, category: ExerciseCategory.push, entries: list);
  }

  @override
  Future<List<ProgressPoint>> getProgress(String exerciseId) async {
    _online();
    final byDay = <DateTime, List<WorkoutEntry>>{};
    for (final e in entries[exerciseId] ?? <WorkoutEntry>[]) {
      (byDay[e.date] ??= []).add(e);
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final d in days)
        ProgressPoint(
          date: d,
          volume: byDay[d]!.fold(0.0, (v, e) => v + e.volume),
          totalReps: byDay[d]!.fold(0, (v, e) => v + e.totalReps),
          maxWeight: byDay[d]!.map((e) => e.maxWeight).fold(0.0, (a, b) => a > b ? a : b),
          sets: byDay[d]!.fold(0, (v, e) => v + e.sets.length),
          estimatedOneRepMax: byDay[d]!.map((e) => e.estimatedOneRepMax).fold(0.0, (a, b) => a > b ? a : b),
        ),
    ];
  }

  @override
  Future<List<WorkoutSummary>> getSummaries() async {
    _online();
    return [
        for (final id in entries.keys)
          if (entries[id]!.isNotEmpty)
            await getProgress(id).then((p) => WorkoutSummary(
                  exerciseId: id,
                  exerciseName: exerciseName,
                  category: ExerciseCategory.push,
                  trainingDays: p.length,
                  lastDate: p.last.date,
                  lastVolume: p.last.volume,
                  bestVolume: p.map((x) => x.volume).reduce((a, b) => a > b ? a : b),
                  lastTotalReps: p.last.totalReps,
                )),
      ];
  }

  @override
  Future<WorkoutEntry> addEntry(String exerciseId, WorkoutEntryRequest req) async {
    _online();
    posted.add(req);
    if (saveError != null) throw saveError!;
    // Same id again = a retry: the API returns the existing entry.
    final existing = entries[exerciseId]?.where((e) => e.id == req.id).firstOrNull;
    if (existing != null) return existing;
    final entry = entryOf(req.id ?? 'e${_id++}', req.date, req.sets, req.notes);
    (entries[exerciseId] ??= []).add(entry);
    return entry;
  }

  @override
  Future<WorkoutEntry> updateEntry(String exerciseId, String entryId, WorkoutEntryRequest req) async {
    if (saveError != null) throw saveError!;
    final list = entries[exerciseId]!;
    final i = list.indexWhere((e) => e.id == entryId);
    return list[i] = entryOf(entryId, req.date, req.sets, req.notes);
  }

  @override
  Future<void> deleteEntry(String exerciseId, String entryId) async =>
      entries[exerciseId]?.removeWhere((e) => e.id == entryId);

  /// Records for [getStats]; days are computed from [entries].
  final records = <PersonalRecord>[];
  final bodyWeights = <BodyWeight>[];

  @override
  Future<WorkoutStats> getStats({DateTime? since}) async {
    _online();
    final byDay = <DateTime, List<WorkoutEntry>>{};
    for (final list in entries.values) {
      for (final e in list) {
        (byDay[e.date] ??= []).add(e);
      }
    }
    final days = byDay.keys.toList()..sort();
    return WorkoutStats(
      days: [
        for (final d in days)
          TrainingDay(
            date: d,
            volume: byDay[d]!.fold(0.0, (v, e) => v + e.volume),
            exercises: byDay[d]!.length,
            sets: byDay[d]!.fold(0, (n, e) => n + e.sets.length),
          ),
      ],
      records: records,
    );
  }

  @override
  Future<List<BodyWeight>> getBodyWeights({DateTime? since}) async {
    _online();
    return [...bodyWeights]..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> setBodyWeight(DateTime date, double kg) async {
    _online();
    bodyWeights
      ..removeWhere((w) => w.date == date)
      ..add(BodyWeight(date: date, kg: kg));
  }

  @override
  Future<void> deleteBodyWeight(DateTime date) async => bodyWeights.removeWhere((w) => w.date == date);
}
