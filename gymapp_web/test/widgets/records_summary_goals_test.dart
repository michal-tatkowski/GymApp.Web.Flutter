import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/goals/goals_card.dart';
import 'package:gymapp_web/features/gym/goals/goals_data.dart';
import 'package:gymapp_web/features/gym/progress/records_screen.dart';
import 'package:gymapp_web/features/gym/progress/summary_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

class FakeGoalRepository extends GoalRepository {
  FakeGoalRepository([List<Goal>? goals]) : goals = [...?goals], super(Dio());

  final List<Goal> goals;
  final created = <Goal>[];
  final achieved = <String>[];

  @override
  Future<List<Goal>> list() async => List.of(goals);

  @override
  Future<Goal> create(Goal goal) async {
    created.add(goal);
    final saved = Goal(
      id: 'g${goals.length}',
      kind: goal.kind,
      target: goal.target,
      exerciseId: goal.exerciseId,
      exerciseName: goal.exerciseId == null ? null : 'Bench press',
      startValue: goal.startValue,
      deadline: goal.deadline,
    );
    goals.add(saved);
    return saved;
  }

  @override
  Future<Goal> update(Goal goal, {bool? achieved}) async {
    if (achieved == true) this.achieved.add(goal.id);
    final i = goals.indexWhere((g) => g.id == goal.id);
    goals[i] = Goal(
      id: goal.id,
      kind: goal.kind,
      target: goal.target,
      exerciseId: goal.exerciseId,
      exerciseName: goal.exerciseName,
      startValue: goal.startValue,
      achievedAt: achieved == true ? DateTime.now() : null,
    );
    return goals[i];
  }

  @override
  Future<void> delete(String id) async => goals.removeWhere((g) => g.id == id);
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  ExerciseRecords bench({double heaviest = 90}) => ExerciseRecords(
        exerciseId: 'bench',
        exerciseName: 'Bench press',
        category: ExerciseCategory.push,
        tracking: Tracking.weight,
        trainingDays: 12,
        lastDate: today,
        bestOneRepMax: RecordValue(value: 105, date: today.subtract(const Duration(days: 20)), reps: 5, weight: 90),
        heaviestWeight: RecordValue(value: heaviest, date: today.subtract(const Duration(days: 20)), reps: 5, weight: heaviest),
        bestDayVolume: RecordValue(value: 2400, date: today.subtract(const Duration(days: 5))),
        mostReps: RecordValue(value: 15, date: today.subtract(const Duration(days: 40)), reps: 15, weight: 50),
      );

  group('goal progress', () {
    test('from the start value to the target, both directions', () {
      const lift = Goal(id: '1', kind: GoalKind.exerciseWeight, target: 100, startValue: 80);
      expect(goalProgress(lift, 90).fraction, 0.5);
      expect(goalProgress(lift, 105).reached, isTrue);
      const cut = Goal(id: '2', kind: GoalKind.bodyWeight, target: 80, startValue: 90);
      expect(goalProgress(cut, 85).fraction, 0.5);
      expect(goalProgress(cut, 92).fraction, 0);
      const weekly = Goal(id: '3', kind: GoalKind.weeklyWorkouts, target: 3);
      expect(goalProgress(weekly, 2).fraction, closeTo(0.667, 0.001));
      expect(goalProgress(weekly, null).fraction, 0);
    });
  });

  test('period summary counts days, sets, time and the most trained exercises', () {
    TrainingDayDetails day(int d, List<String> names, {int minutes = 0}) => TrainingDayDetails(
          date: DateTime(2026, 11, d),
          exercises: [
            for (final n in names)
              DayExercise(
                exerciseId: n,
                exerciseName: n,
                category: ExerciseCategory.push,
                tracking: Tracking.weight,
                entries: [FakeWorkoutRepository.entryOf(n, DateTime(2026, 11, d), const [WorkoutSet(reps: 10, weight: 50)], null)],
              ),
          ],
          sessions: [
            if (minutes > 0)
              WorkoutSessionInfo(id: 's$d', name: 'P', startedAt: DateTime(2026, 11, d, 18), finishedAt: DateTime(2026, 11, d, 18, minutes)),
          ],
        );
    final s = summarize(
      [day(3, ['Squat', 'Bench'], minutes: 50), day(5, ['Squat'], minutes: 40), day(7, ['Row'])],
      [PersonalRecord(date: DateTime(2026, 11, 5), exerciseId: 'squat', exerciseName: 'Squat', oneRepMax: true)],
      DateTime(2026, 11),
      DateTime(2026, 11, 30),
    );
    expect((s.workouts, s.sets, s.volumeKg, s.minutes, s.records), (3, 4, 2000.0, 90, 1));
    expect(s.topExercises.first, ('Squat', 2));
  });

  testWidgets('records screen shows the bests with their dates', (tester) async {
    tall(tester);
    final repo = FakeWorkoutRepository()..exerciseRecords = [bench()];
    await pumpScreen(tester, const RecordsScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('105 kg (5 × 90 kg)'), findsOneWidget);
    expect(find.text('15 × 50 kg'), findsOneWidget);
    expect(find.text('2,400 kg'), findsOneWidget);
  });

  testWidgets('summary of this month with the share button', (tester) async {
    tall(tester);
    final repo = FakeWorkoutRepository()
      ..seed('Squat', today, const [WorkoutSet(reps: 5, weight: 100), WorkoutSet(reps: 5, weight: 100)]);
    await pumpScreen(tester, const SummaryScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    expect(find.byKey(const Key('summary.card')), findsOneWidget);
    expect(find.text('1. Squat · 1 training day'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const Key('summary.next'))).onPressed, isNull); // no future months
    expect(tester.widget<IconButton>(find.byKey(const Key('summary.share'))).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('summary.prev')));
    await tester.pumpAndSettle();
    expect(find.text('No workouts in this period.'), findsOneWidget);
  });

  testWidgets('goals: add a lift goal from the heaviest set; reaching it marks it achieved', (tester) async {
    tall(tester);
    final goals = FakeGoalRepository();
    final workouts = FakeWorkoutRepository()..exerciseRecords = [bench(heaviest: 90)];
    await pumpScreen(tester, const Scaffold(body: SingleChildScrollView(child: GoalsCard())), overrides: [
      goalRepositoryProvider.overrideWithValue(goals),
      workoutRepositoryProvider.overrideWithValue(workouts),
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [
        Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push),
      ])),
    ]);

    await tester.tap(find.byKey(const Key('goals.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal.exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench press'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal.target')), '100');
    await tester.tap(find.byKey(const Key('goal.save')));
    await tester.pumpAndSettle();

    final created = goals.created.single;
    expect((created.kind, created.exerciseId, created.target, created.startValue), (GoalKind.exerciseWeight, 'bench', 100.0, 90.0));
    expect(find.text('Bench press: 100 kg'), findsOneWidget);
    expect(find.textContaining('now 90 kg'), findsOneWidget);
    expect(goals.achieved, isEmpty);

    workouts.exerciseRecords = [bench(heaviest: 100)];
    final container = ProviderScope.containerOf(tester.element(find.byType(GoalsCard)));
    container.invalidate(recordsProvider);
    await tester.pumpAndSettle();
    expect(goals.achieved, ['g0']);
    expect(find.textContaining('Goal reached'), findsOneWidget);
  });
}
