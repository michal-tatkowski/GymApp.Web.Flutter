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

/// When a goal will be reached at the current pace.
sealed class GoalForecast {
  const GoalForecast();
}

/// Within a week.
class ForecastSoon extends GoalForecast {
  const ForecastSoon();
}

class ForecastWeeks extends GoalForecast {
  const ForecastWeeks(this.weeks, {this.late = false});

  final int weeks;

  /// Later than the goal's deadline.
  final bool late;
}

/// Flat, going the other way, or too far off (over two years) to promise anything.
class ForecastNoTrend extends GoalForecast {
  const ForecastNoTrend();
}

/// Straight line through the last 12 weeks of [points] (date, value): heaviest set for an
/// exercise goal, body weight for a weight goal. Null with too little data (under three
/// days or two weeks) — then the card simply says nothing.
GoalForecast? forecastGoal(List<(DateTime, double)> points, double target, DateTime today, {DateTime? deadline}) {
  final from = today.subtract(const Duration(days: 84));
  final recent = points.where((p) => !p.$1.isBefore(from)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  if (recent.length < 3 || recent.last.$1.difference(recent.first.$1).inDays < 14) return null;

  // Least squares: value = a + b * day.
  final xs = [for (final p in recent) p.$1.difference(from).inHours / 24.0];
  final ys = [for (final p in recent) p.$2];
  final n = xs.length;
  final mx = xs.reduce((a, b) => a + b) / n, my = ys.reduce((a, b) => a + b) / n;
  var sxy = 0.0, sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - mx) * (ys[i] - my);
    sxx += (xs[i] - mx) * (xs[i] - mx);
  }
  if (sxx == 0) return const ForecastNoTrend();
  final slope = sxy / sxx;
  final now = my + slope * (today.difference(from).inHours / 24.0 - mx);
  final gap = target - now;
  if (gap == 0 || gap.sign != slope.sign || slope.abs() < 1e-6) return gap.abs() < 1e-9 ? const ForecastSoon() : const ForecastNoTrend();
  final days = gap / slope;
  if (days > 730) return const ForecastNoTrend();
  if (days <= 7) return const ForecastSoon();
  final late = deadline != null && today.add(Duration(days: days.ceil())).isAfter(deadline);
  return ForecastWeeks((days / 7).round(), late: late);
}
