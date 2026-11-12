import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';
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

  test('angles turn the short way round (no folding up mid-movement)', () {
    const a = Pose(root: Offset.zero, shin: 180, thigh: -150, torso: 110, upperArm: 0, forearm: 0);
    const b = Pose(root: Offset.zero, shin: 180, thigh: 180, torso: 180, upperArm: 0, forearm: 0);
    final mid = Pose.lerp(a, b, 0.5);
    expect(mid.thigh, closeTo(-165, 0.001)); // not 15 (= pointing down)
  });

  test('a sequence (burpee) plays its phases in order and loops', () {
    final burpee = motionsByKey['burpees']!;
    expect(burpee.isSequence, isTrue);
    final n = burpee.frames!.length;
    for (var i = 0; i < n; i++) {
      expect(burpee.poseAt(i / n).root, burpee.frames![i].root);
    }
    expect(burpee.poseAt(1).root, burpee.frames!.first.root);
    expect(burpee.end.root, burpee.frames![2].root); // still picture: the plank
  });
}
