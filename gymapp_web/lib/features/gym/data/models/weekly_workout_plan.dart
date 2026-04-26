class WeeklyWorkoutPlan {
  const WeeklyWorkoutPlan({this.id});

  final String? id;

  factory WeeklyWorkoutPlan.fromJson(Map<String, dynamic> json) =>
      WeeklyWorkoutPlan(id: json['id'] as String?);
}
