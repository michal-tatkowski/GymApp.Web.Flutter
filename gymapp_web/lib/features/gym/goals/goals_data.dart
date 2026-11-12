import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failure.dart';
import '../../../core/providers/retry.dart';
import '../../auth/presentation/auth_providers.dart';
import '../workouts/data/workout_models.dart';

/// Matches the API (GoalKind).
enum GoalKind { exerciseWeight, weeklyWorkouts, bodyWeight }

extension GoalKindX on GoalKind {
  String get apiName => name[0].toUpperCase() + name.substring(1);

  static GoalKind fromJson(dynamic v) => GoalKind.values
      .firstWhere((k) => k.name.toLowerCase() == v?.toString().toLowerCase(), orElse: () => GoalKind.weeklyWorkouts);
}

/// Must match the API (GoalRules).
const kMaxGoals = 20;
const kMaxWeeklyWorkouts = 14;

class Goal {
  const Goal({
    required this.id,
    required this.kind,
    required this.target,
    this.exerciseId,
    this.exerciseName,
    this.startValue,
    this.deadline,
    this.achievedAt,
  });

  final String id;
  final GoalKind kind;

  /// kg (exercise, body weight) or workouts per week.
  final double target;
  final String? exerciseId;
  final String? exerciseName;

  /// Where the user started (heaviest set / body weight when the goal was set).
  final double? startValue;
  final DateTime? deadline;
  final DateTime? achievedAt;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'].toString(),
        kind: GoalKindX.fromJson(json['kind']),
        target: (json['target'] as num).toDouble(),
        exerciseId: json['exerciseId']?.toString(),
        exerciseName: json['exerciseName'] as String?,
        startValue: (json['startValue'] as num?)?.toDouble(),
        deadline: json['deadline'] == null ? null : fromApiDate(json['deadline'] as String),
        achievedAt: json['achievedAt'] == null ? null : DateTime.parse(json['achievedAt'] as String).toLocal(),
      );

  Map<String, dynamic> toRequest({bool? achieved}) => {
        'kind': kind.apiName,
        if (exerciseId != null) 'exerciseId': exerciseId,
        'target': target,
        if (startValue != null) 'startValue': startValue,
        if (deadline != null) 'deadline': toApiDate(deadline!),
        if (achieved != null) 'achieved': achieved,
      };
}

/// Where a goal stands: current value and 0–1 progress from the start value.
class GoalProgress {
  const GoalProgress({required this.current, required this.fraction});

  final double? current;
  final double fraction;

  bool get reached => fraction >= 1;
}

/// [current]: heaviest set (exercise), workouts this week, or the latest body weight.
GoalProgress goalProgress(Goal goal, double? current) {
  if (current == null) return const GoalProgress(current: null, fraction: 0);
  if (goal.kind == GoalKind.weeklyWorkouts) {
    return GoalProgress(current: current, fraction: (current / goal.target).clamp(0, 1).toDouble());
  }
  final start = goal.startValue ?? (goal.kind == GoalKind.bodyWeight ? current : 0);
  final span = goal.target - start;
  if (span == 0) return GoalProgress(current: current, fraction: 1);
  // Works both ways: gaining (span > 0) and losing body weight (span < 0).
  return GoalProgress(current: current, fraction: ((current - start) / span).clamp(0, 1).toDouble());
}

class GoalRepository {
  GoalRepository(this._dio);

  final Dio _dio;

  Future<List<Goal>> list() => _guard(() async {
        final res = await _dio.get<dynamic>('Goals');
        return (res.data as List).cast<Map<String, dynamic>>().map(Goal.fromJson).toList();
      });

  Future<Goal> create(Goal goal) => _guard(() async {
        final res = await _dio.post<dynamic>('Goals', data: goal.toRequest());
        return Goal.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Goal> update(Goal goal, {bool? achieved}) => _guard(() async {
        final res = await _dio.put<dynamic>('Goals/${goal.id}', data: goal.toRequest(achieved: achieved));
        return Goal.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> delete(String id) => _guard(() => _dio.delete<dynamic>('Goals/$id'));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) => GoalRepository(ref.watch(dioProvider)));

final goalsProvider =
    FutureProvider.autoDispose<List<Goal>>((ref) => ref.watch(goalRepositoryProvider).list(), retry: noRetry);
