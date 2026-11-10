import 'package:dio/dio.dart';

import 'models/create_exercise_request.dart';
import 'models/exercise.dart';

class ExerciseApi {
  ExerciseApi(this._dio);

  final Dio _dio;

  /// One page of exercises, sorted by popularity. Filtering by [category] and
  /// searching by name ([search]) happen on the server, so pages stay consistent.
  /// The last page has fewer than [pageSize] items.
  Future<List<Exercise>> getExercises({
    ExerciseCategory? category,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      'Exercise',
      queryParameters: {
        if (category != null) 'category': category.apiName,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
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

  /// Creates a custom exercise; the API returns it in the same shape as the list.
  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    final res = await _dio.post<dynamic>('Exercise', data: req.toJson());
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected create exercise response');
    }
    return Exercise.fromJson(data);
  }
}
