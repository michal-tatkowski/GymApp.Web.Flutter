import '../../exercises/data/models/exercise.dart';

/// Must match the API (PlanLimits).
const kPlanMaxNameLength = 60;
const kPlanMaxExercises = 20;
const kPlanMaxSets = 10;
const kPlanMaxReps = 100;

/// Exercise in a plan with its target: [sets] × [repsMin]–[repsMax] reps.
class PlanItem {
  const PlanItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 12,
    this.supersetWithNext = false,
    this.tracking = Tracking.weight,
  });

  final String exerciseId;
  final String exerciseName;
  final ExerciseCategory category;
  final int sets;
  final int repsMin;
  final int repsMax;

  /// Done in turns with the next exercise, no rest in between (a chain of 3+ = circuit).
  final bool supersetWithNext;

  /// From the API (the exercise's type); not sent back.
  final Tracking tracking;

  PlanItem copyWith({int? sets, int? repsMin, int? repsMax, bool? supersetWithNext}) => PlanItem(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        category: category,
        sets: sets ?? this.sets,
        repsMin: repsMin ?? this.repsMin,
        repsMax: repsMax ?? this.repsMax,
        supersetWithNext: supersetWithNext ?? this.supersetWithNext,
        tracking: tracking,
      );

  /// "3 × 8–12" or "4 × 5".
  String get target => repsMin == repsMax ? '$sets × $repsMin' : '$sets × $repsMin–$repsMax';

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        exerciseId: json['exerciseId'].toString(),
        exerciseName: json['exerciseName'] as String,
        category: ExerciseCategoryX.fromJson(json['category']),
        sets: (json['sets'] as num).toInt(),
        repsMin: (json['repsMin'] as num).toInt(),
        repsMax: (json['repsMax'] as num).toInt(),
        supersetWithNext: json['supersetWithNext'] == true,
        tracking: TrackingX.fromJson(json['tracking']),
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets,
        'repsMin': repsMin,
        'repsMax': repsMax,
        'supersetWithNext': supersetWithNext,
      };
}

class WorkoutPlan {
  const WorkoutPlan({required this.id, required this.name, required this.items});

  final String id;
  final String name;

  /// In training order.
  final List<PlanItem> items;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'].toString(),
        name: json['name'] as String,
        items: (json['exercises'] as List).cast<Map<String, dynamic>>().map(PlanItem.fromJson).toList(),
      );
}

/// POST/PUT body.
class PlanRequest {
  const PlanRequest({required this.name, required this.items});

  final String name;
  final List<PlanItem> items;

  /// The last exercise has nothing to pair with, so its link is dropped.
  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'exercises': [
          for (var i = 0; i < items.length; i++)
            (i == items.length - 1 ? items[i].copyWith(supersetWithNext: false) : items[i]).toJson(),
        ],
      };
}

/// Ready-made plan from the API (api/Plans/templates), opened in the editor to save as one's own.
class PlanTemplate {
  const PlanTemplate({required this.key, required this.name, required this.description, required this.daysPerWeek, required this.items});

  final String key;
  final String name;
  final String description;
  final int daysPerWeek;
  final List<PlanItem> items;

  factory PlanTemplate.fromJson(Map<String, dynamic> json) => PlanTemplate(
        key: json['key'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 3,
        items: (json['exercises'] as List).cast<Map<String, dynamic>>().map(PlanItem.fromJson).toList(),
      );
}
