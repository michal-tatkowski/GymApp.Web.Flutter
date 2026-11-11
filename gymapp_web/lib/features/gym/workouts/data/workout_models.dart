import '../../exercises/data/models/exercise.dart';

/// API date format for training days: "yyyy-MM-dd" (no time, no time zone).
String toApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime fromApiDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// One set: reps × weight in kg (0 = bodyweight).
class WorkoutSet {
  const WorkoutSet({required this.reps, required this.weight});

  final int reps;
  final double weight;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      WorkoutSet(reps: (json['reps'] as num).toInt(), weight: _num(json['weight']));

  Map<String, dynamic> toJson() => {'reps': reps, 'weight': weight};

  @override
  bool operator ==(Object other) => other is WorkoutSet && other.reps == reps && other.weight == weight;

  @override
  int get hashCode => Object.hash(reps, weight);
}

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
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;

  /// Newest first.
  final List<WorkoutEntry> entries;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        entries: (json['entries'] as List).cast<Map<String, dynamic>>().map(WorkoutEntry.fromJson).toList(),
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
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;
  final int trainingDays;
  final DateTime lastDate;
  final double lastVolume;
  final double bestVolume;
  final int lastTotalReps;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) => WorkoutSummary(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        trainingDays: (json['trainingDays'] as num).toInt(),
        lastDate: fromApiDate(json['lastDate'] as String),
        lastVolume: _num(json['lastVolume']),
        bestVolume: _num(json['bestVolume']),
        lastTotalReps: (json['lastTotalReps'] as num?)?.toInt() ?? 0,
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
  });

  final DateTime date;
  final double volume;
  final int totalReps;
  final double maxWeight;
  final int sets;

  /// Best estimated one-rep max of the day (Epley).
  final double estimatedOneRepMax;

  factory ProgressPoint.fromJson(Map<String, dynamic> json) => ProgressPoint(
        date: fromApiDate(json['date'] as String),
        volume: _num(json['volume']),
        totalReps: (json['totalReps'] as num).toInt(),
        maxWeight: _num(json['maxWeight']),
        sets: (json['sets'] as num).toInt(),
        estimatedOneRepMax: _num(json['estimatedOneRepMax']),
      );
}
