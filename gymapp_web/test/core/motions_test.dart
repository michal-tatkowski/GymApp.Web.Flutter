import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motions.dart';

void main() {
  test('ids match the API (SystemExerciseSeeder.IdFor)', () {
    // Seen from the API: barbell-bench-press.
    expect(systemExerciseId('barbell-bench-press'), '4395b56e-174b-55b0-95e5-cae20cad7ff4');
  });

  test('every system exercise has its own movement; custom ones get the category\'s', () {
    expect(motionsByKey, hasLength(44));
    expect(motionFor(systemExerciseId('deadlift'), ExerciseCategory.other), same(motionsByKey['deadlift']));
    expect(motionFor('custom-id', ExerciseCategory.legs), same(motionsByCategory[ExerciseCategory.legs]));
    expect(motionForId('custom-id'), isNull);
  });
}
