import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/my_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/widgets/progress_chart.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  const bench = 'bench';

  Future<FakeWorkoutRepository> pumpLog(WidgetTester tester, [void Function(FakeWorkoutRepository)? seed]) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = FakeWorkoutRepository();
    seed?.call(repo);
    await pumpScreen(tester, const ExerciseWorkoutsScreen(exerciseId: bench, exerciseName: 'Bench press'),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);
    return repo;
  }

  Future<void> fillSet(WidgetTester tester, int i, String reps, String weight) async {
    await tester.enterText(find.byKey(Key('workout.set$i.reps')), reps);
    await tester.enterText(find.byKey(Key('workout.set$i.weight')), weight);
  }

  testWidgets('10×100 → 10×100 → 12×100: the chart goes up', (tester) async {
    await pumpLog(tester, (r) {
      r.seed(bench, today.subtract(const Duration(days: 3)), [const WorkoutSet(reps: 10, weight: 100)]);
      r.seed(bench, today.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 10, weight: 100)]);
      r.seed(bench, today.subtract(const Duration(days: 1)), [const WorkoutSet(reps: 12, weight: 100)]);
    });

    expect(find.byKey(const Key('progress.chart')), findsOneWidget);
    expect(find.text('1000 → 1200'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.text('Volume (kg)'), findsOneWidget);
    expect(find.text('1200 kg'), findsOneWidget); // newest entry on top of the history
  });

  testWidgets('empty log: hint instead of a chart, "Log workout" saves the first entry', (tester) async {
    final repo = await pumpLog(tester);
    expect(find.text('No workouts for this exercise yet.'), findsOneWidget);
    expect(find.text('Log at least two training days to see the trend.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await fillSet(tester, 0, '10', '100');
    await tester.tap(find.text('Add set')); // copies the previous set
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    final saved = repo.entries[bench]!.single;
    expect(saved.sets, const [WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 10, weight: 100)]);
    expect(saved.date, today);
    expect(find.text('Workout saved'), findsOneWidget);
    expect(find.text('2 × 10 × 100 kg'), findsOneWidget);
    expect(find.text('2000 kg'), findsOneWidget);
  });

  testWidgets('new entry starts from the last workout\'s sets', (tester) async {
    await pumpLog(tester, (r) => r.seed(bench, today.subtract(const Duration(days: 1)),
        [const WorkoutSet(reps: 8, weight: 105), const WorkoutSet(reps: 6, weight: 110)]));

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextFormField>(find.byKey(const Key('workout.set0.reps'))).controller!.text, '8');
    expect(tester.widget<TextFormField>(find.byKey(const Key('workout.set1.weight'))).controller!.text, '110');
  });

  testWidgets('invalid reps are caught by the form; nothing is sent', (tester) async {
    final repo = await pumpLog(tester);

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await fillSet(tester, 0, '0', '100');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value between 1 and 1000'), findsOneWidget);
    expect(repo.entries[bench], isNull);
  });

  testWidgets('API error keeps the sheet open with the message', (tester) async {
    final repo = await pumpLog(tester);
    repo.saveError = const ValidationFailure('Invalid workout date (it cannot be in the future).');

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await fillSet(tester, 0, '10', '100');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid workout date (it cannot be in the future).'), findsOneWidget);
    expect(find.byKey(const Key('workout.save')), findsOneWidget);
  });

  testWidgets('tapping an entry edits it', (tester) async {
    final repo = await pumpLog(tester, (r) => r.seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]));

    await tester.tap(find.text('10×100 kg'));
    await tester.pumpAndSettle();
    expect(find.text('Edit workout'), findsOneWidget);
    await fillSet(tester, 0, '12', '100');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(repo.entries[bench]!.single.sets.single.reps, 12);
    expect(find.text('12×100 kg'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation', (tester) async {
    final repo = await pumpLog(tester, (r) => r.seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]));

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this workout?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.entries[bench], isEmpty);
    expect(find.text('Workout deleted'), findsOneWidget);
  });

  testWidgets('bodyweight exercise charts reps', (tester) async {
    await pumpLog(tester, (r) {
      r.seed(bench, today.subtract(const Duration(days: 1)), [const WorkoutSet(reps: 20, weight: 0)]);
      r.seed(bench, today, [const WorkoutSet(reps: 25, weight: 0)]);
    });

    expect(find.text('Reps (bodyweight)'), findsOneWidget);
    expect(find.text('20 → 25'), findsOneWidget);
    expect(find.text('25 reps'), findsOneWidget);
  });

  group('My workouts', () {
    testWidgets('lists trained exercises with last and best volume', (tester) async {
      final repo = FakeWorkoutRepository()
        ..seed(bench, today.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 12, weight: 100)])
        ..seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]);
      await pumpScreen(tester, const MyWorkoutsScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('Bench press'), findsOneWidget);
      expect(find.textContaining('2 training days'), findsOneWidget);
      expect(find.text('1000 kg'), findsOneWidget);
      expect(find.text('best 1200'), findsOneWidget);
    });

    testWidgets('empty state points to the exercises', (tester) async {
      await pumpScreen(tester, const MyWorkoutsScreen(),
          overrides: [workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository())]);

      expect(find.textContaining('No workouts yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Exercises'), findsOneWidget);
    });
  });

  test('chart metric: volume, or reps when everything is bodyweight', () {
    ProgressPoint p(double volume, int reps) =>
        ProgressPoint(date: DateTime(2026), volume: volume, totalReps: reps, maxWeight: 0, sets: 1);

    expect(metricFor([p(1000, 10), p(0, 12)]), ProgressMetric.volume);
    expect(metricFor([p(0, 10), p(0, 12)]), ProgressMetric.reps);
  });
}
