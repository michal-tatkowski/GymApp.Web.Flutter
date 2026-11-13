
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/goals/goals_data.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/progress/compare_challenges.dart';
import 'package:gymapp_web/features/gym/session/routines.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

class _NoGoals extends GoalRepository {
  _NoGoals() : super(Dio());

  @override
  Future<List<Goal>> list() async => const [];
}

/// Ends the workout and its rest timer before the test ends (no timers left running).
void endSession(ProviderContainer c) {
  c.read(activeSessionProvider.notifier).discard();
  c.read(restTimerProvider.notifier).stop();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const bench = Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push);
  const dips = Exercise(id: 'dips', name: 'Dips', category: ExerciseCategory.push);
  const row = Exercise(id: 'row', name: 'Barbell row', category: ExerciseCategory.pull);

  /// Starts [plan] from Today; returns the exercise fake (notes) and the container.
  Future<(FakeExerciseRepository, ProviderContainer)> startPlan(WidgetTester tester, WorkoutPlan plan) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final exercises = FakeExerciseRepository(const [bench, dips, row]);
    await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
      exerciseRepositoryProvider.overrideWithValue(exercises),
      workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
      goalRepositoryProvider.overrideWithValue(_NoGoals()),
    ]);
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
    await tester.tap(find.byKey(Key('plan.start.${plan.id}')));
    await tester.pumpAndSettle();
    return (exercises, c);
  }

  Finder doneOf(int set) => find.descendant(of: find.byKey(Key('session.set$set')), matching: find.byKey(const Key('done')));

  const push = WorkoutPlan(id: 'p1', name: 'Push', items: [
    PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 8, repsMax: 8),
  ]);

  testWidgets('exercise note: added in a workout, kept for next time', (tester) async {
    final (exercises, c) = await startPlan(tester, push);

    await tester.tap(find.byKey(const Key('exerciseNote.add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exerciseNote.field')), '  Seat 4, wide grip ');
    await tester.tap(find.byKey(const Key('exerciseNote.save')));
    await tester.pumpAndSettle();

    expect(exercises.notes, {'bench': 'Seat 4, wide grip'});
    expect(find.text('Seat 4, wide grip'), findsOneWidget);
    expect(c.read(exerciseNotesProvider).value, {'bench': 'Seat 4, wide grip'});
    endSession(c);
  });

  testWidgets('swap: alternatives from the same muscle group; not after a set is done', (tester) async {
    final (_, c) = await startPlan(tester, push);

    await tester.tap(find.byKey(const Key('session.swap')));
    await tester.pumpAndSettle();
    expect(find.text('Instead of Bench press'), findsOneWidget);
    expect(find.text('Barbell row'), findsNothing); // pull: another group
    await tester.tap(find.text('Dips'));
    await tester.pumpAndSettle();

    final s = c.read(activeSessionProvider)!;
    expect((s.exercises.single.exerciseId, s.exercises.single.sets.length, s.exercises.single.repsMax), ('dips', 1, 8));
    expect(find.text('Swapped for Dips'), findsOneWidget);

    await tester.tap(doneOf(0));
    await tester.pump();
    expect(find.byKey(const Key('session.swap')), findsNothing);
    endSession(c);
  });

  testWidgets('timed set: 3 s to get ready, then the countdown ticks the set off', (tester) async {
    final (_, c) = await startPlan(
      tester,
      const WorkoutPlan(id: 'p2', name: 'Core', items: [
        PlanItem(exerciseId: 'plank', exerciseName: 'Plank', category: ExerciseCategory.core, sets: 2, tracking: Tracking.time),
      ]),
    );

    await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('timer'))));
    await tester.pump();
    expect(find.text('Get ready'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold it'), findsOneWidget);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    var sets = c.read(activeSessionProvider)!.exercises.single.sets;
    expect((sets[0].done, sets[0].durationSeconds), (true, 60));

    // "Finish now" after 20 s: only this set gets 20 s, the next one keeps its target.
    c.read(restTimerProvider.notifier).stop();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byKey(const Key('session.set1')), matching: find.byKey(const Key('timer'))));
    await tester.pump();
    for (var i = 0; i < 23; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.byKey(const Key('timedSet.finish')));
    await tester.pumpAndSettle();
    sets = c.read(activeSessionProvider)!.exercises.single.sets;
    expect((sets[1].done, sets[1].durationSeconds), (true, 20));
    endSession(c);
  });

  testWidgets('warm-up before the first set, stretching after the last', (tester) async {
    final (_, c) = await startPlan(tester, push);

    expect(find.text('Warm up first (5 min)'), findsOneWidget);
    expect(find.text('Arm circles, 10 each way'), findsOneWidget); // upper-body day
    await tester.tap(find.byKey(const Key('routine.warmUp.cardio')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.byKey(const Key('routine.coolDown')), findsNothing);

    await tester.tap(doneOf(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routine.warmUp')), findsNothing);
    expect(find.text('Stretch to finish (5 min)'), findsOneWidget);
    expect(find.text('Chest stretch in a doorway, 30 s'), findsOneWidget);
    endSession(c);
  });

  testWidgets('warm-up and stretching can be turned off', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.hide_routines': true});
    final (_, c) = await startPlan(tester, push);
    expect(find.byKey(const Key('routine.warmUp')), findsNothing);
    endSession(c);
  });

  test('routines follow what the workout trains', () {
    expect(warmUpFor([ExerciseCategory.legs]), contains(RoutineStep.legSwings));
    expect(coolDownFor([ExerciseCategory.legs]), contains(RoutineStep.hamstring));
    expect(coolDownFor([ExerciseCategory.push, ExerciseCategory.legs]), containsAll([RoutineStep.chest, RoutineStep.quad]));
  });

  group('this period vs. the previous one', () {
    TrainingDay day(DateTime d, {int sets = 10, double volume = 1000}) => TrainingDay(date: d, volume: volume, exercises: 2, sets: sets);

    test('week: the same number of days of the week before', () {
      final r = comparePeriods([
        day(DateTime(2026, 11, 9)), day(DateTime(2026, 11, 11)), // this week (Mon 9 – Thu 12)
        day(DateTime(2026, 11, 3)), day(DateTime(2026, 11, 6)), // last week: Tue in, Fri after "Thursday" out
      ], DateTime(2026, 11, 12), month: false);
      expect(r.current, (days: 2, sets: 20, volume: 2000.0));
      expect(r.previous, (days: 1, sets: 10, volume: 1000.0));
    });

    test('month: day 31 compares with the whole of a shorter month', () {
      final r = comparePeriods([day(DateTime(2026, 2, 28)), day(DateTime(2026, 3, 30))], DateTime(2026, 3, 31), month: true);
      expect((r.current.days, r.previous.days), (1, 1));
    });
  });

  group('goal forecast', () {
    final today = DateTime(2026, 11, 12);
    List<(DateTime, double)> weekly(double start, double perWeek, int weeks) =>
        [for (var w = weeks; w >= 0; w--) (today.subtract(Duration(days: 7 * w)), start + perWeek * (weeks - w))];

    test('steady progress → weeks to go; late when past the deadline', () {
      final points = weekly(100, 2.5, 6); // 100 → 115 kg
      expect(forecastGoal(points, 125, today), isA<ForecastWeeks>().having((f) => f.weeks, 'weeks', 4));
      expect(forecastGoal(points, 125, today, deadline: today.add(const Duration(days: 14))),
          isA<ForecastWeeks>().having((f) => f.late, 'late', true));
      expect(forecastGoal(points, 116, today), isA<ForecastSoon>());
    });

    test('losing body weight works the other way; flat or wrong way → no trend; little data → nothing', () {
      expect(forecastGoal(weekly(90, -0.5, 8), 84, today), isA<ForecastWeeks>().having((f) => f.weeks, 'weeks', 4));
      expect(forecastGoal(weekly(100, 0, 6), 110, today), isA<ForecastNoTrend>());
      expect(forecastGoal(weekly(100, -1, 6), 110, today), isA<ForecastNoTrend>());
      expect(forecastGoal(weekly(100, 2.5, 1), 110, today), isNull);
    });
  });

  group('monthly challenges (from the API)', () {
    testWidgets('card: progress per challenge, done ones marked, completed ones counted', (tester) async {
      final repo = FakeWorkoutRepository()
        ..challenges = MonthChallenges(month: DateTime(2026, 11), completedBefore: 2, challenges: const [
          Challenge(kind: ChallengeKind.workouts, target: 12, value: 5),
          Challenge(kind: ChallengeKind.sets, target: 100, value: 120, done: true),
          Challenge(kind: ChallengeKind.volume, target: 20000, value: 8500),
        ]);
      await pumpScreen(tester, const SingleChildScrollView(child: ChallengesCard()),
          overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text('Challenges · November'), findsOneWidget);
      expect(find.text('Train on 12 days'), findsOneWidget);
      expect(find.text('5 / 12'), findsOneWidget);
      expect(find.text('Done!'), findsOneWidget);
      expect(find.text('8,500 / 20,000 kg'), findsOneWidget);
      expect(find.text('3 challenges completed so far'), findsOneWidget); // 2 before + 1 now
    });

    testWidgets('older API or offline: no card', (tester) async {
      await pumpScreen(tester, const SingleChildScrollView(child: ChallengesCard()),
          overrides: [workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository())]);
      expect(find.byKey(const Key('today.challenges')), findsNothing);
    });
  });
}
