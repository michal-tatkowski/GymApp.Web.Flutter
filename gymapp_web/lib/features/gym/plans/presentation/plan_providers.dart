import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/providers/retry.dart';
import '../../../../core/storage/secure_storage_keys.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../exercises/data/models/exercise.dart';
import '../data/plan_models.dart';
import '../data/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) => PlanRepository(ref.watch(dioProvider)));

/// The user's plans, last changed first. The last list is kept on the phone, so
/// a plan can be started in a gym without signal (sets then go to the offline queue).
final plansProvider = FutureProvider.autoDispose<List<WorkoutPlan>>(
  (ref) async {
    try {
      final plans = await ref.watch(planRepositoryProvider).getPlans();
      unawaited(SharedPreferences.getInstance().then((prefs) => prefs.setString(
            StorageKeys.plansCache,
            jsonEncode([
              for (final p in plans)
                {
                  'id': p.id,
                  'name': p.name,
                  'exercises': [
                    for (final i in p.items)
                      {...i.toJson(), 'exerciseName': i.exerciseName, 'category': i.category.apiName},
                  ],
                },
            ]),
          )));
      return plans;
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
      final cached = (await SharedPreferences.getInstance()).getString(StorageKeys.plansCache);
      if (cached == null) rethrow;
      return (jsonDecode(cached) as List).cast<Map<String, dynamic>>().map(WorkoutPlan.fromJson).toList();
    }
  },
  retry: noRetry,
);

/// Create / edit / delete, then reload the list. Throws a Failure (shown by the editor).
class PlanActions {
  PlanActions(this._ref);

  final Ref _ref;

  Future<WorkoutPlan> save(String? id, PlanRequest req) async {
    final repo = _ref.read(planRepositoryProvider);
    final plan = id == null ? await repo.create(req) : await repo.update(id, req);
    _ref.invalidate(plansProvider);
    return plan;
  }

  Future<void> delete(String id) async {
    await _ref.read(planRepositoryProvider).delete(id);
    _ref.invalidate(plansProvider);
  }
}

final planActionsProvider = Provider<PlanActions>(PlanActions.new);
