import 'package:dio/dio.dart';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/exercise_api.dart';
import 'package:gymapp_web/features/gym/exercises/data/exercise_repository.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/create_exercise_request.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';

Exercise _ex(String id, {ExerciseCategory category = ExerciseCategory.push, String? name}) =>
    Exercise(id: id, name: name ?? 'Ex $id', category: category);

/// Server stub: [total] exercises, paged; optional per-call delays to simulate races.
class _FakeRepo extends ExerciseRepository {
  _FakeRepo({this.total = 45}) : super(api: ExerciseApi(Dio()));

  final int total;
  final calls = <({ExerciseCategory? category, String? search, int page})>[];
  final delays = <String, Duration>{};
  Object? createError;

  @override
  Future<List<Exercise>> getExercises({ExerciseCategory? category, String? search, int page = 1, int pageSize = 20}) async {
    calls.add((category: category, search: search, page: page));
    final delay = delays[search ?? ''];
    if (delay != null) await Future<void>.delayed(delay);
    final all = List.generate(total, (i) => _ex('${search ?? ''}$i', category: category ?? ExerciseCategory.push));
    return all.skip((page - 1) * pageSize).take(pageSize).toList();
  }

  @override
  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    if (createError != null) throw createError!;
    return Exercise(id: 'new', name: req.name, category: req.category, isCustom: true);
  }
}

void main() {
  group('Exercise JSON contract', () {
    test('parses the API shape', () {
      final e = Exercise.fromJson({
        'id': 'a1',
        'name': 'Martwy ciąg',
        'category': 'Pull',
        'description': 'Opis',
        'imageUrl': null,
        'popularityCount': 3,
        'source': 'Community',
        'createdByUserId': 'u1',
        'isCustom': true,
      });

      expect(e.category, ExerciseCategory.pull);
      expect(e.description, 'Opis');
      expect(e.source, ExerciseSource.community);
      expect(e.isCustom, isTrue);
      expect(e.popularityCount, 3);
    });

    test('empty description is treated as missing; legacy numeric category still parses', () {
      final e = Exercise.fromJson({'id': 'a', 'name': 'x', 'category': '3', 'description': ''});
      expect(e.description, isNull);
      expect(e.category, ExerciseCategory.core);
      expect(ExerciseCategoryX.fromJson('weird'), ExerciseCategory.other);
    });

    test('create request sends the category name the API expects', () {
      final json = const CreateExerciseRequest(name: 'Plank', category: ExerciseCategory.core).toJson();
      expect(json['category'], 'Core');
    });
  });

  group('ExercisesNotifier', () {
    test('loads pages without duplicates and stops at the last page', () async {
      final repo = _FakeRepo(total: 45);
      final n = ExercisesNotifier(repo);
      await pumpEventQueue();

      await n.loadMore();
      await n.loadMore();
      await n.loadMore(); // no more pages

      expect(n.state.items.length, 45);
      expect(n.state.items.map((e) => e.id).toSet().length, 45);
      expect(n.state.hasMore, isFalse);
      expect(repo.calls.map((c) => c.page), [1, 2, 3]);
    });

    test('search is sent to the server, debounced', () {
      fakeAsync((async) {
        final repo = _FakeRepo();
        final n = ExercisesNotifier(repo);
        async.flushMicrotasks();

        n.setQuery('w');
        n.setQuery('wy');
        n.setQuery('wyc');
        async.elapse(searchDebounce + const Duration(milliseconds: 10));

        expect(repo.calls.map((c) => c.search), ['', 'wyc']);
        expect(n.state.items.first.id, startsWith('wyc'));
      });
    });

    test('a slow response for an old query does not overwrite the newer list', () {
      fakeAsync((async) {
        final repo = _FakeRepo()..delays['slow'] = const Duration(seconds: 2);
        final n = ExercisesNotifier(repo);
        async.flushMicrotasks();

        n.setQuery('slow');
        async.elapse(searchDebounce);
        n.setQuery('fast');
        async.elapse(const Duration(seconds: 3));

        expect(n.state.query, 'fast');
        expect(n.state.items.first.id, startsWith('fast'));
      });
    });

    test('category filter goes to the server', () async {
      final repo = _FakeRepo();
      final n = ExercisesNotifier(repo);
      await pumpEventQueue();

      await n.setCategory(ExerciseCategory.legs);

      expect(repo.calls.last.category, ExerciseCategory.legs);
      expect(n.state.items.every((e) => e.category == ExerciseCategory.legs), isTrue);
    });

    test('added exercise appears on top only when it matches the filter', () async {
      final repo = _FakeRepo();
      final n = ExercisesNotifier(repo);
      await pumpEventQueue();

      await n.addExercise(const CreateExerciseRequest(name: 'Plank', category: ExerciseCategory.push));
      expect(n.state.items.first.id, 'new');

      await n.setCategory(ExerciseCategory.legs);
      await n.addExercise(const CreateExerciseRequest(name: 'Plank', category: ExerciseCategory.push));
      expect(n.state.items.any((e) => e.id == 'new'), isFalse);
    });

    test('create failure is thrown to the caller and does not become a list error', () async {
      final repo = _FakeRepo()..createError = const ConflictFailure('Masz już ćwiczenie o tej nazwie.', 'ExerciseAlreadyExists');
      final n = ExercisesNotifier(repo);
      await pumpEventQueue();

      await expectLater(
        n.addExercise(const CreateExerciseRequest(name: 'x', category: ExerciseCategory.push)),
        throwsA(isA<ConflictFailure>()),
      );
      expect(n.state.error, isNull);
    });
  });
}
