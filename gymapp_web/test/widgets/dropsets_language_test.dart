import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/auth/presentation/auth_providers.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_providers.dart';
import 'package:gymapp_web/features/gym/session/session_models.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/presentation/profile_providers.dart';
import 'package:gymapp_web/features/profile/presentation/widgets/progress_photos.dart';
import 'package:gymapp_web/features/settings/presentation/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const kg = WeightFormat.kg;

  group('drop sets', () {
    test('each about 20 % lighter, on the plate step, same reps', () {
      final drops = dropSetsAfter(const SessionSet(reps: 8, weightKg: 100), 2, kg);
      expect([for (final d in drops) (d.weightKg, d.reps, d.drop)], [(80.0, 8, true), (65.0, 8, true)]);
      expect(dropSetsAfter(const SessionSet(reps: 10, weightKg: 0), 1, kg).single.weightKg, 0); // bodyweight stays 0
    });

    test('from a plan: drops after the working sets; last time\'s drops do not skew the hint', () {
      const item = PlanItem(exerciseId: 'bench', exerciseName: 'Bench', category: ExerciseCategory.push, sets: 2, repsMin: 8, repsMax: 10, dropSets: 2);
      final e = SessionExercise.fromPlan(item, const [
        WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 10, weight: 100), // top of the range → +2.5
        WorkoutSet(reps: 6, weight: 80), WorkoutSet(reps: 5, weight: 65), // last time's drops
      ], kg);
      expect([for (final s in e.sets) (s.weightKg, s.drop)], [(102.5, false), (102.5, false), (82.5, true), (65.0, true)]);
    });

    test('plans send drop sets only when there are some', () {
      const item = PlanItem(exerciseId: 'x', exerciseName: 'X', category: ExerciseCategory.push);
      expect(item.toJson().containsKey('dropSets'), isFalse);
      expect(item.copyWith(dropSets: 2).toJson()['dropSets'], 2);
      expect(PlanItem.fromJson({...item.toJson(), 'exerciseName': 'X', 'category': 'Push', 'dropSets': 3}).dropSets, 3);
    });

    testWidgets('in a workout: no rest before a drop set, rest after the last one', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
        PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 8, repsMax: 8, dropSets: 2),
      ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()
          ..seed('bench', DateTime(2026, 1, 1), const [WorkoutSet(reps: 8, weight: 100)])),
      ]);
      final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      Finder done(int i) => find.descendant(of: find.byKey(Key('session.set$i')), matching: find.byKey(const Key('done')));
      expect(find.byTooltip('Drop set: about 20% lighter, straight away, no rest'), findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(done(i));
        await tester.tap(done(i));
        await tester.pump();
        expect(c.read(restTimerProvider).running, isFalse, reason: 'set $i is followed by a drop set');
      }
      await tester.ensureVisible(done(2));
      await tester.tap(done(2));
      await tester.pump();
      expect(c.read(restTimerProvider).running, isTrue);

      c.read(activeSessionProvider.notifier).discard();
      c.read(restTimerProvider.notifier).stop();
    });
  });

  testWidgets('switching the language reloads names from the API (plans fetched again)', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.locale': 'en'});
    final plans = FakePlanRepository();
    await tester.pumpWidget(ProviderScope(
      retry: noRetry,
      overrides: [
        authLocalStorageProvider.overrideWithValue(EmptyAuthStorage()),
        onboardingEnabledProvider.overrideWithValue(false),
        restAlarmProvider.overrideWithValue(FakeRestAlarm()),
        planRepositoryProvider.overrideWithValue(plans),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        progressPhotoStoreProvider.overrideWithValue(null),
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository(const UserProfile(nickname: 'Tester'))),
      ],
      child: const GymApp(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'jan@test.pl');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();
    final before = plans.loads;
    expect(before, greaterThan(0));

    final c = ProviderScope.containerOf(tester.element(find.byType(GymApp)));
    await c.read(localeProvider.notifier).toggle();
    await tester.pumpAndSettle();

    expect(find.text('Dziś'), findsWidgets);
    expect(plans.loads, greaterThan(before));
  });
}
