import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/goals/goals_data.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

class _Goals extends GoalRepository {
  _Goals() : super(Dio());

  final created = <Goal>[];

  @override
  Future<List<Goal>> list() async => const [];

  @override
  Future<Goal> create(Goal goal) async {
    created.add(goal);
    return goal;
  }
}

PlanTemplate _template(String key, String name) => PlanTemplate(key: key, name: name, description: '$name plan', daysPerWeek: 4, items: [
      PlanItem(exerciseId: 'squat', exerciseName: 'Squat', category: ExerciseCategory.legs),
    ]);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recommendation by place, days and goal', () {
    expect(recommendTemplates(TrainingGoal.muscle, TrainingPlace.home, 5), ['home-bodyweight']);
    expect(recommendTemplates(TrainingGoal.strength, TrainingPlace.gym, 3), ['five-by-five']);
    expect(recommendTemplates(TrainingGoal.fitness, TrainingPlace.gym, 2), ['fbw-beginner']);
    expect(recommendTemplates(TrainingGoal.muscle, TrainingPlace.gym, 4), ['upper', 'lower']);
    expect(recommendTemplates(TrainingGoal.fatLoss, TrainingPlace.gym, 6), ['push', 'pull', 'legs']);
    expect(spreadDays(3), {DateTime.monday, DateTime.wednesday, DateTime.friday});
  });

  Future<(FakePlanRepository, _Goals, FakeReminderScheduler)> pumpNewAccount(WidgetTester tester, {FakeWorkoutRepository? workouts}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final plans = FakePlanRepository()..templates = [_template('upper', 'Upper body'), _template('lower', 'Lower body')];
    final goals = _Goals();
    final reminders = FakeReminderScheduler();
    await pumpScreen(tester, const TodayScreen(), onboarding: true, plans: plans, reminders: reminders, overrides: [
      goalRepositoryProvider.overrideWithValue(goals),
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(workouts ?? FakeWorkoutRepository()),
    ]);
    return (plans, goals, reminders);
  }

  testWidgets('new account: three answers → plans, weekly goal and reminders', (tester) async {
    final (plans, goals, reminders) = await pumpNewAccount(tester);

    expect(find.text('What\'s your main goal?'), findsOneWidget);
    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('At a gym'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.tap(find.byKey(const Key('onboarding.daysNext')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding.plan.upper')), findsOneWidget);
    expect(find.byKey(const Key('onboarding.plan.lower')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding.accept')));
    await tester.pumpAndSettle();

    expect(plans.saved.map((p) => p.name), ['Upper body', 'Lower body']);
    expect((goals.created.single.kind, goals.created.single.target), (GoalKind.weeklyWorkouts, 4.0));
    expect(reminders.applied.last.weekdays, hasLength(4));
    expect(find.byType(OnboardingScreen), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('onboarding.done'), isTrue);
  });

  testWidgets('skip: never asked again on this phone', (tester) async {
    final (plans, _, _) = await pumpNewAccount(tester);
    await tester.tap(find.byKey(const Key('onboarding.skip')));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(plans.saved, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('onboarding.done'), isTrue);
  });

  testWidgets('an account that already trains is not asked', (tester) async {
    final workouts = FakeWorkoutRepository()
      ..seed('bench', DateUtils.dateOnly(DateTime.now()), const [WorkoutSet(reps: 5, weight: 100)]);
    await pumpNewAccount(tester, workouts: workouts);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('onboarding.done'), isTrue);
  });
}
