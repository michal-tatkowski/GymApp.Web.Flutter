import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import 'exercise_api.dart';
import 'models/create_exercise_request.dart';
import 'models/exercise.dart';

/// Throws [Failure] subclasses — never raw Dio exceptions.
class ExerciseRepository {
  ExerciseRepository({required this.api});

  final ExerciseApi api;

  Future<List<Exercise>> getExercises({
    ExerciseCategory? category,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await api.getExercises(category: category, search: search, page: page, pageSize: pageSize);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }

  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    try {
      return await api.createExercise(req);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }
}
