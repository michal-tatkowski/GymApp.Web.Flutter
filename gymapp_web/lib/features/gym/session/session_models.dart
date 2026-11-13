import '../../../core/units/weight_unit.dart';
import '../exercises/data/models/exercise.dart';
import '../plans/data/plan_models.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/widgets/workout_entry_sheet.dart' show defaultSet;
import '../deload/deload.dart' show kDeloadShare;

/// One set in a live session. [weightKg] always in kg (like the API).
class SessionSet {
  const SessionSet({
    required this.reps,
    required this.weightKg,
    this.done = false,
    this.durationSeconds,
    this.distanceMeters,
    this.rir,
    this.note,
    this.drop = false,
  });

  final int reps;
  final double weightKg;
  final bool done;

  /// Timed / cardio sets ([Tracking.time], [Tracking.distance]).
  final int? durationSeconds;
  final double? distanceMeters;

  /// Reps in reserve, chosen after the set is done.
  final int? rir;
  final String? note;

  /// A drop set: straight after the set before it, lighter, no rest.
  final bool drop;

  /// [clearRir] / [clearNote] remove them (null alone means "keep").
  SessionSet copyWith({
    int? reps,
    double? weightKg,
    bool? done,
    int? durationSeconds,
    double? distanceMeters,
    int? rir,
    String? note,
    bool clearRir = false,
    bool clearNote = false,
  }) =>
      SessionSet(
        reps: reps ?? this.reps,
        weightKg: weightKg ?? this.weightKg,
        done: done ?? this.done,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        rir: clearRir ? null : rir ?? this.rir,
        note: clearNote ? null : note ?? this.note,
        drop: drop,
      );

  WorkoutSet toWorkoutSet() =>
      WorkoutSet(reps: reps, weight: weightKg, durationSeconds: durationSeconds, distanceMeters: distanceMeters, rir: rir, note: note);

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weightKg': weightKg,
        'done': done,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (distanceMeters != null) 'distanceMeters': distanceMeters,
        if (rir != null) 'rir': rir,
        if (note != null) 'note': note,
        if (drop) 'drop': true,
      };

  factory SessionSet.fromJson(Map<String, dynamic> j) => SessionSet(
        reps: (j['reps'] as num).toInt(),
        weightKg: (j['weightKg'] as num).toDouble(),
        done: j['done'] as bool? ?? false,
        durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
        distanceMeters: (j['distanceMeters'] as num?)?.toDouble(),
        rir: (j['rir'] as num?)?.toInt(),
        note: j['note'] as String?,
        drop: j['drop'] == true,
      );

  static SessionSet fromWorkoutSet(WorkoutSet s) =>
      SessionSet(reps: s.reps, weightKg: s.weight, durationSeconds: s.durationSeconds, distanceMeters: s.distanceMeters);
}

/// What to aim for today, from the last workout and the plan's rep range
/// (double progression: reach the top of the range in every set, then add weight).
/// [deload]: a lighter week (85 % of the weight, one set fewer) — see features/gym/deload.
enum HintKind { addWeight, addReps, repeat, deload }

class ProgressionHint {
  const ProgressionHint({required this.kind, required this.lastSets, required this.sets});

  final HintKind kind;

  /// Last workout of this exercise (kg).
  final List<WorkoutSet> lastSets;

  /// Suggested sets for today (kg), one per planned set.
  final List<SessionSet> sets;
}

/// Reps in reserve from which a set counts as easy (see [suggestNext]).
const kEasyRir = 3;

/// Double progression. Every planned set uses the working (heaviest) weight of
/// last time; when all of last time's sets reached [repsMax], the weight goes up by
/// one plate step of the user's unit and reps restart at [repsMin]. Bodyweight
/// exercises progress in reps. Null without history.
ProgressionHint? suggestNext({
  required List<WorkoutSet>? last,
  required int targetSets,
  required int repsMin,
  required int repsMax,
  required WeightFormat weights,
}) {
  if (last == null || last.isEmpty) return null;
  final working = last.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  final atWorking = last.where((s) => s.weight == working).toList();
  final allAtTop = atWorking.every((s) => s.reps >= repsMax);
  // RIR (when logged for every working set): 3+ in reserve everywhere = clearly too light.
  final easy = atWorking.every((s) => s.rir != null && s.rir! >= kEasyRir);

  if (working == 0) {
    final reps = atWorking.map((s) => s.reps).reduce((a, b) => a < b ? a : b) + (allAtTop ? 1 : 0);
    return ProgressionHint(
      kind: allAtTop ? HintKind.addReps : HintKind.repeat,
      lastSets: last,
      sets: List.filled(targetSets, SessionSet(reps: reps, weightKg: 0)),
    );
  }
  // Top of the range: one plate step up — two when it was still easy. Easy without reaching
  // the top (reps held back): one step up anyway instead of grinding out more reps.
  if (allAtTop || (easy && atWorking.every((s) => s.reps >= repsMin))) {
    final steps = allAtTop && easy ? 2 : 1;
    final heavier = weights.toKg(weights.fromKg(working) + steps * weights.step);
    return ProgressionHint(
      kind: HintKind.addWeight,
      lastSets: last,
      sets: List.filled(targetSets, SessionSet(reps: repsMin, weightKg: heavier)),
    );
  }
  // Same weight; each set starts from what was done last time (at least repsMin).
  return ProgressionHint(
    kind: HintKind.repeat,
    lastSets: last,
    sets: [
      for (var i = 0; i < targetSets; i++)
        SessionSet(
          reps: (i < atWorking.length ? atWorking[i].reps : atWorking.last.reps).clamp(repsMin, repsMax),
          weightKg: working,
        ),
    ],
  );
}

/// Ramp-up sets before the working weight: ~40 % × 10, 60 % × 6, 80 % × 3, rounded
/// down to the plate step of the user's unit. Light work (under 8 steps: 20 kg /
/// 40 lb) needs no ramp; the 80 % set only from 16 steps up. Warm-ups are a guide
/// only — they are not logged.
List<SessionSet> warmUpSets(double workingKg, WeightFormat weights) {
  final working = weights.fromKg(workingKg);
  final step = weights.step;
  if (working < 8 * step) return const [];
  final result = <SessionSet>[];
  for (final (share, reps) in const [(0.4, 10), (0.6, 6), (0.8, 3)]) {
    if (share == 0.8 && working < 16 * step) continue;
    final value = (working * share / step).floor() * step;
    if (value <= 0 || value >= working) continue;
    if (result.isNotEmpty && weights.fromKg(result.last.weightKg) == value) continue;
    result.add(SessionSet(reps: reps, weightKg: weights.toKg(value)));
  }
  return result;
}

/// One exercise of the session.
class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.repsMin,
    required this.repsMax,
    required this.sets,
    this.lastSets,
    this.hint,
    this.savedEntryId,
    this.supersetWithNext = false,
    this.tracking = Tracking.weight,
  });

  final String exerciseId;
  final String name;
  final ExerciseCategory category;
  final int repsMin;
  final int repsMax;
  final List<SessionSet> sets;

  /// Last workout (kg), for the "Last time" line; null = never trained.
  final List<WorkoutSet>? lastSets;
  final HintKind? hint;

  /// Set once its done sets were saved as a log entry (then they are read-only).
  final String? savedEntryId;

  /// From the plan: done in turns with the next exercise (see [WorkoutSession.groupOf]).
  final bool supersetWithNext;

  final Tracking tracking;

  bool get saved => savedEntryId != null;

  /// Heaviest planned set — what the warm-up ramps up to.
  double get workingKg => sets.fold(0.0, (m, s) => s.weightKg > m ? s.weightKg : m);
  List<SessionSet> get doneSets => sets.where((s) => s.done).toList();
  bool get allDone => sets.isNotEmpty && sets.every((s) => s.done);
  String get target => repsMin == repsMax ? '${sets.length} × $repsMin' : '${sets.length} × $repsMin–$repsMax';

  SessionExercise copyWith({List<SessionSet>? sets, String? savedEntryId}) => SessionExercise(
        exerciseId: exerciseId,
        name: name,
        category: category,
        repsMin: repsMin,
        repsMax: repsMax,
        sets: sets ?? this.sets,
        lastSets: lastSets,
        hint: hint,
        savedEntryId: savedEntryId ?? this.savedEntryId,
        supersetWithNext: supersetWithNext,
        tracking: tracking,
      );

  /// From a plan item; prefilled with the progression hint, or empty sets without history.
  /// [deload]: a lighter week — weight × [kDeloadShare] (down to the plate step), one set fewer
  /// (at least 2), no drop sets.
  factory SessionExercise.fromPlan(PlanItem item, List<WorkoutSet>? last, WeightFormat weights, {bool deload = false}) {
    // Timed / cardio: no progression rule — start from last time (or a sensible default).
    if (item.tracking != Tracking.weight) {
      final from = last != null && last.isNotEmpty ? last : [defaultSet(item.tracking)];
      return SessionExercise(
        exerciseId: item.exerciseId,
        name: item.exerciseName,
        category: item.category,
        repsMin: item.repsMin,
        repsMax: item.repsMax,
        sets: [for (var i = 0; i < item.sets; i++) SessionSet.fromWorkoutSet(from[i < from.length ? i : from.length - 1])],
        lastSets: last,
        hint: last == null ? null : HintKind.repeat,
        supersetWithNext: item.supersetWithNext,
        tracking: item.tracking,
      );
    }
    // Last time's drop sets (lighter, at the end) are not working sets: the hint looks at the rest.
    final working = last != null && item.dropSets > 0 && last.length > item.sets ? last.take(item.sets).toList() : last;
    final hint = suggestNext(
      last: working,
      targetSets: item.sets,
      repsMin: item.repsMin,
      repsMax: item.repsMax,
      weights: weights,
    );
    final sets = hint?.sets ?? List.filled(item.sets, SessionSet(reps: item.repsMin, weightKg: 0));
    if (deload && hint != null) {
      final count = item.sets > 2 ? item.sets - 1 : item.sets;
      final light = [
        for (final s in sets.take(count))
          s.weightKg <= 0
              ? s
              : SessionSet(
                  reps: s.reps,
                  weightKg: weights.toKg((weights.fromKg(s.weightKg) * kDeloadShare / weights.step).floor() * weights.step),
                ),
      ];
      return SessionExercise(
        exerciseId: item.exerciseId,
        name: item.exerciseName,
        category: item.category,
        repsMin: item.repsMin,
        repsMax: item.repsMax,
        sets: light,
        lastSets: last,
        hint: HintKind.deload,
        supersetWithNext: item.supersetWithNext,
        tracking: item.tracking,
      );
    }
    return SessionExercise(
      exerciseId: item.exerciseId,
      name: item.exerciseName,
      category: item.category,
      repsMin: item.repsMin,
      repsMax: item.repsMax,
      sets: [...sets, ...dropSetsAfter(sets.last, item.dropSets, weights)],
      lastSets: last,
      hint: hint?.kind,
      supersetWithNext: item.supersetWithNext,
      tracking: item.tracking,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'category': category.apiName,
        'repsMin': repsMin,
        'repsMax': repsMax,
        'sets': sets.map((s) => s.toJson()).toList(),
        if (lastSets != null) 'lastSets': lastSets!.map((s) => s.toJson()).toList(),
        if (hint != null) 'hint': hint!.name,
        if (savedEntryId != null) 'savedEntryId': savedEntryId,
        if (supersetWithNext) 'supersetWithNext': true,
        if (tracking != Tracking.weight) 'tracking': tracking.apiName,
      };

  factory SessionExercise.fromJson(Map<String, dynamic> j) => SessionExercise(
        exerciseId: j['exerciseId'] as String,
        name: j['name'] as String,
        category: ExerciseCategoryX.fromJson(j['category']),
        repsMin: (j['repsMin'] as num).toInt(),
        repsMax: (j['repsMax'] as num).toInt(),
        sets: (j['sets'] as List).cast<Map<String, dynamic>>().map(SessionSet.fromJson).toList(),
        lastSets: (j['lastSets'] as List?)?.cast<Map<String, dynamic>>().map(WorkoutSet.fromJson).toList(),
        hint: HintKind.values.where((h) => h.name == j['hint']).firstOrNull,
        savedEntryId: j['savedEntryId'] as String?,
        supersetWithNext: j['supersetWithNext'] == true,
        tracking: TrackingX.fromJson(j['tracking']),
      );
}

/// A workout in progress, started from a plan.
class WorkoutSession {
  const WorkoutSession({
    required this.planId,
    required this.planName,
    required this.startedAt,
    required this.exercises,
    this.current = 0,
  });

  final String? planId;
  final String planName;
  final DateTime startedAt;
  final List<SessionExercise> exercises;
  final int current;

  SessionExercise get currentExercise => exercises[current];

  /// First and last index of the superset/circuit [index] belongs to
  /// (a plain exercise is a group of one).
  ({int start, int end}) groupOf(int index) {
    var start = index, end = index;
    while (start > 0 && exercises[start - 1].supersetWithNext) {
      start--;
    }
    while (end < exercises.length - 1 && exercises[end].supersetWithNext) {
      end++;
    }
    return (start: start, end: end);
  }

  WorkoutSession copyWith({List<SessionExercise>? exercises, int? current}) => WorkoutSession(
        planId: planId,
        planName: planName,
        startedAt: startedAt,
        exercises: exercises ?? this.exercises,
        current: current ?? this.current,
      );

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'planName': planName,
        'startedAt': startedAt.toIso8601String(),
        'current': current,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        planId: j['planId'] as String?,
        planName: j['planName'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        current: (j['current'] as num).toInt(),
        exercises: (j['exercises'] as List).cast<Map<String, dynamic>>().map(SessionExercise.fromJson).toList(),
      );
}

/// Shown when the session ends.
class SessionSummary {
  const SessionSummary({
    required this.planName,
    required this.duration,
    required this.exercises,
    required this.sets,
    required this.volumeKg,
    required this.records,
    this.sessionId,
    this.recorded,
  });

  final String planName;
  final Duration duration;
  final int exercises;
  final int sets;
  final double volumeKg;

  /// Names of the exercises that set a new record.
  final List<String> records;

  /// Id of the session sent to the history (null when nothing was done).
  final String? sessionId;

  /// Completes with true once the session reached the API (mood / note can then be attached).
  final Future<bool>? recorded;
}

/// [count] drop sets after [last]: each about 20 % lighter than the one before (rounded to
/// the plate step, never below one step), same reps — done to failure, no rest.
List<SessionSet> dropSetsAfter(SessionSet last, int count, WeightFormat weights) {
  final drops = <SessionSet>[];
  var kg = last.weightKg;
  for (var i = 0; i < count; i++) {
    final shown = weights.fromKg(kg) * 0.8;
    final rounded = (shown / weights.step).round() * weights.step;
    kg = kg <= 0 ? 0 : weights.toKg(rounded < weights.step ? weights.step : rounded);
    drops.add(SessionSet(reps: last.reps, weightKg: kg, drop: true));
  }
  return drops;
}
