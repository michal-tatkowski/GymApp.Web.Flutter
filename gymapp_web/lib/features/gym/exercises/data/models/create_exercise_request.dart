import 'exercise.dart';

class CreateExerciseRequest {
  const CreateExerciseRequest({
    required this.name,
    required this.category,
    this.description,
  });

  final String name;
  final ExerciseCategory category;
  final String? description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.toJson(),
        'description': description,
      };
}
