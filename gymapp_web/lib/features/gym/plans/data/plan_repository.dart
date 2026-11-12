import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import 'plan_models.dart';

/// api/Plans. Throws [Failure] subclasses — never raw Dio exceptions.
class PlanRepository {
  PlanRepository(this._dio);

  final Dio _dio;

  Future<List<WorkoutPlan>> getPlans() => _guard(() async {
        final res = await _dio.get<dynamic>('Plans');
        return (res.data as List).cast<Map<String, dynamic>>().map(WorkoutPlan.fromJson).toList();
      });

  Future<WorkoutPlan> create(PlanRequest req) => _guard(() async {
        final res = await _dio.post<dynamic>('Plans', data: req.toJson());
        return WorkoutPlan.fromJson(res.data as Map<String, dynamic>);
      });

  Future<WorkoutPlan> update(String id, PlanRequest req) => _guard(() async {
        final res = await _dio.put<dynamic>('Plans/$id', data: req.toJson());
        return WorkoutPlan.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> delete(String id) => _guard(() => _dio.delete<dynamic>('Plans/$id'));

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
