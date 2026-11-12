import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable, Refreshable;
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/errors/failure_messages.dart';
import '../../../core/units/weight_unit.dart';
import '../../../core/validation/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/presentation/widgets/body_weight_card.dart';
import '../exercises/data/models/exercise.dart';
import '../plans/presentation/exercise_picker_sheet.dart';
import '../today/week_summary.dart';
import '../workouts/presentation/workout_providers.dart';
import 'goals_data.dart';

/// Current value of every goal kind: heaviest set per exercise, workouts this week,
/// latest body weight. Null while loading or without data.
double? currentFor(Goal goal, WidgetRef ref, int firstDayOfWeek) => switch (goal.kind) {
      GoalKind.exerciseWeight => ref
          .watch(recordsProvider)
          .value
          ?.where((r) => r.exerciseId == goal.exerciseId)
          .firstOrNull
          ?.heaviestWeight
          ?.value,
      GoalKind.weeklyWorkouts => ref.watch(workoutStatsProvider).value == null
          ? null
          : summarizeWeek(ref.watch(workoutStatsProvider).value!, DateTime.now(), firstDayOfWeek).workouts.toDouble(),
      GoalKind.bodyWeight => ref.watch(bodyWeightsProvider).value?.lastOrNull?.kg,
    };

/// "Goals" on Today: each with a progress bar; "+" adds one. A goal reached for the
/// first time is marked achieved (weekly goals repeat every week, so never).
class GoalsCard extends ConsumerStatefulWidget {
  const GoalsCard({super.key});

  @override
  ConsumerState<GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends ConsumerState<GoalsCard> {
  final _marking = <String>{};

  void _markReached(Goal goal) {
    if (!_marking.add(goal.id)) return;
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    ref.read(goalRepositoryProvider).update(goal, achieved: true).then((_) {
      ref.invalidate(goalsProvider);
      messenger.showSnackBar(SnackBar(content: Text(t.goalReached(goalTitle(t, goal, ref.read(weightFormatProvider))))));
    }, onError: (Object _) {
      _marking.remove(goal.id); // try again next time
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goals = ref.watch(goalsProvider).value;
    final weights = ref.watch(weightFormatProvider);
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
          child: Row(
            children: [
              Expanded(child: Text(t.goals, style: theme.textTheme.titleMedium)),
              IconButton(
                key: const Key('goals.add'),
                tooltip: t.addGoal,
                icon: const Icon(Icons.add),
                onPressed: (goals?.length ?? 0) >= kMaxGoals ? null : () => showAddGoalSheet(context),
              ),
            ],
          ),
        ),
        if (goals == null || goals.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(t.noGoalsYet),
              onTap: () => showAddGoalSheet(context),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final goal in goals)
                  Builder(builder: (context) {
                    final progress = goalProgress(goal, currentFor(goal, ref, firstDay));
                    if (progress.reached && goal.achievedAt == null && goal.kind != GoalKind.weeklyWorkouts) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _markReached(goal) : null);
                    }
                    return _GoalTile(goal: goal, progress: progress, weights: weights);
                  }),
              ],
            ),
          ),
      ],
    );
  }
}

String goalTitle(AppLocalizations t, Goal goal, WeightFormat weights) => switch (goal.kind) {
      GoalKind.exerciseWeight => t.goalExerciseTitle(goal.exerciseName ?? '?', weights.withUnit(goal.target)),
      GoalKind.weeklyWorkouts => t.goalWeeklyTitle(goal.target.round()),
      GoalKind.bodyWeight => t.goalBodyWeightTitle(weights.withUnit(goal.target)),
    };

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, required this.progress, required this.weights});

  final Goal goal;
  final GoalProgress progress;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final current = progress.current;
    final now = current == null
        ? t.goalNoData
        : goal.kind == GoalKind.weeklyWorkouts
            ? t.goalThisWeek(current.round())
            : t.goalNow(weights.withUnit(current));
    final achieved = goal.achievedAt != null || (goal.kind == GoalKind.weeklyWorkouts && progress.reached);

    return ListTile(
      key: Key('goal.${goal.id}'),
      leading: Icon(
        achieved ? Icons.emoji_events : switch (goal.kind) {
          GoalKind.exerciseWeight => Icons.fitness_center,
          GoalKind.weeklyWorkouts => Icons.event_repeat,
          GoalKind.bodyWeight => Icons.monitor_weight_outlined,
        },
        color: achieved ? theme.colorScheme.tertiary : theme.colorScheme.primary,
      ),
      title: Text(goalTitle(t, goal, weights)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress.fraction, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 4),
          Text(
            [
              now,
              if (goal.deadline != null) t.goalBy(DateFormat.yMMMd(locale).format(goal.deadline!)),
            ].join(' · '),
          ),
          if (!achieved && !progress.reached && goal.kind != GoalKind.weeklyWorkouts) _GoalForecastLine(goal: goal),
        ],
      ),
      trailing: PopupMenuButton<String>(
        tooltip: t.more,
        onSelected: (_) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(goalRepositoryProvider).delete(goal.id);
            ref.invalidate(goalsProvider);
          } catch (e) {
            messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
          }
        },
        itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(t.delete))],
      ),
    );
  }
}

Future<void> showAddGoalSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _AddGoalSheet(),
    );

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _form = GlobalKey<FormState>();
  final _target = TextEditingController();
  GoalKind _kind = GoalKind.exerciseWeight;
  Exercise? _exercise;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    if (_kind == GoalKind.exerciseWeight && _exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.goalPickExercise)));
      return;
    }
    final weights = ref.read(weightFormatProvider);
    final value = parseDecimal(_target.text)!;
    final draft = Goal(
      id: '',
      kind: _kind,
      target: _kind == GoalKind.weeklyWorkouts ? value.roundToDouble() : weights.toKg(value),
      exerciseId: _exercise?.id,
      deadline: _deadline,
    );
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final start = await _startValue(draft);
      await ref.read(goalRepositoryProvider).create(Goal(
            id: '',
            kind: draft.kind,
            target: draft.target,
            exerciseId: draft.exerciseId,
            deadline: draft.deadline,
            startValue: draft.kind == GoalKind.weeklyWorkouts ? null : start,
          ));
      ref.invalidate(goalsProvider);
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  /// Where the user is now — the 0 % of the progress bar. Loaded here, not watched:
  /// the card may not have needed records or body weight yet.
  Future<double?> _startValue(Goal draft) async {
    Future<T?> load<T>(ProviderListenable<AsyncValue<T>> provider, Refreshable<Future<T>> future) async {
      final keepAlive = ref.listenManual(provider, (_, _) {});
      try {
        return await ref.read(future);
      } catch (_) {
        return null; // no data (offline) — the goal still works, starting from the first value seen
      } finally {
        keepAlive.close();
      }
    }

    return switch (draft.kind) {
      GoalKind.exerciseWeight => (await load(recordsProvider, recordsProvider.future))
          ?.where((r) => r.exerciseId == draft.exerciseId)
          .firstOrNull
          ?.heaviestWeight
          ?.value,
      GoalKind.bodyWeight => (await load(bodyWeightsProvider, bodyWeightsProvider.future))?.lastOrNull?.kg,
      GoalKind.weeklyWorkouts => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final weights = ref.watch(weightFormatProvider);
    final locale = Localizations.localeOf(context).toString();
    final weekly = _kind == GoalKind.weeklyWorkouts;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.addGoal, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<GoalKind>(
                key: const Key('goal.kind'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: GoalKind.exerciseWeight, label: Text(t.goalKindExercise)),
                  ButtonSegment(value: GoalKind.weeklyWorkouts, label: Text(t.goalKindWeekly)),
                  ButtonSegment(value: GoalKind.bodyWeight, label: Text(t.goalKindBodyWeight)),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.single),
              ),
              const SizedBox(height: 12),
              if (_kind == GoalKind.exerciseWeight)
                ListTile(
                  key: const Key('goal.exercise'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center),
                  title: Text(_exercise?.name ?? t.goalPickExercise),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await pickExercise(context);
                    if (picked != null) setState(() => _exercise = picked);
                  },
                ),
              TextFormField(
                key: const Key('goal.target'),
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: weekly ? t.goalTargetWorkouts : t.goalTargetWeight,
                  suffixText: weekly ? null : weights.label,
                ),
                validator: (v) {
                  final n = parseDecimal(v ?? '');
                  final max = weekly ? kMaxWeeklyWorkouts : weights.maxSetWeight.floor();
                  return n == null || n < 1 || n > max ? t.numberOutOfRange(1, max) : null;
                },
              ),
              ListTile(
                key: const Key('goal.deadline'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(_deadline == null ? t.goalNoDeadline : t.goalBy(DateFormat.yMMMd(locale).format(_deadline!))),
                trailing: _deadline == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _deadline = null)),
                onTap: weekly
                    ? null
                    : () async {
                        final now = DateUtils.dateOnly(DateTime.now());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now.add(const Duration(days: 90)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 3 * 365)),
                        );
                        if (picked != null) setState(() => _deadline = picked);
                      },
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('goal.save'),
                onPressed: _saving ? null : _save,
                child: Text(t.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "At this pace: about 6 weeks" under a weight or body-weight goal, from the trend of
/// the last 12 weeks. Nothing while loading or with too little data.
class _GoalForecastLine extends ConsumerWidget {
  const _GoalForecastLine({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final List<(DateTime, double)>? points = switch (goal.kind) {
      GoalKind.exerciseWeight when goal.exerciseId != null => ref
          .watch(workoutProgressProvider(goal.exerciseId!))
          .value
          ?.where((p) => p.maxWeight > 0)
          .map((p) => (p.date, p.maxWeight))
          .toList(),
      GoalKind.bodyWeight => ref.watch(bodyWeightsProvider).value?.map((w) => (w.date, w.kg)).toList(),
      _ => null,
    };
    if (points == null) return const SizedBox.shrink();
    final forecast = forecastGoal(points, goal.target, DateUtils.dateOnly(DateTime.now()), deadline: goal.deadline);
    final text = switch (forecast) {
      null => null,
      ForecastSoon() => t.goalForecastSoon,
      ForecastWeeks(late: true) => t.goalForecastLate,
      ForecastWeeks(:final weeks) => t.goalForecastWeeks(weeks),
      ForecastNoTrend() => t.goalForecastNoTrend,
    };
    if (text == null) return const SizedBox.shrink();
    final late = forecast is ForecastWeeks && forecast.late;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 16, color: late ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(child: Text(text, key: Key('goal.forecast.${goal.id}'), style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
