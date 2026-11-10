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
