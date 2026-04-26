import 'package:dio/dio.dart';

import 'models/create_exercise_request.dart';
import 'models/exercise.dart';

class ExerciseApi {
  ExerciseApi(this._dio);

  final Dio _dio;

  /// Returns exercises sorted by popularity.
  /// Supports optional [category] filter and [page]/[pageSize] for pagination.
  /// If the backend does not support pagination it will return all results —
  /// the repository handles that gracefully.
  Future<List<Exercise>> getExercises({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      'Exercise',
      queryParameters: {
        if (category != null) 'category': category,
        'page': page,
        'pageSize': pageSize,
      },
    );
    final list = res.data as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList(growable: false);
  }

  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    final res = await _dio.post<dynamic>('Exercise', data: req.toJson());
    return Exercise.fromJson(res.data as Map<String, dynamic>);
  }
}
