import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/pending_sync_bar.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/pending_workouts.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

/// Basement gym, no signal: workouts are kept on the phone and sent later.
void main() {
  const bench = 'bench';
  final today = DateUtils.dateOnly(DateTime.now());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(FakeWorkoutRepository, ProviderContainer)> pumpExercise(WidgetTester tester, {bool offline = true}) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeWorkoutRepository()
      ..seed(bench, today.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 10, weight: 100)]);
    await pumpScreen(
      tester,
      const Scaffold(
        body: Column(
          children: [
            Expanded(child: ExerciseWorkoutsScreen(exerciseId: bench, exerciseName: 'Bench press')),
            PendingSyncBar(),
          ],
        ),
      ),
      overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
    );
    repo.offline = offline;
    final c = ProviderScope.containerOf(tester.element(find.byType(PendingSyncBar)));
    return (repo, c);
  }

  testWidgets('logging without a connection keeps the workout on the phone and says so', (tester) async {
    final (repo, c) = await pumpExercise(tester);

    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved on the phone'), findsOneWidget);
    expect(find.text('1 workout waiting to sync'), findsOneWidget);
    final queued = c.read(pendingWorkoutsProvider).single;
    expect(queued.request.id, isNotNull);
    expect(find.byKey(Key('workout.pending.${queued.entryId}')), findsOneWidget); // in the history, marked
    expect(repo.entries[bench], hasLength(1)); // nothing reached the server

    final stored = (await SharedPreferences.getInstance()).getString('workouts.pending');
    expect(jsonDecode(stored!) as List, hasLength(1)); // survives closing the app
  });

  testWidgets('"Sync now" sends it with the same id; a retried POST does not duplicate', (tester) async {
    final (repo, c) = await pumpExercise(tester);
    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();
    final id = c.read(pendingWorkoutsProvider).single.entryId;

    repo.offline = false;
    await tester.pump(const Duration(seconds: 6)); // let the "Undo" snackbar go away (it covers the bar here)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();

    expect(c.read(pendingWorkoutsProvider), isEmpty);
    expect(find.byKey(const Key('pending.bar')), findsNothing);
    expect(repo.posted.single.id, id);
    expect(repo.entries[bench]!.map((e) => e.id), contains(id));
    expect((await SharedPreferences.getInstance()).getString('workouts.pending'), isNull);

    // The response to the first POST was lost and the queue sends it again: still one entry.
    await repo.addEntry(bench, repo.posted.single);
    expect(repo.entries[bench]!.where((e) => e.id == id), hasLength(1));
  });

  testWidgets('still offline: sync stops and keeps everything for later', (tester) async {
    final (repo, c) = await pumpExercise(tester);
    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();

    expect(await c.read(pendingWorkoutsProvider.notifier).sync(), 0);
    expect(c.read(pendingWorkoutsProvider), hasLength(1));
  });

  testWidgets('a workout the server rejects for good is dropped, not retried forever', (tester) async {
    final (repo, c) = await pumpExercise(tester);
    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();

    repo
      ..offline = false
      ..saveError = const NotFoundFailure('Exercise not found', 'ExerciseNotFound');
    await c.read(pendingWorkoutsProvider.notifier).sync();
    await tester.pumpAndSettle();

    expect(c.read(pendingWorkoutsProvider), isEmpty);
  });

  testWidgets('deleting a queued workout removes it from the queue, no API call', (tester) async {
    final (repo, c) = await pumpExercise(tester);
    await tester.tap(find.byKey(const Key('workout.repeat')));
    await tester.pumpAndSettle();
    final id = c.read(pendingWorkoutsProvider).single.entryId;

    await tester.tap(find.descendant(of: find.byKey(Key('workout.pending.$id')), matching: find.byTooltip('Delete')));
    await tester.pumpAndSettle();

    expect(c.read(pendingWorkoutsProvider), isEmpty);
    expect(repo.posted, isEmpty);
  });

  testWidgets('opened without a connection: notice instead of an error page, "Log workout" still works', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeWorkoutRepository()..offline = true;
    await pumpScreen(tester, const ExerciseWorkoutsScreen(exerciseId: bench, exerciseName: 'Bench press'),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    expect(find.byKey(const Key('workout.offline')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('workout.set0.weight')), '60');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved on the phone'), findsOneWidget);
    expect(find.textContaining('Waiting to sync'), findsWidgets);
  });

  test('the queue is restored after an app restart', () async {
    final req = WorkoutEntryRequest(date: DateTime(2026, 11, 11), sets: const [WorkoutSet(reps: 5, weight: 80)], id: 'x1');
    SharedPreferences.setMockInitialValues({
      'workouts.pending': jsonEncode([PendingWorkout(exerciseId: bench, request: req).toJson()]),
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(pendingWorkoutsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final restored = c.read(pendingWorkoutsProvider).single;
    expect(restored.entryId, 'x1');
    expect(restored.request.sets.single.weight, 80);
    expect(restored.request.date, DateTime(2026, 11, 11));
  });

  test('Today keeps the last favorites for offline quick logging', () async {
    final repo = FakeExerciseRepository([const Exercise(id: bench, name: 'Bench press', category: ExerciseCategory.push, isFavorite: true)]);
    final c = ProviderContainer(overrides: [exerciseRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final sub = c.listen(favoriteExercisesProvider, (_, __) {});
    expect((await c.read(favoriteExercisesProvider.future)).single.name, 'Bench press');
    await Future<void>.delayed(Duration.zero); // cache write runs in the background

    repo.loadError = const NetworkFailure();
    c.invalidate(favoriteExercisesProvider);
    expect((await c.read(favoriteExercisesProvider.future)).single.name, 'Bench press');
    sub.close();
  });

  testWidgets('logging out with unsent workouts asks first; Cancel keeps them', (tester) async {
    final req = WorkoutEntryRequest(date: today, sets: const [WorkoutSet(reps: 5, weight: 80)], id: 'x1');
    SharedPreferences.setMockInitialValues({
      'workouts.pending': jsonEncode([PendingWorkout(exerciseId: bench, request: req).toJson()]),
    });
    await pumpScreen(tester, const SettingsScreen());
    final c = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
    c.read(pendingWorkoutsProvider);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Logout'), 100);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Workouts not sent yet'), findsOneWidget);
    expect(find.textContaining('1 workout waiting to sync'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(c.read(pendingWorkoutsProvider), hasLength(1));
  });

  testWidgets('Today offline: "+" still opens the form and the workout is queued', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final workouts = FakeWorkoutRepository()..offline = true;
    await pumpScreen(tester, const TodayScreen(), overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(
          [const Exercise(id: bench, name: 'Bench press', category: ExerciseCategory.push, isFavorite: true)])),
      workoutRepositoryProvider.overrideWithValue(workouts),
    ]);
    expect(find.text('Not trained yet'), findsNothing); // unknown offline, not "never"

    await tester.tap(find.byKey(const Key('today.log.$bench')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('workout.set0.weight')), '60');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved on the phone'), findsOneWidget);
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
    expect(c.read(pendingWorkoutsProvider).single.request.sets.single.weight, 60);
  });
}
