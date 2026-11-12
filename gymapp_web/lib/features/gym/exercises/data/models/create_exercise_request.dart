import 'exercise.dart';

class CreateExerciseRequest {
  const CreateExerciseRequest({
    required this.name,
    required this.category,
    this.description,
    this.tracking = Tracking.weight,
  });

  final String name;
  final ExerciseCategory category;
  final String? description;
  final Tracking tracking;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.apiName,
        'description': description,
        'tracking': tracking.apiName,
      };
}
