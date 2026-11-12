import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/history/history_screen.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('a day becomes a one-off plan: same exercises, number of sets and reps range', () {
    final day = TrainingDayDetails(date: today, exercises: [
      DayExercise(
        exerciseId: 'bench',
        exerciseName: 'Bench',
        category: ExerciseCategory.push,
        tracking: Tracking.weight,
        entries: [
          FakeWorkoutRepository.entryOf('e1', today, const [WorkoutSet(reps: 10, weight: 60), WorkoutSet(reps: 8, weight: 70)], null),
        ],
      ),
      DayExercise(
        exerciseId: 'plank',
        exerciseName: 'Plank',
        category: ExerciseCategory.core,
        tracking: Tracking.time,
        entries: [FakeWorkoutRepository.entryOf('e2', today, const [WorkoutSet(reps: 0, weight: 0, durationSeconds: 60)], null)],
      ),
    ]);

    final plan = planFromDay(day, 'Again');
    expect(plan.id, isEmpty);
    expect(plan.items.map((i) => (i.exerciseId, i.sets, i.repsMin, i.repsMax, i.tracking)), [
      ('bench', 2, 8, 10, Tracking.weight),
      ('plank', 1, 1, 1, Tracking.time),
    ]);
  });

  testWidgets('history lists days with their sets; Repeat starts the same workout', (tester) async {
    tall(tester);
    final repo = FakeWorkoutRepository()
      ..seed('bench', today.subtract(const Duration(days: 2)), const [WorkoutSet(reps: 5, weight: 100)])
      ..seed('squat', today.subtract(const Duration(days: 2)), const [WorkoutSet(reps: 5, weight: 120), WorkoutSet(reps: 5, weight: 120)])
      ..seed('bench', today.subtract(const Duration(days: 9)), const [WorkoutSet(reps: 6, weight: 95)]);
    await pumpScreen(tester, const HistoryScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);
    final c = ProviderScope.containerOf(tester.element(find.byType(HistoryScreen)));

    final recent = toApiDate(today.subtract(const Duration(days: 2)));
    expect(find.byKey(Key('history.day.$recent')), findsOneWidget);
    expect(find.byKey(Key('history.day.${toApiDate(today.subtract(const Duration(days: 9)))}')), findsOneWidget);
    expect(find.text('2 × 5 × 120 kg'), findsOneWidget);
    expect(find.textContaining('3 sets'), findsOneWidget);

    await tester.tap(find.byKey(Key('history.repeat.$recent')));
    await tester.pumpAndSettle();
    final session = c.read(activeSessionProvider)!;
    expect(session.planId, isNull);
    expect(session.exercises.map((e) => (e.exerciseId, e.sets.length)), [('bench', 1), ('squat', 2)]);
    c.read(restTimerProvider.notifier).stop();
  });

  testWidgets('Today offers to repeat the last workout; finishing records the session', (tester) async {
    tall(tester);
    final repo = FakeWorkoutRepository()
      ..seed('bench', today.subtract(const Duration(days: 1)), const [WorkoutSet(reps: 5, weight: 100)]);
    await pumpScreen(tester, const TodayScreen(), overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(repo),
    ]);
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));

    await tester.tap(find.byKey(const Key('today.repeatLast')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('session.finish')));
    await tester.pumpAndSettle();

    expect(repo.posted, hasLength(1));
    expect(repo.sessions.single.date, today);
    expect(repo.sessions.single.name, startsWith('Workout of'));
    c.read(restTimerProvider.notifier).stop();
  });

  testWidgets('a ready-made plan opens filled in and is saved as the user\'s own', (tester) async {
    tall(tester);
    final plans = FakePlanRepository()
      ..templates = const [
        PlanTemplate(key: 'fbw', name: 'Full body', description: 'Three times a week', daysPerWeek: 3, items: [
          PlanItem(exerciseId: 'squat', exerciseName: 'Squat', category: ExerciseCategory.legs, sets: 3, repsMin: 8, repsMax: 10,
              supersetWithNext: true),
          PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 3, repsMin: 8, repsMax: 10),
        ]),
      ];
    await pumpScreen(tester, const TodayScreen(), plans: plans, overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
    ]);

    await tester.tap(find.byKey(const Key('plans.new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plans.new.template')));
    await tester.pumpAndSettle();
    expect(find.text('Full body'), findsOneWidget);
    await tester.tap(find.text('Full body'));
    await tester.pumpAndSettle();
    expect(find.text('Three times a week'), findsOneWidget);
    await tester.tap(find.byKey(const Key('template.use.fbw')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byKey(const Key('plan.name'))).controller!.text, 'Full body');
    await tester.tap(find.byKey(const Key('plan.save')));
    await tester.pumpAndSettle();
    final saved = plans.saved.single;
    expect(saved.items.map((i) => (i.exerciseId, i.supersetWithNext)), [('squat', true), ('bench', false)]);
  });
}
