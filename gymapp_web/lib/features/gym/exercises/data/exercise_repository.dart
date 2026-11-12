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
    bool favoritesOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await api.getExercises(
          category: category, search: search, favoritesOnly: favoritesOnly, page: page, pageSize: pageSize);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }

  Future<void> setFavorite(String exerciseId, bool favorite) async {
    try {
      await api.setFavorite(exerciseId, favorite);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    }
  }

  Future<Map<String, String>> getNotes() async {
    try {
      return await api.getNotes();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }

  Future<void> setNote(String exerciseId, String? note) async {
    try {
      await api.setNote(exerciseId, note);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
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
