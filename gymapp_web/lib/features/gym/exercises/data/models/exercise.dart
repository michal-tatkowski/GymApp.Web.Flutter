// ExerciseCategory maps to the C# enum: Push=0, Pull=1, Legs=2, Core=3, Cardio=4, Other=5
enum ExerciseCategory { push, pull, legs, core, cardio, other }

extension ExerciseCategoryX on ExerciseCategory {
  static ExerciseCategory? fromJson(dynamic v) {
    if (v == null) return null;
    final i = v is int ? v : int.tryParse(v.toString());
    if (i != null) return ExerciseCategory.values.elementAtOrNull(i);
    // fallback: string name
    final s = v.toString().toLowerCase();
    return ExerciseCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ExerciseCategory.other,
    );
  }

  int toJson() => index;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String? description;
  final bool isCustom;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: (json['id'] ?? json['guid'] ?? '').toString(),
        name: json['name'] as String,
        category: ExerciseCategoryX.fromJson(json['category']) ??
            ExerciseCategory.other,
        description: json['description'] as String?,
        isCustom: (json['isCustom'] as bool?) ?? false,
      );
}
