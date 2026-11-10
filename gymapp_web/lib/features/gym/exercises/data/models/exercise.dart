/// Matches the API enum ExerciseCategory. On the wire: the name ("Push").
enum ExerciseCategory { push, pull, legs, core, cardio, other }

extension ExerciseCategoryX on ExerciseCategory {
  /// Name used by the API: "Push", "Pull", …
  String get apiName => name[0].toUpperCase() + name.substring(1);

  /// Accepts the API name (any case) and, for older responses, the index ("0").
  static ExerciseCategory fromJson(dynamic v) {
    final s = v?.toString().trim() ?? '';
    final index = int.tryParse(s);
    if (index != null) return ExerciseCategory.values.elementAtOrNull(index) ?? ExerciseCategory.other;
    return ExerciseCategory.values.firstWhere(
      (e) => e.name == s.toLowerCase(),
      orElse: () => ExerciseCategory.other,
    );
  }
}

/// System = built-in, community = created by a user (possibly the current one).
enum ExerciseSource { system, community }

/// GET/POST api/Exercise item:
/// `{ id, name, category, description, imageUrl, popularityCount, source, createdByUserId, isCustom }`.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
    this.popularityCount = 0,
    this.source = ExerciseSource.system,
    this.createdByUserId,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String? description;
  final String? imageUrl;
  final int popularityCount;
  final ExerciseSource source;
  final String? createdByUserId;

  /// Created by the current user.
  final bool isCustom;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String?;
    return Exercise(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: ExerciseCategoryX.fromJson(json['category']),
      description: (description == null || description.trim().isEmpty) ? null : description,
      imageUrl: json['imageUrl'] as String?,
      popularityCount: (json['popularityCount'] as num?)?.toInt() ?? 0,
      source: (json['source']?.toString().toLowerCase() == 'community')
          ? ExerciseSource.community
          : ExerciseSource.system,
      createdByUserId: json['createdByUserId']?.toString(),
      isCustom: (json['isCustom'] as bool?) ?? false,
    );
  }
}
