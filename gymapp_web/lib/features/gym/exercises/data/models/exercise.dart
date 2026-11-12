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

/// What a set of the exercise measures (API `tracking`): reps × weight, time, or distance + time.
enum Tracking { weight, time, distance }

extension TrackingX on Tracking {
  String get apiName => name[0].toUpperCase() + name.substring(1);

  /// Unknown or missing (older API, cached data) = [Tracking.weight].
  static Tracking fromJson(dynamic v) =>
      Tracking.values.firstWhere((t) => t.name == v?.toString().toLowerCase(), orElse: () => Tracking.weight);
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
    this.isFavorite = false,
    this.tracking = Tracking.weight,
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

  /// Starred by the current user (favorites come first in the list).
  final bool isFavorite;

  final Tracking tracking;

  Exercise copyWith({bool? isFavorite}) => Exercise(
        id: id,
        name: name,
        category: category,
        description: description,
        imageUrl: imageUrl,
        popularityCount: popularityCount,
        source: source,
        createdByUserId: createdByUserId,
        isCustom: isCustom,
        isFavorite: isFavorite ?? this.isFavorite,
        tracking: tracking,
      );

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
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      tracking: TrackingX.fromJson(json['tracking']),
    );
  }

  /// Same shape as the API (read back by [Exercise.fromJson]) — for the offline cache.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.apiName,
        'description': description,
        'imageUrl': imageUrl,
        'popularityCount': popularityCount,
        'source': source == ExerciseSource.community ? 'Community' : 'System',
        'createdByUserId': createdByUserId,
        'isCustom': isCustom,
        'isFavorite': isFavorite,
        'tracking': tracking.apiName,
      };
}
