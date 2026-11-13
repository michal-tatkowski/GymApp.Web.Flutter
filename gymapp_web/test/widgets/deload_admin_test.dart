import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/admin/admin_panel.dart';
import 'package:gymapp_web/features/gym/deload/deload.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/session/session_models.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final today = DateTime(2026, 11, 13); // a Friday

  TrainingDayDetails day(DateTime date, Map<String, List<WorkoutSet>> exercises) => TrainingDayDetails(
        date: date,
        exercises: [
          for (final MapEntry(key: id, value: sets) in exercises.entries)
            DayExercise(
              exerciseId: id,
              exerciseName: id,
              category: ExerciseCategory.push,
              tracking: Tracking.weight,
              entries: [FakeWorkoutRepository.entryOf('e$id$date', date, sets, null)],
            ),
        ],
      );

  group('when to suggest a lighter week', () {
    test('most last sets to failure lately → hard sets', () {
      const toFailure = [WorkoutSet(reps: 8, weight: 100, rir: 2), WorkoutSet(reps: 6, weight: 100, rir: 0)];
      final days = [
        day(today.subtract(const Duration(days: 2)), {'bench': toFailure, 'row': toFailure}),
        day(today.subtract(const Duration(days: 5)), {'bench': toFailure, 'squat': const [WorkoutSet(reps: 5, weight: 100, rir: 2)]}),
      ];
      expect(deloadAdvice(days, const [], today)?.reason, DeloadReason.hardSets);
    });

    test('results dropping in two exercises → stalled', () {
      List<WorkoutSet> at(double kg) => [WorkoutSet(reps: 5, weight: kg)];
      final days = [
        for (final (ago, kg) in [(20, 100.0), (13, 105.0), (2, 95.0)])
          day(today.subtract(Duration(days: ago)), {'bench': at(kg), 'squat': at(kg + 40)}),
      ];
      final advice = deloadAdvice(days, const [], today)!;
      expect((advice.reason, advice.count), (DeloadReason.stalled, 2));
    });

    test('eight weeks in a row → streak, unless there was a deload lately', () {
      final mondays = [for (var w = 0; w < 9; w++) DateTime(2026, 11, 9).subtract(Duration(days: 7 * w))];
      final advice = deloadAdvice(const [], mondays, today)!;
      expect((advice.reason, advice.count), (DeloadReason.streak, 9));
      expect(deloadAdvice(const [], mondays, today, lastDeload: DateTime(2026, 10, 1)), isNull);
      expect(deloadAdvice(const [], mondays.take(5), today), isNull);
    });

    test('nothing wrong → no advice', () {
      expect(deloadAdvice([day(today, {'bench': const [WorkoutSet(reps: 8, weight: 100, rir: 2)]})], const [], today), isNull);
    });
  });

  test('a deload workout: 85 % of the weight on the plate step, one set fewer, no drop sets', () {
    const item = PlanItem(exerciseId: 'bench', exerciseName: 'Bench', category: ExerciseCategory.push, sets: 3, repsMin: 8, repsMax: 10, dropSets: 2);
    final e = SessionExercise.fromPlan(item, const [WorkoutSet(reps: 8, weight: 100), WorkoutSet(reps: 8, weight: 100)], WeightFormat.kg,
        deload: true);
    expect([for (final s in e.sets) (s.weightKg, s.drop)], [(85.0, false), (85.0, false)]);
    expect(e.hint, HintKind.deload);
    // Without history there is nothing to lighten: the plan as usual.
    expect(SessionExercise.fromPlan(item, null, WeightFormat.kg, deload: true).hint, isNull);
  });

  testWidgets('Today: advice → "Plan a lighter week" → the next workout starts lighter', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateUtils.dateOnly(DateTime.now());
    final repo = FakeWorkoutRepository();
    for (final ago in [1, 3, 5]) {
      repo.seed('bench', now.subtract(Duration(days: ago)), const [WorkoutSet(reps: 8, weight: 100, rir: 0)]);
      repo.seed('row', now.subtract(Duration(days: ago)), const [WorkoutSet(reps: 8, weight: 80, rir: 0)]);
    }
    const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
      PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 3, repsMin: 8, repsMax: 10),
    ]);
    await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(repo),
    ]);
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));

    expect(find.text('Time for a lighter week?'), findsOneWidget);
    expect(find.text('Most of your last sets lately went to failure (RIR 0).'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deload.start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deload.active')), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('deload.state'), contains('activeUntil'));

    await tester.tap(find.byKey(const Key('plan.start.p1')));
    await tester.pumpAndSettle();
    final sets = c.read(activeSessionProvider)!.exercises.single.sets;
    expect([for (final s in sets) s.weightKg], [85.0, 85.0]);
    expect(find.text('Lighter week: about 85% of the weight, one set fewer'), findsOneWidget);

    c.read(activeSessionProvider.notifier).discard();
    c.read(restTimerProvider.notifier).stop();
  });

  testWidgets('"Not now" hides the advice for a week', (tester) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final repo = FakeWorkoutRepository();
    for (final ago in [1, 3]) {
      repo.seed('bench', now.subtract(Duration(days: ago)), const [WorkoutSet(reps: 8, weight: 100, rir: 0)]);
      repo.seed('row', now.subtract(Duration(days: ago)), const [WorkoutSet(reps: 8, weight: 80, rir: 0)]);
    }
    await pumpScreen(tester, const SingleChildScrollView(child: DeloadCard()),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);
    await tester.tap(find.byKey(const Key('deload.later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deload.advice')), findsNothing);
  });

  group('admin panel', () {
    final stats = AdminStats(
      generatedAt: DateTime(2026, 11, 13, 9, 30),
      values: const {
        'totalUsers': 1250, 'confirmedUsers': 1100, 'newUsers24h': 12, 'newUsers7d': 80, 'newUsers30d': 300,
        'active24h': 140, 'active48h': 210, 'active7d': 520, 'active30d': 900,
        'trainedToday': 60, 'trained7d': 400, 'trained30d': 700, 'workouts7d': 3200, 'sessions7d': 650,
      },
      days: [for (var i = 0; i < 30; i++) AdminDay(date: DateTime(2026, 10, 15 + i), activeUsers: 100 + i, newUsers: i % 5, trainingUsers: 50)],
    );

    testWidgets('not an admin: no entry in Settings', (tester) async {
      tallView(tester);
      await pumpScreen(tester, const SettingsScreen());
      expect(find.byKey(const Key('settings.admin')), findsNothing);
    });

    testWidgets('admin: Settings → panel with users, active and training counts', (tester) async {
      tallView(tester);
      await pumpScreen(tester, const SettingsScreen(), admin: FakeAdminRepository(isAdminUser: true, statsResult: stats));
      await tester.tap(find.byKey(const Key('settings.admin')));
      await tester.pumpAndSettle();

      expect(find.text('Admin panel'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget); // all users
      expect(find.text('140'), findsOneWidget); // active in 24 h
      expect(find.text('Last 48 h'), findsOneWidget);
      expect(find.text('210'), findsOneWidget);
      expect(find.text('3,200'), findsOneWidget); // exercises logged in 7 days
      await tester.scrollUntilVisible(find.byKey(const Key('admin.daily')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('max 129'), findsOneWidget); // active per day
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(find.text('max 4'), findsOneWidget);
    });
  });
}
