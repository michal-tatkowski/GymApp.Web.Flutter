import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/session/session_models.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const kg = WeightFormat.kg;

  group('progression with RIR', () {
    ProgressionHint? hint(List<WorkoutSet> last) =>
        suggestNext(last: last, targetSets: 2, repsMin: 8, repsMax: 10, weights: kg);

    test('top of the range and still easy → two plate steps', () {
      final h = hint(const [WorkoutSet(reps: 10, weight: 100, rir: 3), WorkoutSet(reps: 10, weight: 100, rir: 4)])!;
      expect((h.kind, h.sets.first.weightKg, h.sets.first.reps), (HintKind.addWeight, 105.0, 8));
    });

    test('top of the range, hard → one step (as without RIR)', () {
      expect(hint(const [WorkoutSet(reps: 10, weight: 100, rir: 0), WorkoutSet(reps: 10, weight: 100, rir: 1)])!.sets.first.weightKg,
          102.5);
    });

    test('easy but below the top → one step up anyway; hard below the top → repeat', () {
      final easy = hint(const [WorkoutSet(reps: 8, weight: 100, rir: 3), WorkoutSet(reps: 9, weight: 100, rir: 3)])!;
      expect((easy.kind, easy.sets.first.weightKg), (HintKind.addWeight, 102.5));
      expect(hint(const [WorkoutSet(reps: 8, weight: 100, rir: 0), WorkoutSet(reps: 8, weight: 100)])!.kind, HintKind.repeat);
    });
  });

  test('history shows RIR per set', () {
    expect(
      ExerciseWorkoutsScreen.describeSets(const [WorkoutSet(reps: 8, weight: 100, rir: 2), WorkoutSet(reps: 8, weight: 100, rir: 0)]),
      '2 × 8 × 100 kg · RIR 2/0',
    );
    expect(ExerciseWorkoutsScreen.describeSets(const [WorkoutSet(reps: 8, weight: 100), WorkoutSet(reps: 6, weight: 100, rir: 1)]),
        '8×100, 6×100 kg · RIR –/1');
  });

  testWidgets('after a set: pick RIR and add a note; both are saved', (tester) async {
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
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
    await tester.tap(find.byKey(const Key('plan.start.p1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session.feedback0')), findsNothing); // only after the set is done
    await tester.tap(find.descendant(of: find.byKey(const Key('session.set0')), matching: find.byKey(const Key('done'))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rir.2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('setNote')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('setNote.field')), ' slow negative ');
    await tester.tap(find.byKey(const Key('setNote.save')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('session.finish')));
    await tester.pumpAndSettle();
    final set = repo.posted.single.sets.single;
    expect((set.rir, set.note), (2, 'slow negative'));
    expect(set.toJson(), containsPair('rir', 2));
    c.read(restTimerProvider.notifier).stop();
  });
}
