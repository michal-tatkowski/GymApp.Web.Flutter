import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../exercises/data/models/exercise.dart';

/// Short general warm-up and cool-down for a workout, picked by what it trains:
/// upper body, legs, or both. Done as a checklist, not logged anywhere.
enum RoutineStep {
  cardio,
  armCircles,
  bandPullApart,
  catCow,
  hipCircles,
  legSwings,
  squats,
  chest,
  lat,
  shoulder,
  quad,
  hamstring,
  hipFlexor,
  childPose,
  breathing,
}

enum _Focus { upper, lower, full }

_Focus _focusOf(Iterable<ExerciseCategory> categories) {
  final legs = categories.contains(ExerciseCategory.legs);
  final upper = categories.any((c) => c == ExerciseCategory.push || c == ExerciseCategory.pull);
  return legs && !upper ? _Focus.lower : (upper && !legs ? _Focus.upper : _Focus.full);
}

List<RoutineStep> warmUpFor(Iterable<ExerciseCategory> categories) => switch (_focusOf(categories)) {
      _Focus.upper => const [RoutineStep.cardio, RoutineStep.armCircles, RoutineStep.bandPullApart, RoutineStep.catCow],
      _Focus.lower => const [RoutineStep.cardio, RoutineStep.hipCircles, RoutineStep.legSwings, RoutineStep.squats],
      _Focus.full => const [RoutineStep.cardio, RoutineStep.armCircles, RoutineStep.hipCircles, RoutineStep.squats],
    };

List<RoutineStep> coolDownFor(Iterable<ExerciseCategory> categories) => switch (_focusOf(categories)) {
      _Focus.upper => const [RoutineStep.chest, RoutineStep.lat, RoutineStep.shoulder, RoutineStep.childPose, RoutineStep.breathing],
      _Focus.lower => const [RoutineStep.quad, RoutineStep.hamstring, RoutineStep.hipFlexor, RoutineStep.childPose, RoutineStep.breathing],
      _Focus.full => const [RoutineStep.chest, RoutineStep.lat, RoutineStep.quad, RoutineStep.hamstring, RoutineStep.breathing],
    };

String routineStepLabel(AppLocalizations t, RoutineStep s) => switch (s) {
      RoutineStep.cardio => t.wuCardio,
      RoutineStep.armCircles => t.wuArmCircles,
      RoutineStep.bandPullApart => t.wuBandPullApart,
      RoutineStep.catCow => t.wuCatCow,
      RoutineStep.hipCircles => t.wuHipCircles,
      RoutineStep.legSwings => t.wuLegSwings,
      RoutineStep.squats => t.wuSquats,
      RoutineStep.chest => t.cdChest,
      RoutineStep.lat => t.cdLat,
      RoutineStep.shoulder => t.cdShoulder,
      RoutineStep.quad => t.cdQuad,
      RoutineStep.hamstring => t.cdHamstring,
      RoutineStep.hipFlexor => t.cdHipFlexor,
      RoutineStep.childPose => t.cdChildPose,
      RoutineStep.breathing => t.cdBreathing,
    };

/// Ticked steps of the current workout ("warmUp.cardio", "coolDown.lat"); cleared when a
/// workout starts. In memory only: losing them when the app is killed costs nothing.
final routineChecksProvider = NotifierProvider<RoutineChecks, Set<String>>(RoutineChecks.new);

class RoutineChecks extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void clear() => state = const {};
}

/// "Warm up first (5 min) · 1 of 4" with the steps to tick; folds away once all are done.
class RoutineCard extends ConsumerWidget {
  const RoutineCard({super.key, required this.id, required this.title, required this.icon, required this.steps});

  /// "warmUp" or "coolDown" — prefix of the ticked ids and of the widget keys.
  final String id;
  final String title;
  final IconData icon;
  final List<RoutineStep> steps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final checks = ref.watch(routineChecksProvider);
    final done = steps.where((s) => checks.contains('$id.${s.name}')).length;
    final all = done == steps.length;
    return Card(
      key: Key('routine.$id'),
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        key: PageStorageKey('routine.$id.$all'), // folds by itself when the last step is ticked
        initiallyExpanded: !all,
        leading: Icon(all ? Icons.check_circle : icon, color: all ? Theme.of(context).colorScheme.primary : null),
        title: Text(title),
        subtitle: Text(t.routineProgress(done, steps.length)),
        shape: const Border(),
        children: [
          for (final s in steps)
            CheckboxListTile(
              key: Key('routine.$id.${s.name}'),
              dense: true,
              value: checks.contains('$id.${s.name}'),
              onChanged: (_) => ref.read(routineChecksProvider.notifier).toggle('$id.${s.name}'),
              title: Text(routineStepLabel(t, s)),
            ),
        ],
      ),
    );
  }
}
