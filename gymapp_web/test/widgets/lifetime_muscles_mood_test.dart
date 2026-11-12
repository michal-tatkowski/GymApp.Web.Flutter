import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/theme/app_theme.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/history/history_screen.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/progress/badges.dart';
import 'package:gymapp_web/features/gym/progress/lifetime_muscles.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/settings/presentation/settings_providers.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:gymapp_web/l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final t = AppLocalizationsEn();

  group('lifetime badges', () {
    BadgeProgress badge(List<BadgeProgress> all, String id) => all.firstWhere((b) => b.def.id == id);

    test('a year of weekly workouts two years ago counts, though the year stats do not show it', () {
      final start = DateTime(2023, 1, 2); // a Monday
      final lifetime = LifetimeStats(
        trainingDates: [for (var w = 0; w < 52; w++) start.add(Duration(days: 7 * w))],
        volumeKg: 1200000,
        records: 60,
        exercises: 30,
      );
      final year = WorkoutStats(days: [TrainingDay(date: DateTime(2026, 11, 2), volume: 5000, exercises: 1, sets: 5)], records: const []);
      final b = computeBadges(year, 3, 1, lifetime: lifetime);

      expect(badge(b, 'workouts50').earnedAt, start.add(const Duration(days: 7 * 49)));
      expect(badge(b, 'streak52').earned, isTrue);
      expect(badge(b, 'volume1000t').earned, isTrue);
      expect(badge(b, 'volume1000t').earnedAt, isNull); // reached before the days we can see
      expect(badge(b, 'record50').earned, isTrue);
      expect(badge(b, 'variety25').earned, isTrue);
      expect(badge(b, 'workouts250').earned, isFalse);
    });

    test('without lifetime data (older API, offline) the year stats are used as before', () {
      final days = [for (var i = 0; i < 10; i++) TrainingDay(date: DateTime(2026, 1, 1 + i), volume: 100, exercises: 1, sets: 3)];
      final b = computeBadges(WorkoutStats(days: days, records: const []), 3, 1);
      expect(badge(b, 'workouts10').earnedAt, DateTime(2026, 1, 10));
      expect(badge(b, 'variety25').earned, isFalse);
    });
  });

  group('sets per muscle group', () {
    TrainingDayDetails day(DateTime date, Map<ExerciseCategory, int> sets) => TrainingDayDetails(
          date: date,
          exercises: [
            for (final MapEntry(key: cat, value: n) in sets.entries)
              DayExercise(
                exerciseId: cat.name,
                exerciseName: cat.name,
                category: cat,
                tracking: Tracking.weight,
                entries: [
                  FakeWorkoutRepository.entryOf('e${cat.name}$date', date, [for (var i = 0; i < n; i++) const WorkoutSet(reps: 8, weight: 50)], null),
                ],
              ),
          ],
          sessions: const [],
        );

    test('this week vs. the average of the 4 weeks before it', () {
      final today = DateTime(2026, 11, 12); // Thursday; week from Monday 9 Nov
      final data = muscleSets([
        day(DateTime(2026, 11, 10), {ExerciseCategory.push: 9, ExerciseCategory.pull: 3}),
        day(DateTime(2026, 11, 3), {ExerciseCategory.pull: 8, ExerciseCategory.legs: 8}),
        day(DateTime(2026, 10, 13), {ExerciseCategory.legs: 4}),
        day(DateTime(2026, 10, 1), {ExerciseCategory.legs: 100}), // older than 4 weeks: ignored
      ], 1, today);

      expect(data.thisWeek, {ExerciseCategory.push: 9, ExerciseCategory.pull: 3});
      expect(data.average, {ExerciseCategory.pull: 2.0, ExerciseCategory.legs: 3.0});
      expect(muscleHint(t, data.thisWeek), t.musclesMorePush);
      expect(muscleHint(t, data.average), isNull); // 5 sets: too little to judge
      expect(muscleHint(t, {ExerciseCategory.push: 6, ExerciseCategory.pull: 6}), t.musclesNoLegs);
    });

    testWidgets('Progress cards: all-time totals and the muscle bars with a hint', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = DateUtils.dateOnly(DateTime.now());
      final repo = FakeWorkoutRepository()
        ..seed('bench', today, const [WorkoutSet(reps: 5, weight: 100), WorkoutSet(reps: 5, weight: 100)])
        ..lifetime = LifetimeStats(
          trainingDates: [DateTime(2024, 3, 1), today],
          sets: 1234,
          reps: 9000,
          volumeKg: 250000,
          durationSeconds: 3600 * 41,
          records: 17,
          exercises: 12,
        );
      await pumpScreen(
        tester,
        const SingleChildScrollView(child: Column(children: [MuscleBalanceCard(), LifetimeCard()])),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );

      expect(find.text('Since March 1, 2024'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('41 h'), findsOneWidget);
      expect(find.text('250,000 kg'), findsOneWidget);
      expect(find.byKey(const Key('muscles.push')), findsOneWidget); // the fake files everything under push
      await tester.tap(find.text('4-week average'));
      await tester.pumpAndSettle();
      expect(find.text('No sets in this period yet.'), findsOneWidget);
    });
  });

  testWidgets('after a workout: mood and note go with the session', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeWorkoutRepository();
    const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
      PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 8, repsMax: 8),
    ]);
    await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(repo),
    ]);
    await tester.tap(find.byKey(const Key('plan.start.p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('session.finish')));
    await tester.pumpAndSettle();

    expect(find.text('How did it go?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mood.4')));
    await tester.enterText(find.byKey(const Key('workout.note')), '  Shoulder felt fine ');
    await tester.tap(find.byKey(const Key('session.summary.done')));
    await tester.pumpAndSettle();

    expect(repo.feedback[repo.sessionIds.single], (mood: 4, note: 'Shoulder felt fine'));
  });

  testWidgets('history: add mood and note to a past session', (tester) async {
    final repo = FakeWorkoutRepository()
      ..seed('bench', DateUtils.dateOnly(DateTime.now()), const [WorkoutSet(reps: 5, weight: 100)])
      ..sessions.add((name: 'Push', date: DateUtils.dateOnly(DateTime.now())));
    await pumpScreen(tester, const HistoryScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    await tester.tap(find.byKey(const Key('history.feedback.s')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mood.2')));
    await tester.enterText(find.byKey(const Key('workout.note')), 'Bad sleep');
    await tester.tap(find.byKey(const Key('session.feedback.save')));
    await tester.pumpAndSettle();

    expect(repo.feedback['s'], (mood: 2, note: 'Bad sleep'));
  });

  group('pure black and large buttons', () {
    test('pure black theme: black background and surfaces', () {
      final theme = AppTheme.dark(pureBlack: true);
      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.colorScheme.surface, Colors.black);
      expect(AppTheme.dark().scaffoldBackgroundColor, isNot(Colors.black));
    });

    testWidgets('both switches are remembered; pure black is off with the light theme', (tester) async {
      tallView(tester);
      late WidgetRef ref;
      await pumpScreen(tester, Consumer(builder: (context, r, _) {
        ref = r;
        return const SettingsScreen();
      }));

      await tester.tap(find.byKey(const Key('settings.pureBlack')));
      await tester.tap(find.byKey(const Key('settings.largeControls')));
      await tester.pumpAndSettle();
      expect((ref.read(pureBlackProvider), ref.read(largeSessionControlsProvider)), (true, true));
      final prefs = await SharedPreferences.getInstance();
      expect((prefs.getBool('settings.pure_black'), prefs.getBool('settings.large_session_controls')), (true, true));

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('settings.pureBlack'))).onChanged, isNull);
    });

    testWidgets('large buttons: "done" spans the set card with its label', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.large_session_controls': true});
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
        PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 8, repsMax: 8),
      ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
      ]);
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      final done = find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done')));
      expect(find.descendant(of: done, matching: find.text(t.sessionDoneSet)), findsOneWidget);
      expect(tester.getSize(done).height, greaterThanOrEqualTo(56));
      await tester.tap(done);
      await tester.pump();
      expect(find.descendant(of: done, matching: find.text(t.sessionUndoSet)), findsOneWidget);
    });
  });
}
