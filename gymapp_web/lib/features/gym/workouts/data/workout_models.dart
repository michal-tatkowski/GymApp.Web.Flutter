import '../../exercises/data/models/exercise.dart';

/// API date format for training days: "yyyy-MM-dd" (no time, no time zone).
String toApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime fromApiDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// One set: reps × weight in kg (0 = bodyweight). Timed / cardio exercises
/// ([Tracking.time], [Tracking.distance]) also have [durationSeconds] and
/// [distanceMeters]; their reps may be 0.
class WorkoutSet {
  const WorkoutSet({required this.reps, required this.weight, this.durationSeconds, this.distanceMeters});

  final int reps;
  final double weight;
  final int? durationSeconds;
  final double? distanceMeters;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        reps: (json['reps'] as num).toInt(),
        weight: _num(json['weight']),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (distanceMeters != null) 'distanceMeters': distanceMeters,
      };

  @override
  bool operator ==(Object other) =>
      other is WorkoutSet &&
      other.reps == reps &&
      other.weight == weight &&
      other.durationSeconds == durationSeconds &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(reps, weight, durationSeconds, distanceMeters);
}

int totalDuration(Iterable<WorkoutSet> sets) => sets.fold(0, (sum, s) => sum + (s.durationSeconds ?? 0));
double totalDistance(Iterable<WorkoutSet> sets) => sets.fold(0.0, (sum, s) => sum + (s.distanceMeters ?? 0));

/// One training entry: day + sets (+ notes). Volume = Σ reps × weight.
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.date,
    required this.sets,
    this.notes,
    this.volume = 0,
    this.totalReps = 0,
    this.maxWeight = 0,
    this.estimatedOneRepMax = 0,
    this.pending = false,
  });

  /// Saved on the phone only (no connection yet); PendingWorkouts sends it later.
  /// A local entry has no server-computed 1RM.
  factory WorkoutEntry.pending(WorkoutEntryRequest req) => WorkoutEntry(
        id: req.id!,
        date: req.date,
        sets: req.sets,
        notes: req.notes,
        volume: req.sets.fold(0.0, (sum, s) => sum + s.reps * s.weight),
        totalReps: req.sets.fold(0, (sum, s) => sum + s.reps),
        maxWeight: req.sets.fold(0.0, (max, s) => s.weight > max ? s.weight : max),
        pending: true,
      );

  final String id;
  final DateTime date;
  final List<WorkoutSet> sets;
  final String? notes;
  final double volume;
  final int totalReps;
  final double maxWeight;

  /// Best Epley estimate of the sets (weight × (1 + reps / 30)); 0 for bodyweight.
  final double estimatedOneRepMax;

  /// Not on the server yet — see [WorkoutEntry.pending].
  final bool pending;

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) => WorkoutEntry(
        id: json['id'].toString(),
        date: fromApiDate(json['date'] as String),
        sets: (json['sets'] as List).cast<Map<String, dynamic>>().map(WorkoutSet.fromJson).toList(),
        notes: json['notes'] as String?,
        volume: _num(json['volume']),
        totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
        maxWeight: _num(json['maxWeight']),
        estimatedOneRepMax: _num(json['estimatedOneRepMax']),
      );
}

/// POST/PUT body.
class WorkoutEntryRequest {
  const WorkoutEntryRequest({required this.date, required this.sets, this.notes, this.id});

  final DateTime date;
  final List<WorkoutSet> sets;
  final String? notes;

  /// Entry id chosen by the app (POST only). The API returns the existing entry
  /// for a repeated id, so a workout queued offline can be re-sent safely.
  final String? id;

  WorkoutEntryRequest withId(String id) => WorkoutEntryRequest(date: date, sets: sets, notes: notes, id: id);

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': toApiDate(date),
        'sets': sets.map((s) => s.toJson()).toList(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };

  /// Reads back what [toJson] wrote (the offline queue stores requests).
  factory WorkoutEntryRequest.fromJson(Map<String, dynamic> json) => WorkoutEntryRequest(
        id: json['id'] as String?,
        date: fromApiDate(json['date'] as String),
        sets: (json['sets'] as List).cast<Map<String, dynamic>>().map(WorkoutSet.fromJson).toList(),
        notes: json['notes'] as String?,
      );
}

class WorkoutLog {
  const WorkoutLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.entries,
    this.tracking = Tracking.weight,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;

  /// Newest first.
  final List<WorkoutEntry> entries;
  final Tracking tracking;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        entries: (json['entries'] as List).cast<Map<String, dynamic>>().map(WorkoutEntry.fromJson).toList(),
        tracking: TrackingX.fromJson(json['tracking']),
      );
}

/// Exercise the user has trained ("My workouts" list).
class WorkoutSummary {
  const WorkoutSummary({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.trainingDays,
    required this.lastDate,
    required this.lastVolume,
    required this.bestVolume,
    required this.lastTotalReps,
    this.tracking = Tracking.weight,
    this.lastDurationSeconds = 0,
    this.lastDistanceMeters = 0,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;
  final int trainingDays;
  final DateTime lastDate;
  final double lastVolume;
  final double bestVolume;
  final int lastTotalReps;
  final Tracking tracking;
  final int lastDurationSeconds;
  final double lastDistanceMeters;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) => WorkoutSummary(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        trainingDays: (json['trainingDays'] as num).toInt(),
        lastDate: fromApiDate(json['lastDate'] as String),
        lastVolume: _num(json['lastVolume']),
        bestVolume: _num(json['bestVolume']),
        lastTotalReps: (json['lastTotalReps'] as num?)?.toInt() ?? 0,
        tracking: TrackingX.fromJson(json['tracking']),
        lastDurationSeconds: (json['lastDurationSeconds'] as num?)?.toInt() ?? 0,
        lastDistanceMeters: _num(json['lastDistanceMeters']),
      );
}

/// One chart point = one training day.
class ProgressPoint {
  const ProgressPoint({
    required this.date,
    required this.volume,
    required this.totalReps,
    required this.maxWeight,
    required this.sets,
    this.estimatedOneRepMax = 0,
    this.totalDurationSeconds = 0,
    this.totalDistanceMeters = 0,
    this.bestDurationSeconds = 0,
  });

  final DateTime date;
  final double volume;
  final int totalReps;
  final double maxWeight;
  final int sets;
  final int totalDurationSeconds;
  final double totalDistanceMeters;

  /// Longest single set of the day (plank).
  final int bestDurationSeconds;

  /// Best estimated one-rep max of the day (Epley).
  final double estimatedOneRepMax;

  factory ProgressPoint.fromJson(Map<String, dynamic> json) => ProgressPoint(
        date: fromApiDate(json['date'] as String),
        volume: _num(json['volume']),
        totalReps: (json['totalReps'] as num).toInt(),
        maxWeight: _num(json['maxWeight']),
        sets: (json['sets'] as num).toInt(),
        estimatedOneRepMax: _num(json['estimatedOneRepMax']),
        totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
        totalDistanceMeters: _num(json['totalDistanceMeters']),
        bestDurationSeconds: (json['bestDurationSeconds'] as num?)?.toInt() ?? 0,
      );
}

/// A day the user trained (all exercises together).
class TrainingDay {
  const TrainingDay({required this.date, required this.volume, required this.exercises, required this.sets});

  final DateTime date;
  final double volume;
  final int exercises;
  final int sets;

  factory TrainingDay.fromJson(Map<String, dynamic> json) => TrainingDay(
        date: fromApiDate(json['date'] as String),
        volume: _num(json['volume']),
        exercises: (json['exercises'] as num).toInt(),
        sets: (json['sets'] as num).toInt(),
      );
}

/// A day an exercise beat all earlier ones.
class PersonalRecord {
  const PersonalRecord({required this.date, required this.exerciseId, required this.exerciseName, required this.oneRepMax});

  final DateTime date;
  final String exerciseId;
  final String exerciseName;

  /// Estimated 1RM record (otherwise volume).
  final bool oneRepMax;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        date: fromApiDate(json['date'] as String),
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        oneRepMax: json['kind'] == 'OneRepMax',
      );
}

class WorkoutStats {
  const WorkoutStats({required this.days, required this.records});

  final List<TrainingDay> days;
  final List<PersonalRecord> records;

  factory WorkoutStats.fromJson(Map<String, dynamic> json) => WorkoutStats(
        days: (json['days'] as List).cast<Map<String, dynamic>>().map(TrainingDay.fromJson).toList(),
        records: (json['records'] as List).cast<Map<String, dynamic>>().map(PersonalRecord.fromJson).toList(),
      );
}

/// A body weight measurement (kg), one per day.
class BodyWeight {
  const BodyWeight({required this.date, required this.kg});

  final DateTime date;
  final double kg;

  factory BodyWeight.fromJson(Map<String, dynamic> json) =>
      BodyWeight(date: fromApiDate(json['date'] as String), kg: _num(json['weightKg']));
}

/// A finished session (from a plan or "repeat"): when and how long.
class WorkoutSessionInfo {
  const WorkoutSessionInfo({required this.id, required this.name, required this.startedAt, required this.finishedAt, this.planId});

  final String id;
  final String? planId;
  final String name;
  final DateTime startedAt;
  final DateTime finishedAt;

  Duration get duration => finishedAt.difference(startedAt);

  factory WorkoutSessionInfo.fromJson(Map<String, dynamic> json) => WorkoutSessionInfo(
        id: json['id'].toString(),
        planId: json['planId']?.toString(),
        name: json['name'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
        finishedAt: DateTime.parse(json['finishedAt'] as String).toLocal(),
      );
}

/// One exercise of a day in the history, with all its entries of that day.
class DayExercise {
  const DayExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.tracking,
    required this.entries,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;
  final Tracking tracking;
  final List<WorkoutEntry> entries;

  List<WorkoutSet> get sets => [for (final e in entries) ...e.sets];

  factory DayExercise.fromJson(Map<String, dynamic> json) => DayExercise(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        tracking: TrackingX.fromJson(json['tracking']),
        entries: (json['entries'] as List).cast<Map<String, dynamic>>().map(WorkoutEntry.fromJson).toList(),
      );
}

/// A day in the history: exercises in training order and the sessions of that day.
class TrainingDayDetails {
  const TrainingDayDetails({required this.date, required this.exercises, this.sessions = const []});

  final DateTime date;
  final List<DayExercise> exercises;
  final List<WorkoutSessionInfo> sessions;

  int get sets => exercises.fold(0, (n, e) => n + e.sets.length);
  double get volumeKg => exercises.fold(0.0, (v, e) => v + e.sets.fold(0.0, (w, s) => w + s.reps * s.weight));

  factory TrainingDayDetails.fromJson(Map<String, dynamic> json) => TrainingDayDetails(
        date: fromApiDate(json['date'] as String),
        exercises: (json['exercises'] as List).cast<Map<String, dynamic>>().map(DayExercise.fromJson).toList(),
        sessions: (json['sessions'] as List? ?? const []).cast<Map<String, dynamic>>().map(WorkoutSessionInfo.fromJson).toList(),
      );
}
