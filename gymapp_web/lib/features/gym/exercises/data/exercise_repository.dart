import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import 'exercise_api.dart';
import 'models/create_exercise_request.dart';
import 'models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository({required this.api});

  final ExerciseApi api;

  Future<List<Exercise>> getExercises({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await api.getExercises(
        category: category,
        page: page,
        pageSize: pageSize,
      );
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    }
  }

  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    try {
      return await api.createExercise(req);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
