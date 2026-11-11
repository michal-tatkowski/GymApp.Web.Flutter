import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  List<Exercise> catalog() => [
        const Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push),
        const Exercise(id: 'squat', name: 'Squat', category: ExerciseCategory.legs, isFavorite: true),
        const Exercise(id: 'row', name: 'Barbell row', category: ExerciseCategory.pull),
      ];

  Future<FakeExerciseRepository> pump(WidgetTester tester) async {
    final repo = FakeExerciseRepository(catalog());
    await pumpScreen(tester, const ExercisesScreen(),
        overrides: [
          exerciseRepositoryProvider.overrideWithValue(repo),
          workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()), // opened exercise loads its log
        ]);
    return repo;
  }

  Finder starOf(String name) => find.descendant(
        of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
        matching: find.byType(IconButton),
      );

  testWidgets('favorites are listed first and show a filled star', (tester) async {
    await pump(tester);

    final names = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title as Text).data).toList();
    expect(names.first, 'Squat');
    expect(find.descendant(of: starOf('Squat'), matching: find.byIcon(Icons.star)), findsOneWidget);
    expect(find.descendant(of: starOf('Bench press'), matching: find.byIcon(Icons.star_border)), findsOneWidget);
  });

  testWidgets('tapping the star stars the exercise on the server and in the UI', (tester) async {
    final repo = await pump(tester);

    await tester.tap(starOf('Bench press'));
    await tester.pumpAndSettle();

    expect(repo.favoriteCalls, [('bench', true)]);
    expect(find.descendant(of: starOf('Bench press'), matching: find.byIcon(Icons.star)), findsOneWidget);
  });

  testWidgets('failed toggle reverts the star and shows the error', (tester) async {
    final repo = await pump(tester);
    repo.favoriteError = const NetworkFailure();

    await tester.tap(starOf('Bench press'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: starOf('Bench press'), matching: find.byIcon(Icons.star_border)), findsOneWidget);
    expect(find.text('No internet connection.'), findsOneWidget);
  });

  testWidgets('"Favorites" chip shows only starred exercises; unstarring removes the row', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(starOf('Squat'));
    await tester.pumpAndSettle();

    expect(repo.favoriteCalls, [('squat', false)]);
    expect(find.text('Squat'), findsNothing);
  });

  testWidgets('star in the details stays in sync with the list', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(repo.favoriteCalls, [('bench', true)]);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.descendant(of: starOf('Bench press'), matching: find.byIcon(Icons.star)), findsOneWidget);
  });
}
