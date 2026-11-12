import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart';

import '../../data/models/exercise.dart';
import 'motion.dart';

// Shorthands. Standing poses start at the ankle on the floor; others at the hip.
const _ankle = Offset(46, floorY);
Pose _stand({
  double shin = 180,
  double thigh = 180,
  double torso = 180,
  double upperArm = 0,
  double forearm = 0,
  Offset root = _ankle,
  double? upperArm2,
  double? forearm2,
}) =>
    Pose(
      root: root,
      shin: shin,
      thigh: thigh,
      torso: torso,
      upperArm: upperArm,
      forearm: forearm,
      upperArm2: upperArm2,
      forearm2: forearm2,
    );

Pose _hip(
  Offset hip, {
  required double torso,
  required double thigh,
  required double shin,
  required double upperArm,
  required double forearm,
  double? thigh2,
  double? shin2,
  double? upperArm2,
  double? forearm2,
}) =>
    Pose(
      root: hip,
      fromAnkle: false,
      shin: shin,
      thigh: thigh,
      torso: torso,
      upperArm: upperArm,
      forearm: forearm,
      thigh2: thigh2,
      shin2: shin2,
      upperArm2: upperArm2,
      forearm2: forearm2,
    );

// ── Static equipment ──────────────────────────────────────────────────────
const _flatBench = [
  Prop.line(Offset(12, 69), Offset(64, 69)),
  Prop.line(Offset(18, 69), Offset(18, floorY)),
  Prop.line(Offset(58, 69), Offset(58, floorY)),
];
const _seat = [
  Prop.line(Offset(30, 73), Offset(56, 73)),
  Prop.line(Offset(43, 73), Offset(43, floorY)),
];
const _pullBar = [Prop.line(Offset(28, 10), Offset(72, 10), width: 3)];

// ── Movements ─────────────────────────────────────────────────────────────
final _squat = Motion(
  _stand(upperArm: -50, forearm: 150),
  _stand(shin: 145, thigh: -100, torso: 140, upperArm: -90, forearm: 110),
  held: Held.barbell,
);

final _deadlift = Motion(
  _stand(shin: 160, thigh: -115, torso: 125),
  _stand(),
  held: Held.barbell,
);

final _romanianDeadlift = Motion(
  _stand(),
  _stand(shin: 172, thigh: -165, torso: 100),
  held: Held.barbell,
);

final _kettlebellSwing = Motion(
  _stand(shin: 168, thigh: -150, torso: 110, upperArm: -10, forearm: -20),
  _stand(upperArm: 95, forearm: 95),
  held: Held.kettlebell,
);

final _lunge = Motion(
  _hip(const Offset(46, 52), torso: 180, thigh: 0, shin: 0, upperArm: 0, forearm: 0, thigh2: 0, shin2: 0),
  _hip(const Offset(42, 64), torso: 180, thigh: 70, shin: 0, upperArm: 0, forearm: 0, thigh2: -20, shin2: -85),
  held: Held.dumbbell,
);

final _bulgarianSquat = Motion(
  _hip(const Offset(44, 54), torso: 180, thigh: 15, shin: 0, upperArm: 0, forearm: 0, thigh2: -20, shin2: -70),
  _hip(const Offset(42, 66), torso: 175, thigh: 75, shin: 0, upperArm: 0, forearm: 0, thigh2: -10, shin2: -95),
  held: Held.dumbbell,
  props: const [Prop.line(Offset(4, 70), Offset(22, 70)), Prop.line(Offset(13, 70), Offset(13, floorY))],
);

final _legPress = Motion(
  _hip(const Offset(36, 72), torso: -145, thigh: 140, shin: 70, upperArm: 30, forearm: 70),
  _hip(const Offset(36, 72), torso: -145, thigh: 112, shin: 112, upperArm: 30, forearm: 70),
  props: const [
    Prop.line(Offset(14, 58), Offset(36, 78)),
    Prop.line(Offset(36, 78), Offset(36, floorY)),
    Prop.line(Offset(70, 40), Offset(84, 68), width: 3),
  ],
);

final _benchPress = Motion(
  _hip(const Offset(56, 64), torso: -90, thigh: 70, shin: 0, upperArm: 20, forearm: 180),
  _hip(const Offset(56, 64), torso: -90, thigh: 70, shin: 0, upperArm: 180, forearm: 180),
  held: Held.barbell,
  props: _flatBench,
);

final _inclinePress = Motion(
  _hip(const Offset(56, 68), torso: -120, thigh: 75, shin: 0, upperArm: 30, forearm: 160),
  _hip(const Offset(56, 68), torso: -120, thigh: 75, shin: 0, upperArm: 160, forearm: 160),
  held: Held.dumbbell,
  props: const [
    Prop.line(Offset(56, 73), Offset(24, 54)),
    Prop.line(Offset(56, 73), Offset(70, 73)),
    Prop.line(Offset(56, 73), Offset(56, floorY)),
  ],
);

final _skullCrusher = Motion(
  _hip(const Offset(56, 64), torso: -90, thigh: 70, shin: 0, upperArm: 165, forearm: -110),
  _hip(const Offset(56, 64), torso: -90, thigh: 70, shin: 0, upperArm: 165, forearm: 170),
  held: Held.barbell,
  props: _flatBench,
);

Motion _seatedPress(Held held) => Motion(
      _hip(const Offset(44, 70), torso: 180, thigh: 90, shin: 0, upperArm: 15, forearm: 170),
      _hip(const Offset(44, 70), torso: 180, thigh: 90, shin: 0, upperArm: 172, forearm: 178),
      held: held,
      props: _seat,
    );

final _lateralRaise = Motion(
  _stand(upperArm: 8, forearm: 8),
  _stand(upperArm: 85, forearm: 88),
  held: Held.dumbbell,
);

final _cableFly = Motion(
  _stand(upperArm: -75, forearm: -60),
  _stand(upperArm: 95, forearm: 90),
  cable: const Offset(8, 20),
);

final _dips = Motion(
  _hip(const Offset(50, 60), torso: 175, thigh: 15, shin: -100, upperArm: 0, forearm: 0),
  _hip(const Offset(50, 72), torso: 168, thigh: 15, shin: -100, upperArm: -70, forearm: 42),
  // Parallel bar at hand height on a post.
  props: const [Prop.line(Offset(42, 61), Offset(64, 61)), Prop.line(Offset(62, 61), Offset(62, floorY))],
);

final _pushUp = Motion(
  _stand(root: const Offset(84, floorY - 2), shin: -112, thigh: -112, torso: -112, upperArm: 0, forearm: 0),
  _stand(root: const Offset(84, floorY - 2), shin: -95, thigh: -95, torso: -95, upperArm: 100, forearm: -51),
);

final _pullUp = Motion(
  _hip(const Offset(50, 72), torso: 180, thigh: 8, shin: -25, upperArm: 180, forearm: 180),
  _hip(const Offset(50, 52), torso: 180, thigh: 8, shin: -25, upperArm: 135, forearm: -95),
  props: _pullBar,
  floor: false,
);

final _latPulldown = Motion(
  _hip(const Offset(46, 72), torso: 175, thigh: 90, shin: 0, upperArm: 178, forearm: 178),
  _hip(const Offset(46, 72), torso: 170, thigh: 90, shin: 0, upperArm: 30, forearm: 165),
  cable: const Offset(48, 4),
  props: _seat,
);

Motion _row(Held held) => Motion(
      _stand(shin: 165, thigh: -160, torso: 105),
      _stand(shin: 165, thigh: -160, torso: 105, upperArm: -150, forearm: -10),
      held: held,
    );

final _cableRow = Motion(
  _hip(const Offset(36, 80), torso: 160, thigh: 80, shin: 95, upperArm: 92, forearm: 92),
  _hip(const Offset(36, 80), torso: -175, thigh: 80, shin: 95, upperArm: -55, forearm: 85),
  cable: const Offset(94, 74),
  props: const [Prop.line(Offset(20, 84), Offset(54, 84))],
);

final _facePull = Motion(
  _stand(upperArm: 95, forearm: 92),
  _stand(upperArm: -95, forearm: 140),
  cable: const Offset(94, 26),
);

Motion _curl(Held held) => Motion(_stand(), _stand(forearm: 160), held: held);

final _pushdown = Motion(
  _stand(torso: 172, upperArm: 0, forearm: 150),
  _stand(torso: 172, upperArm: 0, forearm: 5),
  cable: const Offset(70, 6),
);

final _legCurl = Motion(
  _hip(const Offset(52, 62), torso: -90, thigh: 90, shin: 90, upperArm: 0, forearm: 0),
  _hip(const Offset(52, 62), torso: -90, thigh: 90, shin: 185, upperArm: 0, forearm: 0),
  props: const [Prop.line(Offset(16, 68), Offset(76, 68)), Prop.line(Offset(46, 68), Offset(46, floorY))],
);

final _legExtension = Motion(
  _hip(const Offset(40, 68), torso: 178, thigh: 90, shin: 0, upperArm: 10, forearm: 30),
  _hip(const Offset(40, 68), torso: 178, thigh: 90, shin: 88, upperArm: 10, forearm: 30),
  props: const [Prop.line(Offset(26, 72), Offset(60, 72)), Prop.line(Offset(42, 72), Offset(42, floorY))],
);

final _calfRaise = Motion(
  _stand(),
  _stand(root: const Offset(46, floorY - 6)),
  held: Held.dumbbell,
);

final _hipThrust = Motion(
  _hip(const Offset(44, 74), torso: -135, thigh: 75, shin: 50, upperArm: 40, forearm: 70),
  _hip(const Offset(50, 62), torso: -95, thigh: 70, shin: 20, upperArm: 92, forearm: 92),
  held: Held.barbell,
  props: const [Prop.line(Offset(4, 66), Offset(24, 66)), Prop.line(Offset(12, 66), Offset(12, floorY))],
);

final _plank = Motion(
  _stand(root: const Offset(86, floorY - 2), shin: -103, thigh: -103, torso: -103, upperArm: 0, forearm: -90),
  _stand(root: const Offset(86, floorY - 2), shin: -103, thigh: -108, torso: -98, upperArm: 0, forearm: -90),
);

final _legRaise = Motion(
  _hip(const Offset(50, 68), torso: 180, thigh: 0, shin: 0, upperArm: 180, forearm: 180),
  _hip(const Offset(50, 68), torso: 182, thigh: 95, shin: 95, upperArm: 180, forearm: 180),
  props: _pullBar,
  floor: false,
);

final _cableCrunch = Motion(
  _hip(const Offset(44, 70), torso: 175, thigh: 0, shin: -90, upperArm: 150, forearm: -150),
  _hip(const Offset(44, 70), torso: 110, thigh: 0, shin: -90, upperArm: 80, forearm: -140),
  cable: const Offset(62, 4),
);

final _abWheel = Motion(
  _hip(const Offset(36, 70), torso: 150, thigh: 0, shin: -90, upperArm: 20, forearm: 20),
  _hip(const Offset(42, 76), torso: 105, thigh: 30, shin: -90, upperArm: 85, forearm: 85),
  held: Held.wheel,
);

final _russianTwist = Motion(
  _hip(const Offset(36, 82), torso: -160, thigh: 125, shin: 80, upperArm: 100, forearm: 100),
  _hip(const Offset(36, 82), torso: -160, thigh: 125, shin: 80, upperArm: 50, forearm: 20),
  held: Held.kettlebell,
);

final _run = Motion(
  _hip(const Offset(48, 54), torso: 170, thigh: 30, shin: -25, upperArm: -30, forearm: 60,
      thigh2: -25, shin2: -70, upperArm2: 35, forearm2: 110),
  _hip(const Offset(48, 54), torso: 170, thigh: -25, shin: -70, upperArm: 35, forearm: 110,
      thigh2: 30, shin2: -25, upperArm2: -30, forearm2: 60),
  props: const [Prop.line(Offset(8, floorY + 1), Offset(80, floorY + 1), width: 3), Prop.line(Offset(80, floorY), Offset(84, 40))],
  floor: false,
);

final _rower = Motion(
  _hip(const Offset(44, 80), torso: 150, thigh: 125, shin: 55, upperArm: 95, forearm: 95),
  _hip(const Offset(28, 80), torso: -165, thigh: 95, shin: 92, upperArm: -40, forearm: 85),
  cable: const Offset(86, 76),
  props: const [Prop.line(Offset(10, 86), Offset(90, 86)), Prop.circle(Offset(90, 76), 7)],
  floor: false,
);

final _bike = Motion(
  _hip(const Offset(44, 54), torso: 140, thigh: 70, shin: 15, upperArm: 110, forearm: 115, thigh2: 110, shin2: -25),
  _hip(const Offset(44, 54), torso: 140, thigh: 110, shin: -25, upperArm: 110, forearm: 115, thigh2: 70, shin2: 15),
  props: const [
    Prop.line(Offset(38, 58), Offset(50, 58)),
    Prop.line(Offset(44, 58), Offset(58, 82)),
    Prop.line(Offset(58, 82), Offset(76, 38)),
    Prop.circle(Offset(58, 82), 8),
  ],
);

final _jumpRope = Motion(
  _stand(upperArm: 25, forearm: 70),
  _stand(root: const Offset(46, floorY - 9), upperArm: 25, forearm: 70),
);

// Phases: stand → squat, hands down → plank (feet jumped back) → squat → jump, arms up.
final _burpee = Motion.sequence(
  [
    _hip(const Offset(46, 52), torso: 180, thigh: 0, shin: 0, upperArm: 0, forearm: 0),
    _hip(const Offset(44, 74), torso: 140, thigh: 80, shin: -43, upperArm: 5, forearm: 5),
    _hip(const Offset(50, 78), torso: 115, thigh: -70, shin: -70, upperArm: 0, forearm: 0),
    _hip(const Offset(44, 74), torso: 140, thigh: 80, shin: -43, upperArm: 5, forearm: 5),
    _hip(const Offset(46, 44), torso: 180, thigh: 0, shin: 0, upperArm: 175, forearm: 178),
  ],
  still: 2,
);

final _farmersWalk = Motion(
  _hip(const Offset(46, 52), torso: 180, thigh: 15, shin: -5, upperArm: 0, forearm: 0, thigh2: -15, shin2: -25),
  _hip(const Offset(46, 52), torso: 180, thigh: -15, shin: -25, upperArm: 0, forearm: 0, thigh2: 15, shin2: -5),
  held: Held.dumbbell,
);

final _shrugs = Motion(
  _stand(),
  _stand(upperArm: -6, forearm: 12, torso: 178),
  held: Held.barbell,
);

/// Seed key (GymApp.API Seed/system-exercises.json) → movement.
final Map<String, Motion> motionsByKey = {
  'barbell-bench-press': _benchPress,
  'incline-dumbbell-press': _inclinePress,
  'overhead-press': _seatedPress(Held.barbell),
  'dumbbell-shoulder-press': _seatedPress(Held.dumbbell),
  'dips': _dips,
  'push-up': _pushUp,
  'lateral-raise': _lateralRaise,
  'triceps-pushdown': _pushdown,
  'skull-crusher': _skullCrusher,
  'cable-fly': _cableFly,
  'deadlift': _deadlift,
  'pull-up': _pullUp,
  'chin-up': _pullUp,
  'barbell-row': _row(Held.barbell),
  'dumbbell-row': _row(Held.dumbbell),
  'lat-pulldown': _latPulldown,
  'seated-cable-row': _cableRow,
  'face-pull': _facePull,
  'barbell-curl': _curl(Held.barbell),
  'hammer-curl': _curl(Held.dumbbell),
  'back-squat': _squat,
  'front-squat': _squat,
  'romanian-deadlift': _romanianDeadlift,
  'leg-press': _legPress,
  'walking-lunge': _lunge,
  'bulgarian-split-squat': _bulgarianSquat,
  'leg-curl': _legCurl,
  'leg-extension': _legExtension,
  'hip-thrust': _hipThrust,
  'calf-raise': _calfRaise,
  'plank': _plank,
  'side-plank': _plank,
  'hanging-leg-raise': _legRaise,
  'cable-crunch': _cableCrunch,
  'ab-wheel': _abWheel,
  'russian-twist': _russianTwist,
  'treadmill-run': _run,
  'rowing-machine': _rower,
  'stationary-bike': _bike,
  'jump-rope': _jumpRope,
  'burpees': _burpee,
  'farmers-walk': _farmersWalk,
  'kettlebell-swing': _kettlebellSwing,
  'shrugs': _shrugs,
};

/// For the user's own exercises: a typical movement of the category.
final Map<ExerciseCategory, Motion> motionsByCategory = {
  ExerciseCategory.push: _benchPress,
  ExerciseCategory.pull: _row(Held.barbell),
  ExerciseCategory.legs: _squat,
  ExerciseCategory.core: _plank,
  ExerciseCategory.cardio: _run,
  ExerciseCategory.other: _farmersWalk,
};

/// Id the API gives a system exercise with [key] — same algorithm as
/// SystemExerciseSeeder.IdFor: SHA-1 of "gymapp:system-exercise:{key}", first 16 bytes,
/// UUID version 5 / RFC 4122 variant, printed like .NET's Guid(byte[]) (the first
/// three groups little-endian).
String systemExerciseId(String key) {
  final b = sha1.convert(utf8.encode('gymapp:system-exercise:$key')).bytes.sublist(0, 16);
  b[7] = (b[7] & 0x0F) | 0x50;
  b[8] = (b[8] & 0x3F) | 0x80;
  String hex(Iterable<int> bytes) => bytes.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex([b[3], b[2], b[1], b[0]])}-${hex([b[5], b[4]])}-${hex([b[7], b[6]])}-'
      '${hex(b.sublist(8, 10))}-${hex(b.sublist(10, 16))}';
}

final Map<String, Motion> _byId = {for (final e in motionsByKey.entries) systemExerciseId(e.key): e.value};

/// Movement for an exercise: its own for system exercises, the category's otherwise.
Motion motionFor(String exerciseId, ExerciseCategory category) => _byId[exerciseId] ?? motionsByCategory[category]!;

/// Movement of a system exercise by id; null for the user's own (category unknown here).
Motion? motionForId(String exerciseId) => _byId[exerciseId];
