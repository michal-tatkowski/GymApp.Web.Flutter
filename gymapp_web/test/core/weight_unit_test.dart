import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/units/weight_unit.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  const lb = WeightFormat(WeightUnit.lb);

  test('kg stays exact; lb is rounded to 0.1 and goes back to kg with 0.01 precision', () {
    expect(WeightFormat.kg.withUnit(102.5), '102.5 kg');
    expect(lb.withUnit(100), '220.5 lb');
    expect(lb.toKg(225), 102.06);
    expect(lb.fromKg(lb.toKg(225)), 225); // a typed value survives the round trip
    expect(lb.step, 5);
    expect(lb.maxSetWeight, closeTo(2204.6, 0.1));
  });

  test('sets are described in the chosen unit', () {
    const sets = [WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 10, weight: 100)];
    expect(ExerciseWorkoutsScreen.describeSets(sets), '2 × 10 × 100 kg');
    expect(ExerciseWorkoutsScreen.describeSets(sets, lb), '2 × 10 × 220.5 lb');
    expect(ExerciseWorkoutsScreen.describeSets(const [WorkoutSet(reps: 12, weight: 0)], lb), '12');
  });

  testWidgets('in lb the form shows pounds, steps by 5 lb and saves kilograms', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.weight_unit': 'lb'});
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeWorkoutRepository()
      ..seed('bench', DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 2)), [
        const WorkoutSet(reps: 5, weight: 100),
      ]);
    await pumpScreen(tester, const ExerciseWorkoutsScreen(exerciseId: 'bench', exerciseName: 'Bench press'),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    expect(find.textContaining('220.5 lb'), findsWidgets); // history in pounds
    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    String weight() => tester.widget<TextFormField>(find.byKey(const Key('workout.set0.weight'))).controller!.text;
    expect(weight(), '220.5'); // prefilled from the last workout, converted

    await tester.enterText(find.byKey(const Key('workout.set0.weight')), '220');
    await tester.tap(find.bySemanticsLabel('Increase by 5').last);
    await tester.pump();
    expect(weight(), '225');

    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();
    expect(repo.posted.single.sets.single.weight, 102.06); // the API gets kg
  });
}
