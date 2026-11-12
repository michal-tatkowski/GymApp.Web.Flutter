import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_editor_screen.dart';
import 'package:gymapp_web/features/gym/session/session_models.dart';
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
  const kg = WeightFormat.kg;
  const lb = WeightFormat(WeightUnit.lb);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('double progression', () {
    List<WorkoutSet> sets(int reps, double w, [int n = 3]) => List.filled(n, WorkoutSet(reps: reps, weight: w));

    test('top of the range in every set → one plate step heavier, back to the bottom of the range', () {
      final hint = suggestNext(last: sets(12, 100), targetSets: 3, repsMin: 8, repsMax: 12, weights: kg)!;
      expect(hint.kind, HintKind.addWeight);
      expect(hint.sets.map((s) => (s.reps, s.weightKg)), List.filled(3, (8, 102.5)));
    });

    test('in lb the step is 5 lb (saved as kg)', () {
      final hint = suggestNext(last: sets(12, 100), targetSets: 3, repsMin: 8, repsMax: 12, weights: lb)!;
      expect(lb.fromKg(hint.sets.first.weightKg), 225.5); // 220.5 + 5
    });

    test('not yet at the top → same weight, the reps of last time', () {
      final hint = suggestNext(
        last: const [WorkoutSet(reps: 12, weight: 100), WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 9, weight: 100)],
        targetSets: 3, repsMin: 8, repsMax: 12, weights: kg,
      )!;
      expect(hint.kind, HintKind.repeat);
      expect(hint.sets.map((s) => (s.reps, s.weightKg)), [(12, 100.0), (10, 100.0), (9, 100.0)]);
    });

    test('warm-up sets do not count: the heaviest weight is the working weight', () {
      final hint = suggestNext(
        last: const [WorkoutSet(reps: 10, weight: 60), WorkoutSet(reps: 8, weight: 100), WorkoutSet(reps: 8, weight: 100)],
        targetSets: 2, repsMin: 6, repsMax: 8, weights: kg,
      )!;
      expect(hint.kind, HintKind.addWeight);
    });

    test('bodyweight progresses in reps; no history → no hint', () {
      final hint = suggestNext(last: sets(15, 0), targetSets: 3, repsMin: 10, repsMax: 15, weights: kg)!;
      expect((hint.kind, hint.sets.first.reps), (HintKind.addReps, 16));
      expect(suggestNext(last: null, targetSets: 3, repsMin: 8, repsMax: 12, weights: kg), isNull);
    });
  });

  testWidgets('plan editor: name, pick exercises, set the target, save', (tester) async {
    final plans = FakePlanRepository();
    await pumpScreen(tester, const PlanEditorScreen(), plans: plans, overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [
        Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push),
        Exercise(id: 'row', name: 'Barbell row', category: ExerciseCategory.pull),
      ])),
    ]);

    await tester.tap(find.byKey(const Key('plan.save')));
    await tester.pump();
    expect(find.text('Enter a plan name'), findsOneWidget); // nothing sent
    expect(plans.saved, isEmpty);

    await tester.enterText(find.byKey(const Key('plan.name')), 'Push A');
    for (final name in ['Bench press', 'Barbell row']) {
      await tester.tap(find.byKey(const Key('plan.addExercise')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
    // Bench: 4 sets.
    await tester.tap(find.descendant(of: find.byKey(const Key('plan.0.sets')), matching: find.byIcon(Icons.add)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('plan.save')));
    await tester.pumpAndSettle();

    final req = plans.saved.single;
    expect(req.name, 'Push A');
    expect(req.items.map((i) => (i.exerciseId, i.sets, i.repsMin, i.repsMax)), [('bench', 4, 8, 12), ('row', 3, 8, 12)]);
  });

  group('live session', () {
    const plan = WorkoutPlan(id: 'p1', name: 'Push A', items: [
      PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 2, repsMin: 8, repsMax: 10),
      PlanItem(exerciseId: 'dips', exerciseName: 'Dips', category: ExerciseCategory.push, sets: 2, repsMin: 8, repsMax: 12),
    ]);

    Future<(FakeWorkoutRepository, ProviderContainer)> pumpToday(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final workouts = FakeWorkoutRepository()
        ..seed('bench', today.subtract(const Duration(days: 3)), const [
          WorkoutSet(reps: 10, weight: 100),
          WorkoutSet(reps: 10, weight: 100),
        ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      return (workouts, ProviderScope.containerOf(tester.element(find.byType(TodayScreen))));
    }

    testWidgets('start → sets prefilled from the hint → tick off → next saves → finish shows the summary',
        (tester) async {
      final (workouts, c) = await pumpToday(tester);

      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      // Bench: 2 × 10 × 100 last time at the top of 8–10 → today 102.5 × 8.
      expect(find.textContaining('today 102.5 kg × 8'), findsOneWidget);
      expect(find.textContaining('Last time: 2 × 10 × 100 kg'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.text('102.5')), findsOneWidget);

      await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
      await tester.pump();
      expect(c.read(restTimerProvider).running, isTrue); // rest starts after a set
      // Second set: one rep less than planned, then done.
      await tester.tap(find.descendant(
          of: find.descendant(of: find.byKey(const Key('session.set1')), matching: find.byKey(const Key('reps'))),
          matching: find.byKey(const Key('minus'))));
      await tester.tap(find.descendant(of: find.byKey(const Key('session.set1')), matching: find.byKey(const Key('done'))));
      await tester.pump();

      await tester.tap(find.byKey(const Key('session.next')));
      await tester.pumpAndSettle();
      final bench = workouts.posted.single;
      expect(bench.sets.map((s) => (s.reps, s.weight)), [(8, 102.5), (7, 102.5)]);
      expect(find.text('Dips'), findsWidgets);
      expect(find.textContaining('First time'), findsOneWidget); // no history → no hint

      // Dips: one set done, the other not → only the done one is saved.
      await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
      await tester.pump();
      await tester.tap(find.byKey(const Key('session.finish')));
      await tester.pumpAndSettle();

      expect(workouts.posted, hasLength(2));
      expect(workouts.posted.last.sets, hasLength(1));
      expect(find.byKey(const Key('session.summary')), findsOneWidget);
      expect(find.textContaining('2 exercises · 3 sets'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(c.read(activeSessionProvider), isNull);
      expect((await SharedPreferences.getInstance()).getString('session.active'), isNull);
      expect(find.byKey(const Key('today.session')), findsNothing);
    });

    testWidgets('a session in progress survives an app restart and shows on Today', (tester) async {
      final session = WorkoutSession(
        planId: 'p1',
        planName: 'Push A',
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        current: 1,
        exercises: [
          SessionExercise.fromPlan(plan.items[0], null, kg).copyWith(savedEntryId: 'e9'),
          SessionExercise.fromPlan(plan.items[1], null, kg),
        ],
      );
      SharedPreferences.setMockInitialValues({'session.active': jsonEncode(session.toJson())});
      await pumpToday(tester);

      expect(find.text('Push A in progress · 1/2'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Target: 2 × 8–12'), findsOneWidget); // back on Dips
    });

    testWidgets('a new weight carries over to the later sets not done yet', (tester) async {
      await pumpToday(tester);
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('session.next'))); // to Dips: no history, 0 kg
      await tester.pumpAndSettle();

      Finder weightOf(int set) => find.descendant(
          of: find.descendant(of: find.byKey(Key('session.set$set')), matching: find.byKey(const Key('weight'))),
          matching: find.byType(Text));
      await tester.tap(find.descendant(
          of: find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('weight'))),
          matching: find.byKey(const Key('plus'))));
      await tester.pump();

      expect(tester.widget<Text>(weightOf(1).first).data, '2.5');
    });

    testWidgets('superset: a ticked set jumps to the partner without rest; rest after the round, back to the first',
        (tester) async {
      const superset = WorkoutPlan(id: 'p2', name: 'Arms', items: [
        PlanItem(exerciseId: 'curl', exerciseName: 'Curl', category: ExerciseCategory.pull, sets: 2, repsMin: 10, repsMax: 10, supersetWithNext: true),
        PlanItem(exerciseId: 'pushdown', exerciseName: 'Pushdown', category: ExerciseCategory.push, sets: 2, repsMin: 10, repsMax: 10),
      ]);
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final workouts = FakeWorkoutRepository();
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([superset]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
      Future<void> tickFirstOpenSet() async {
        final s = c.read(activeSessionProvider)!;
        final set = s.currentExercise.sets.indexWhere((x) => !x.done);
        await tester.tap(find.descendant(of: find.byKey(Key('session.set$set')), matching: find.byKey(const Key('done'))));
        await tester.pump();
      }

      await tester.tap(find.byKey(const Key('plan.start.p2')));
      await tester.pumpAndSettle();
      expect(find.text('Superset · 1/2'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget); // one group = the last step: Next is Finish

      await tickFirstOpenSet(); // Curl 1
      expect(c.read(activeSessionProvider)!.current, 1);
      expect(c.read(restTimerProvider).running, isFalse);
      expect(find.text('Superset · 2/2'), findsOneWidget);

      await tickFirstOpenSet(); // Pushdown 1 → end of the round
      expect(c.read(restTimerProvider).running, isTrue);
      expect(c.read(activeSessionProvider)!.current, 0);
      expect(workouts.posted, isEmpty); // nothing saved while the superset is going

      c.read(restTimerProvider.notifier).stop();
      await tickFirstOpenSet(); // Curl 2
      await tickFirstOpenSet(); // Pushdown 2
      expect(c.read(activeSessionProvider)!.current, 1); // all done: stays
      await tester.tap(find.byKey(const Key('session.finish')));
      await tester.pumpAndSettle();
      expect(workouts.posted, hasLength(2));
      c.read(restTimerProvider.notifier).stop();
    });
  });

  group('warm-up', () {
    List<(int, double)> ramp(double kg, [WeightFormat w = kg]) =>
        [for (final s in warmUpSets(kg, w)) (s.reps, w.fromKg(s.weightKg))];

    test('ramps 40/60/80 % rounded down to the plate step', () {
      expect(ramp(100), [(10, 40.0), (6, 60.0), (3, 80.0)]);
      expect(ramp(102.5), [(10, 40.0), (6, 60.0), (3, 80.0)]);
      expect(ramp(lb.toKg(225), lb), [(10, 90.0), (6, 135.0), (3, 180.0)]);
    });

    test('light weights: shorter ramp; very light or bodyweight: none', () {
      expect(ramp(30), [(10, 10.0), (6, 17.5)]); // no 80 % under 40 kg
      expect(ramp(17.5), isEmpty);
      expect(ramp(0), isEmpty);
    });

    testWidgets('shown before the first set, gone once a set is done', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final workouts = FakeWorkoutRepository()
        ..seed('bench', today.subtract(const Duration(days: 3)), const [WorkoutSet(reps: 8, weight: 100)]);
      const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
        PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 1, repsMin: 8, repsMax: 10),
      ]);
      await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      await tester.tap(find.byKey(const Key('plan.start.p1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Before 100 kg'), findsOneWidget);
      await tester.tap(find.text('Warm-up'));
      await tester.pumpAndSettle();
      expect(find.text('10 × 40 kg'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
      await tester.pump();
      expect(find.byKey(const Key('session.warmUp')), findsNothing);
      final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen, skipOffstage: false)));
      c.read(restTimerProvider.notifier).stop();
    });
  });

  test('plan request: the last exercise never links to a next one', () {
    const items = [
      PlanItem(exerciseId: 'a', exerciseName: 'A', category: ExerciseCategory.push, supersetWithNext: true),
      PlanItem(exerciseId: 'b', exerciseName: 'B', category: ExerciseCategory.pull, supersetWithNext: true),
    ];
    final json = const PlanRequest(name: 'X', items: items).toJson()['exercises'] as List;
    expect(json.map((e) => (e as Map)['supersetWithNext']), [true, false]);
    expect(PlanItem.fromJson({...json.first as Map<String, dynamic>, 'exerciseName': 'A', 'category': 'Push'}).supersetWithNext, isTrue);
    expect(PlanItem.fromJson(const {'exerciseId': 'a', 'exerciseName': 'A', 'category': 'Push', 'sets': 3, 'repsMin': 8, 'repsMax': 12})
        .supersetWithNext, isFalse); // older API without the field
  });
}
