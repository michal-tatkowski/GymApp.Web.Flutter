import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_screen.dart';

import '../helpers/test_app.dart';

void main() {
  List<Exercise> catalog() => [
        const Exercise(id: '1', name: 'Bench press', category: ExerciseCategory.push, description: 'Flat bench'),
        const Exercise(id: '2', name: 'Deadlift', category: ExerciseCategory.pull),
        const Exercise(id: '3', name: 'Squat', category: ExerciseCategory.legs),
        const Exercise(
            id: '4', name: 'My plank', category: ExerciseCategory.core, isCustom: true, source: ExerciseSource.community),
      ];

  Future<FakeExerciseRepository> pump(WidgetTester tester, [List<Exercise>? items]) async {
    final repo = FakeExerciseRepository(items ?? catalog());
    await pumpScreen(tester, const ExercisesScreen(),
        overrides: [exerciseRepositoryProvider.overrideWithValue(repo)]);
    return repo;
  }

  testWidgets('lists exercises with category labels; custom ones are marked', (tester) async {
    await pump(tester);

    for (final name in ['Bench press', 'Deadlift', 'Squat', 'My plank']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.byIcon(Icons.person_outline), findsOneWidget); // only "My plank" is custom
  });

  testWidgets('category chip filters on the server', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Legs'));
    await tester.pumpAndSettle();

    expect(repo.queries.last.category, ExerciseCategory.legs);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Deadlift'), findsNothing);
  });

  testWidgets('search is debounced and sent to the server', (tester) async {
    final repo = await pump(tester);
    final before = repo.queries.length;

    await tester.enterText(find.byType(TextField), 'dead');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.queries.length, before); // not yet — debounce

    await tester.pumpAndSettle(searchDebounce);
    expect(repo.queries.last.search, 'dead');
    expect(find.text('Deadlift'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    await pump(tester, []);

    expect(find.text('No exercises found'), findsOneWidget);
  });

  testWidgets('tapping an exercise opens its details with the description', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();

    expect(find.text('Flat bench'), findsOneWidget);
  });

  testWidgets('add sheet creates the exercise and shows it on top', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Exercise name'), 'Pull-up');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise added'), findsOneWidget);
    expect(find.text('Pull-up'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing); // sheet closed
  });

  testWidgets('add sheet: name is required', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('add sheet: 409 from the API keeps the sheet open with the message', (tester) async {
    final repo = await pump(tester);
    repo.createError = const ConflictFailure('You already have an exercise with this name.', 'ExerciseAlreadyExists');

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Exercise name'), 'My plank');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('You already have an exercise with this name.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget); // still open
  });
}
