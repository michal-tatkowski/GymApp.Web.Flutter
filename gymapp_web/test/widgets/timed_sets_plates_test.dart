import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/measures.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/session/plate_calculator.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('time and distance', () {
    test('format and parse', () {
      expect([45, 90, 3723].map(formatDuration), ['45 s', '1:30', '1:02:03']);
      expect(['1:30', '90', '1:02:03', '45 s', '', 'a:b'].map(parseDuration), [90, 90, 3723, 45, null, null]);
      expect(formatDistance(800), '800 m');
      expect(formatDistance(5000), '5 km');
      expect(formatDistance(5250, decimalSeparator: ','), '5,3 km');
      expect(formatPace(1500, 5000), '5:00 /km');
    });

    test('sets are described by time or distance', () {
      expect(ExerciseWorkoutsScreen.describeSets(const [
        WorkoutSet(reps: 0, weight: 0, durationSeconds: 60),
        WorkoutSet(reps: 0, weight: 0, durationSeconds: 60),
      ]), '2 × 1:00');
      expect(ExerciseWorkoutsScreen.describeSets(const [WorkoutSet(reps: 0, weight: 10, durationSeconds: 45)]), '45 s × 10 kg');
      expect(ExerciseWorkoutsScreen.describeSets(const [WorkoutSet(reps: 0, weight: 0, durationSeconds: 1500, distanceMeters: 5000)]),
          '5 km · 25:00');
    });

    testWidgets('a timed exercise is logged with a time, no reps', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeWorkoutRepository();
      await pumpScreen(
        tester,
        const ExerciseWorkoutsScreen(
          exerciseId: 'plank',
          exerciseName: 'Plank',
          exercise: Exercise(id: 'plank', name: 'Plank', category: ExerciseCategory.core, tracking: Tracking.time),
        ),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );

      await tester.tap(find.byKey(const Key('workout.log')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workout.set0.reps')), findsNothing);
      await tester.enterText(find.byKey(const Key('workout.set0.time')), '1:30');
      await tester.tap(find.byKey(const Key('workout.save')));
      await tester.pumpAndSettle();

      final set = repo.posted.single.sets.single;
      expect((set.reps, set.durationSeconds, set.distanceMeters), (0, 90, null));
      ProviderScope.containerOf(tester.element(find.byType(ExerciseWorkoutsScreen))).read(restTimerProvider.notifier).stop();
    });

    testWidgets('a distance exercise takes km and time', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeWorkoutRepository();
      await pumpScreen(
        tester,
        const ExerciseWorkoutsScreen(
          exerciseId: 'run',
          exerciseName: 'Run',
          exercise: Exercise(id: 'run', name: 'Run', category: ExerciseCategory.cardio, tracking: Tracking.distance),
        ),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );

      await tester.tap(find.byKey(const Key('workout.log')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('workout.set0.distance')), '5,2');
      await tester.enterText(find.byKey(const Key('workout.set0.time')), '26:00');
      await tester.tap(find.byKey(const Key('workout.save')));
      await tester.pumpAndSettle();

      final set = repo.posted.single.sets.single;
      expect((set.distanceMeters, set.durationSeconds), (5200.0, 1560));
      ProviderScope.containerOf(tester.element(find.byType(ExerciseWorkoutsScreen))).read(restTimerProvider.notifier).stop();
    });
  });

  group('plate calculator', () {
    test('greedy from the heaviest plate, per side', () {
      expect(platesPerSide(100, 20, WeightUnit.kg).plates, [25, 15]);
      expect(platesPerSide(102.5, 20, WeightUnit.kg).plates, [25, 15, 1.25]);
      expect(platesPerSide(225, 45, WeightUnit.lb).plates, [45, 45]);
      expect(platesPerSide(20, 20, WeightUnit.kg).plates, isEmpty);
      final odd = platesPerSide(101, 20, WeightUnit.kg);
      expect(odd.plates, [25.0, 15.0]);
      expect(odd.remainder, 1.0);
    });

    testWidgets('tapping the weight in a workout opens it; the bar choice is remembered', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = DateUtils.dateOnly(DateTime.now());
      final workouts = FakeWorkoutRepository()
        ..seed('bench', today.subtract(const Duration(days: 3)), const [WorkoutSet(reps: 5, weight: 100)]);
      const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
        PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 5, repsMax: 8),
      ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.text('100')));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const Key('plates.perSide'))).data, '25 + 15');

      await tester.tap(find.text('15 kg'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const Key('plates.perSide'))).data, '25 + 15 + 2.5');
      expect((await SharedPreferences.getInstance()).getDouble('settings.bar_weight.kg'), 15);
    });

    testWidgets('a timed exercise in a workout steps its time', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final workouts = FakeWorkoutRepository();
      const plan = WorkoutPlan(id: 'p1', name: 'Core', items: [
        PlanItem(exerciseId: 'plank', exerciseName: 'Plank', category: ExerciseCategory.core, sets: 2, repsMin: 1, repsMax: 1,
            tracking: Tracking.time),
      ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      expect(find.text('Target: 2 sets'), findsOneWidget);
      expect(find.byKey(const Key('session.warmUp')), findsNothing);
      await tester.tap(find.descendant(
          of: find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('time'))),
          matching: find.byKey(const Key('plus'))));
      await tester.pump();
      expect(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.text('1:15')), findsOneWidget);

      await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
      await tester.pump();
      await tester.tap(find.byKey(const Key('session.finish')));
      await tester.pumpAndSettle();
      final set = workouts.posted.single.sets.single;
      expect((set.reps, set.durationSeconds), (0, 75));
      c.read(restTimerProvider.notifier).stop();
    });
  });
}
