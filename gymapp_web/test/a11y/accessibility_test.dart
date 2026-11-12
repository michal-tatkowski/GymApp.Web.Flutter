// Accessibility audit of the main screens, light and dark, normal and large text:
// tap targets ≥ 48 dp, every tappable thing has a label, text contrast (WCAG AA),
// and no overflow with 1.5× text (an overflow fails the test by itself).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/theme/app_theme.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_screen.dart';
import 'package:gymapp_web/features/gym/goals/goals_data.dart';
import 'package:gymapp_web/features/gym/history/history_screen.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_editor_screen.dart';
import 'package:gymapp_web/features/gym/progress/records_screen.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/session/session_screen.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/my_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const plan = WorkoutPlan(id: 'p1', name: 'Push A', items: [
    PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 3, repsMin: 8, repsMax: 10,
        supersetWithNext: true),
    PlanItem(exerciseId: 'plank', exerciseName: 'Plank', category: ExerciseCategory.core, sets: 2, repsMin: 1, repsMax: 1,
        tracking: Tracking.time),
  ]);

  FakeWorkoutRepository workouts() => FakeWorkoutRepository()
    ..seed('bench', today.subtract(const Duration(days: 2)), const [WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 8, weight: 100)])
    ..seed('bench', today.subtract(const Duration(days: 9)), const [WorkoutSet(reps: 10, weight: 95)])
    ..exerciseRecords = [
      ExerciseRecords(
        exerciseId: 'bench',
        exerciseName: 'Bench press',
        category: ExerciseCategory.push,
        tracking: Tracking.weight,
        trainingDays: 2,
        lastDate: today,
        bestOneRepMax: RecordValue(value: 133, date: today, reps: 10, weight: 100),
        heaviestWeight: RecordValue(value: 100, date: today, reps: 10, weight: 100),
      ),
    ];

  final screens = <String, Widget Function()>{
    'Today': () => const TodayScreen(),
    'Exercises': () => const ExercisesScreen(),
    'Progress': () => const MyWorkoutsScreen(),
    'History': () => const HistoryScreen(),
    'Records': () => const RecordsScreen(),
    'Settings': () => const SettingsScreen(),
    'Plan editor': () => const PlanEditorScreen(plan: plan),
  };

  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.5]) {
      final mode = '${dark ? 'dark' : 'light'}, text ×$scale';
      for (final MapEntry(key: name, value: build) in screens.entries) {
        testWidgets('$name ($mode)', (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 2.75; // ~393 × 873 dp, a typical phone
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          await pumpScreen(
            tester,
            build(),
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            textScale: scale,
            plans: FakePlanRepository([plan]),
            overrides: [
              goalRepositoryProvider.overrideWithValue(_NoGoals()),
              workoutRepositoryProvider.overrideWithValue(workouts()),
              exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [
                Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push, isFavorite: true),
                Exercise(id: 'plank', name: 'Plank', category: ExerciseCategory.core, tracking: Tracking.time),
              ])),
            ],
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }

      testWidgets('Session ($mode)', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          const TodayScreen(),
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          textScale: scale,
          plans: FakePlanRepository([plan]),
          overrides: [
            goalRepositoryProvider.overrideWithValue(_NoGoals()),
            workoutRepositoryProvider.overrideWithValue(workouts()),
            exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
          ],
        );
        await tester.ensureVisible(find.byKey(const Key('plan.start.p1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('plan.start.p1')));
        await tester.pumpAndSettle();
        expect(find.byType(SessionScreen), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen, skipOffstage: false)));
        c.read(activeSessionProvider.notifier).discard();
        c.read(restTimerProvider.notifier).stop();
        handle.dispose();
      });
    }
  }
}

class _NoGoals extends GoalRepository {
  _NoGoals() : super(Dio());

  @override
  Future<List<Goal>> list() async => const [];
}
