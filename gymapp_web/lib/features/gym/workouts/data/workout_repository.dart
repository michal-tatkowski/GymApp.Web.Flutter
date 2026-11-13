import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import 'workout_models.dart';

/// api/Workouts. Throws [Failure] subclasses — never raw Dio exceptions.
class WorkoutRepository {
  WorkoutRepository(this._dio);

  final Dio _dio;

  Future<List<WorkoutSummary>> getSummaries() => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts');
        return (res.data as List).cast<Map<String, dynamic>>().map(WorkoutSummary.fromJson).toList();
      });

  Future<WorkoutLog> getLog(String exerciseId) => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/$exerciseId');
        return WorkoutLog.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<ProgressPoint>> getProgress(String exerciseId) => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/$exerciseId/progress');
        return (res.data as List).cast<Map<String, dynamic>>().map(ProgressPoint.fromJson).toList();
      });

  Future<WorkoutEntry> addEntry(String exerciseId, WorkoutEntryRequest req) => _guard(() async {
        final res = await _dio.post<dynamic>('Workouts/$exerciseId/entries', data: req.toJson());
        return WorkoutEntry.fromJson(res.data as Map<String, dynamic>);
      });

  Future<WorkoutEntry> updateEntry(String exerciseId, String entryId, WorkoutEntryRequest req) => _guard(() async {
        final res = await _dio.put<dynamic>('Workouts/$exerciseId/entries/$entryId', data: req.toJson());
        return WorkoutEntry.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deleteEntry(String exerciseId, String entryId) =>
      _guard(() => _dio.delete<dynamic>('Workouts/$exerciseId/entries/$entryId'));

  /// Training days and records since [since] (API default: 12 weeks).
  Future<WorkoutStats> getStats({DateTime? since}) => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/stats', queryParameters: {
          if (since != null) 'since': toApiDate(since),
        });
        return WorkoutStats.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<ExerciseRecords>> getRecords() => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/records');
        return (res.data as List).cast<Map<String, dynamic>>().map(ExerciseRecords.fromJson).toList();
      });

  /// History day by day, newest first: days [from]–[to] (API default: the last 30 days, at most 400).
  Future<List<TrainingDayDetails>> getDays({DateTime? from, DateTime? to}) => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/days', queryParameters: {
          if (from != null) 'from': toApiDate(from),
          if (to != null) 'to': toApiDate(to),
        });
        return (res.data as List).cast<Map<String, dynamic>>().map(TrainingDayDetails.fromJson).toList();
      });

  /// A finished session (its duration goes to the history). Idempotent by [id].
  Future<void> saveSession({
    required String id,
    required String name,
    required DateTime date,
    required DateTime startedAt,
    required DateTime finishedAt,
    String? planId,
  }) =>
      _guard(() => _dio.post<dynamic>('Workouts/sessions', data: {
            'id': id,
            if (planId != null) 'planId': planId,
            'name': name,
            'date': toApiDate(date),
            'startedAt': startedAt.toUtc().toIso8601String(),
            'finishedAt': finishedAt.toUtc().toIso8601String(),
          }));

  /// Mood (1–5) and note of a saved session; null clears.
  Future<void> setSessionFeedback(String id, {int? mood, String? note}) =>
      _guard(() => _dio.put<dynamic>('Workouts/sessions/$id/feedback', data: {'mood': mood, 'note': note}));

  /// This month's challenges with progress (proposed by the API on the first read of the month).
  Future<MonthChallenges> getChallenges() => _guard(() async {
        final res = await _dio.get<dynamic>('Challenges');
        return MonthChallenges.fromJson(res.data as Map<String, dynamic>);
      });

  /// Totals over the whole account, for the "All time" card and lifetime badges.
  Future<LifetimeStats> getLifetime() => _guard(() async {
        final res = await _dio.get<dynamic>('Workouts/lifetime');
        return LifetimeStats.fromJson(res.data as Map<String, dynamic>);
      });

  /// Body weight measurements, oldest first.
  Future<List<BodyWeight>> getBodyWeights({DateTime? since}) => _guard(() async {
        final res = await _dio.get<dynamic>('BodyWeight', queryParameters: {
          if (since != null) 'since': toApiDate(since),
        });
        return (res.data as List).cast<Map<String, dynamic>>().map(BodyWeight.fromJson).toList();
      });

  /// One per day: a second measurement the same day replaces the first.
  Future<void> setBodyWeight(DateTime date, double kg) =>
      _guard(() => _dio.put<dynamic>('BodyWeight/${toApiDate(date)}', data: {'weightKg': kg}));

  Future<void> deleteBodyWeight(DateTime date) =>
      _guard(() => _dio.delete<dynamic>('BodyWeight/${toApiDate(date)}'));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }
}
