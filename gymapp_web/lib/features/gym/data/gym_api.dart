import 'package:gymapp_web/features/gym/data/models/weekly_workout_plan.dart';
import 'package:dio/dio.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<WeeklyWorkoutPlan> getWeeklyWorkoutPlan() async {
    final res = await _dio.get<dynamic>('Profile');
    return WeeklyWorkoutPlan.fromJson(res.data as Map<String, dynamic>);
  }
}
