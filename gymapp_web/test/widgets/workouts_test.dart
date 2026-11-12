import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
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
    expect(find.text('1200 kg'), findsWidgets); // latest value (big number) and newest history entry
    expect(find.text('+20%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.widgetWithText(SegmentedButton<ProgressMetric>, 'Volume'), findsOneWidget);
    expect(find.text('1200 kg'), findsNWidgets(2)); // big number + newest history entry
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

  testWidgets('delete is immediate and can be undone', (tester) async {
    final repo = await pumpLog(tester, (r) => r.seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]));

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing); // no confirmation dialog
    expect(repo.entries[bench], isEmpty);
    expect(find.text('Workout deleted'), findsOneWidget);
    expect(find.text('10×100 kg'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repo.entries[bench]!.single.sets, const [WorkoutSet(reps: 10, weight: 100)]);
    expect(find.text('10×100 kg'), findsOneWidget);
  });

  testWidgets('"Repeat last" saves today in one tap and can be undone', (tester) async {
    final repo = await pumpLog(tester,
        (r) => r.seed(bench, today.subtract(const Duration(days: 1)), [const WorkoutSet(reps: 12, weight: 100)]));

    expect(find.text('Repeat last: 12×100 kg'), findsOneWidget);
    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();

    expect(repo.entries[bench]!.length, 2);
    expect(repo.entries[bench]!.last.date, today);
    expect(find.text('Workout saved'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.entries[bench]!.length, 1);
  });

  testWidgets('−/+ change reps by 1 and weight by 2.5 kg', (tester) async {
    await pumpLog(tester, (r) => r.seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]));

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Increase by 1').first);
    await tester.tap(find.bySemanticsLabel('Increase by 2.5').first);
    await tester.tap(find.bySemanticsLabel('Increase by 2.5').first);
    await tester.tap(find.bySemanticsLabel('Decrease by 1').first);
    await tester.tap(find.bySemanticsLabel('Decrease by 1').first);
    await tester.pump();

    expect(tester.widget<TextFormField>(find.byKey(const Key('workout.set0.reps'))).controller!.text, '9');
    expect(tester.widget<TextFormField>(find.byKey(const Key('workout.set0.weight'))).controller!.text, '105');
  });

  testWidgets('bodyweight exercise charts reps', (tester) async {
    await pumpLog(tester, (r) {
      r.seed(bench, today.subtract(const Duration(days: 1)), [const WorkoutSet(reps: 20, weight: 0)]);
      r.seed(bench, today, [const WorkoutSet(reps: 25, weight: 0)]);
    });

    expect(find.byKey(const Key('progress.metric')), findsNothing); // reps is the only metric
    expect(find.byKey(const Key('progress.value')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('progress.value'))).data, '25');
    expect(find.text('+25%'), findsOneWidget);
    expect(find.text('25 reps'), findsOneWidget);
  });

  group('My workouts', () {
    testWidgets('lists trained exercises with last and best volume', (tester) async {
      tester.view.physicalSize = const Size(500, 1600); // below the activity and badge cards
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeWorkoutRepository()
        ..seed(bench, today.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 12, weight: 100)])
        ..seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]);
      await pumpScreen(tester, const MyWorkoutsScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('Bench press'), findsOneWidget);
      expect(find.textContaining('2 training days'), findsOneWidget);
      expect(find.text('1000 kg'), findsOneWidget);
      expect(find.text('best 1200 kg'), findsOneWidget);
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

  group('one screen per exercise', () {
    const exercise = Exercise(
      id: bench,
      name: 'Bench press',
      category: ExerciseCategory.push,
      description: 'Flat bench, bar to mid-chest.',
    );

    Future<FakeExerciseRepository> pumpExercise(WidgetTester tester, {required bool trained}) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final workouts = FakeWorkoutRepository();
      if (trained) workouts.seed(bench, today, [const WorkoutSet(reps: 10, weight: 100)]);
      final exercises = FakeExerciseRepository([exercise]);
      await pumpScreen(tester, ExerciseWorkoutsScreen.forExercise(exercise), overrides: [
        workoutRepositoryProvider.overrideWithValue(workouts),
        exerciseRepositoryProvider.overrideWithValue(exercises),
      ]);
      return exercises;
    }

    testWidgets('description is open before the first workout, folded after', (tester) async {
      await pumpExercise(tester, trained: false);
      expect(find.text('Flat bench, bar to mid-chest.'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget); // category chip

      await pumpExercise(tester, trained: true);
      expect(find.text('Flat bench, bar to mid-chest.'), findsNothing);
      await tester.tap(find.text('About this exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Flat bench, bar to mid-chest.'), findsOneWidget);
    });

    testWidgets('star works without the catalog list open (e.g. from Today)', (tester) async {
      final repo = await pumpExercise(tester, trained: true);

      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pumpAndSettle();

      expect(repo.favoriteCalls, [(bench, true)]);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });

    testWidgets('from the Progress tab (no exercise data): just the log, no star', (tester) async {
      await pumpLog(tester);
      expect(find.byTooltip('Add to favorites'), findsNothing);
      expect(find.text('About this exercise'), findsNothing);
    });
  });

  testWidgets('holding + keeps adding 2.5 kg; a tap adds one step', (tester) async {
    await pumpLog(tester);
    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    String weight() => tester.widget<TextFormField>(find.byKey(const Key('workout.set0.weight'))).controller!.text;
    final plus = find.descendant(of: find.byKey(const Key('workout.set0.weight')), matching: find.byIcon(Icons.add));

    await tester.tap(plus);
    await tester.pump();
    expect(weight(), '2.5');

    final gesture = await tester.startGesture(tester.getCenter(plus));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10)); // long press recognized: +1 step
    await tester.pump(const Duration(milliseconds: 450)); // then every 100 ms: +4 steps
    await gesture.up();
    await tester.pump(const Duration(seconds: 1)); // stopped
    expect(weight(), '15');
  });

  testWidgets('"Log workout" shrinks to its icon while scrolling down, grows back scrolling up', (tester) async {
    await pumpLog(tester, (r) {
      for (var d = 1; d <= 30; d++) {
        r.seed(bench, today.subtract(Duration(days: d)), [const WorkoutSet(reps: 10, weight: 100)]);
      }
    });
    bool extended() => tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).isExtended;
    expect(extended(), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(extended(), isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(extended(), isTrue);
  });
}
