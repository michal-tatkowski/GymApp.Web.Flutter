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
    bool favoritesOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      'Exercise',
      queryParameters: {
        if (category != null) 'category': category.apiName,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (favoritesOnly) 'favoritesOnly': true,
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

  /// Star / unstar (idempotent on the server). 404 when the exercise is not visible.
  Future<void> setFavorite(String exerciseId, bool favorite) async {
    final path = 'Exercise/$exerciseId/favorite';
    favorite ? await _dio.put<dynamic>(path) : await _dio.delete<dynamic>(path);
  }

  /// Persistent notes per exercise ("seat 4, wide grip"): exercise id → note.
  Future<Map<String, String>> getNotes() async {
    final res = await _dio.get<dynamic>('Exercise/notes');
    return {
      for (final n in (res.data as List).cast<Map<String, dynamic>>()) n['exerciseId'].toString(): n['note'] as String,
    };
  }

  /// Empty / null removes the note.
  Future<void> setNote(String exerciseId, String? note) =>
      _dio.put<dynamic>('Exercise/$exerciseId/note', data: {'note': note});

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
