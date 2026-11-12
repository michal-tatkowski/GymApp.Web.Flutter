import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/units/measures.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../exercises/data/models/exercise.dart';
import '../exercises/presentation/category_ui.dart';
import '../exercises/presentation/illustration/motion.dart';
import '../exercises/presentation/illustration/motions.dart';
import '../plans/data/plan_models.dart';
import '../plans/presentation/exercise_picker_sheet.dart';
import '../workouts/presentation/exercise_workouts_screen.dart';
import '../workouts/presentation/workout_providers.dart';
import 'plate_calculator.dart';
import 'session_models.dart';
import 'session_providers.dart';

/// Starts [plan] (asking first when another workout is in progress) and opens it.
Future<void> startSession(BuildContext context, WidgetRef ref, WorkoutPlan plan) async {
  final t = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final active = ref.read(activeSessionProvider);
  if (active != null) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.sessionInProgressTitle),
        content: Text(t.sessionInProgressBody(active.planName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.sessionResume)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.sessionStartNew)),
        ],
      ),
    );
    if (replace == null) return;
    if (replace) ref.read(activeSessionProvider.notifier).discard();
  }
  try {
    if (ref.read(activeSessionProvider) == null) await ref.read(activeSessionProvider.notifier).start(plan);
    await navigator.push(MaterialPageRoute<void>(builder: (_) => const SessionScreen()));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
  }
}

/// The workout in progress: one exercise at a time, set by set.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _clock;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  SessionNotifier get _session => ref.read(activeSessionProvider.notifier);

  Future<void> _run(Future<void> Function(WorkoutActions actions) action) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = WorkoutActions.of(context);
    setState(() => _busy = true);
    try {
      await action(actions);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    SessionSummary? summary;
    await _run((actions) async => summary = await _session.finish(actions));
    final result = summary;
    if (result == null || !mounted) return;
    await showDialog<void>(context: context, builder: (_) => _SummaryDialog(summary: result));
    navigator.pop();
  }

  Future<void> _menu(String action) async {
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    if (action == 'add') {
      final s = ref.read(activeSessionProvider);
      final exercise = await pickExercise(context, alreadyAdded: {...?s?.exercises.map((e) => e.exerciseId)});
      if (exercise != null) await _run((actions) => _session.addExercise(exercise, actions));
    } else if (action == 'discard') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.sessionDiscardTitle),
          content: Text(t.sessionDiscardBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.sessionDiscard)),
          ],
        ),
      );
      if (ok == true) {
        _session.discard();
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final session = ref.watch(activeSessionProvider);
    final weights = ref.watch(weightFormatProvider);
    if (session == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(t.sessionNone)));
    }
    final index = session.current;
    final exercise = session.currentExercise;
    // Previous/Next move by group: a superset is one step of the workout.
    final group = session.groupOf(index);
    final last = group.end == session.exercises.length - 1;
    final elapsed = DateTime.now().difference(session.startedAt);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.planName),
            Text(
              _formatElapsed(elapsed),
              key: const Key('session.elapsed'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        actions: [
          TextButton(key: const Key('session.finish'), onPressed: _busy ? null : _finish, child: Text(t.sessionFinish)),
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'add', child: Text(t.addExercise)),
              PopupMenuItem(value: 'discard', child: Text(t.sessionDiscard)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _ExerciseStrip(
            session: session,
            onTap: _busy ? null : (i) => _run((actions) => _session.goTo(i, actions)),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(exercise.exerciseId), // fresh scroll position per exercise
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (group.end > group.start)
                  _SupersetBanner(position: index - group.start + 1, size: group.end - group.start + 1),
                _ExerciseHeader(exercise: exercise, weights: weights),
                if (!exercise.saved && exercise.doneSets.isEmpty && exercise.tracking == Tracking.weight) _WarmUpCard(exercise: exercise, weights: weights),
                const SizedBox(height: 12),
                for (var i = 0; i < exercise.sets.length; i++)
                  _SetRow(
                    key: Key('session.set$i'),
                    number: i + 1,
                    set: exercise.sets[i],
                    weights: weights,
                    readOnly: exercise.saved,
                    onChanged: (v) => _session.updateSet(index, i, v),
                    onToggle: () => _session.toggleDone(index, i),
                    onRemove: exercise.sets.length > 1 ? () => _session.removeSet(index, i) : null,
                    tracking: exercise.tracking,
                    onWeightTap: exercise.tracking == Tracking.weight ? (kg) => showPlateCalculator(context, kg) : null,
                  ),
                if (!exercise.saved)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('session.addSet'),
                      onPressed: () => _session.addSet(index),
                      icon: const Icon(Icons.add),
                      label: Text(t.addSet),
                    ),
                  )
                else
                  ListTile(
                    leading: Icon(Icons.cloud_done_outlined, color: context.appColors.success),
                    title: Text(t.sessionSaved),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (group.start > 0)
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run((actions) => _session.goTo(session.groupOf(group.start - 1).start, actions)),
                      icon: const Icon(Icons.chevron_left),
                      label: Text(t.sessionPrevious),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const Key('session.next'),
                    onPressed: _busy ? null : last ? _finish : () => _run((actions) => _session.goTo(group.end + 1, actions)),
                    icon: Icon(last ? Icons.flag : Icons.chevron_right),
                    label: Text(last ? t.sessionFinish : t.sessionNext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}' : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}

/// Chips with all exercises; done ones ticked. Tap to jump.
class _ExerciseStrip extends StatelessWidget {
  const _ExerciseStrip({required this.session, required this.onTap});

  final WorkoutSession session;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: session.exercises.length,
          // A link between chips = done in turns (superset/circuit).
          separatorBuilder: (context, i) => session.exercises[i].supersetWithNext
              ? Icon(Icons.link, size: 18, color: Theme.of(context).colorScheme.tertiary)
              : const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final e = session.exercises[i];
            final finished = e.saved || e.allDone;
            return ChoiceChip(
              key: Key('session.exercise$i'),
              selected: i == session.current,
              avatar: finished ? const Icon(Icons.check, size: 16) : null,
              showCheckmark: false,
              label: Text(e.name, overflow: TextOverflow.ellipsis),
              // Current one stays enabled (not greyed out); tapping it does nothing.
              onSelected: onTap == null ? null : (_) => i == session.current ? null : onTap!(i),
            );
          },
        ),
      );
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise, required this.weights});

  final SessionExercise exercise;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final last = exercise.lastSets;
    final today = exercise.sets.isEmpty ? null : exercise.sets.first;
    final hint = switch (exercise.hint) {
      HintKind.addWeight when today != null => t.hintAddWeight(weights.withUnit(today.weightKg), today.reps),
      HintKind.addReps => t.hintAddReps,
      HintKind.repeat when exercise.tracking != Tracking.weight => t.hintBeatLastTime,
      HintKind.repeat => t.hintRepeat(exercise.repsMax),
      _ => t.hintFirstTime,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(categoryIcon(exercise.category), color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(exercise.name, style: theme.textTheme.titleLarge)),
          ],
        ),
        Center(
          child: MotionView(
            key: ValueKey('session.motion.${exercise.exerciseId}'),
            motion: motionFor(exercise.exerciseId, exercise.category),
            size: 120,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          exercise.tracking == Tracking.weight ? t.sessionTarget(exercise.target) : t.sessionTargetSets(exercise.sets.length),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Card(
          key: const Key('session.hint'),
          color: theme.colorScheme.secondaryContainer,
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(
              exercise.hint == HintKind.addWeight || exercise.hint == HintKind.addReps ? Icons.trending_up : Icons.tips_and_updates_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            title: Text(hint),
            subtitle: last == null ? null : Text(t.sessionLastTime(ExerciseWorkoutsScreen.describeSets(last, weights))),
          ),
        ),
      ],
    );
  }
}

/// "Superset · 1/2" (or "Circuit" for 3+) above the exercise name.
class _SupersetBanner extends StatelessWidget {
  const _SupersetBanner({required this.position, required this.size});

  final int position;
  final int size;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Chip(
            key: const Key('session.superset'),
            avatar: Icon(Icons.link, size: 18, color: colors.onTertiaryContainer),
            backgroundColor: colors.tertiaryContainer,
            side: BorderSide.none,
            label: Text(
              '${size == 2 ? t.superset : t.circuit} · $position/$size',
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(t.supersetNoRest, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Suggested ramp-up before the first working set; folded by default.
class _WarmUpCard extends StatelessWidget {
  const _WarmUpCard({required this.exercise, required this.weights});

  final SessionExercise exercise;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final sets = warmUpSets(exercise.workingKg, weights);
    if (sets.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    return Card(
      key: const Key('session.warmUp'),
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.local_fire_department_outlined),
        title: Text(t.warmUp),
        subtitle: Text(t.warmUpHint(weights.withUnit(exercise.workingKg))),
        shape: const Border(),
        children: [
          for (final s in sets)
            ListTile(
              dense: true,
              title: Text('${s.reps} × ${weights.withUnit(s.weightKg)}'),
            ),
        ],
      ),
    );
  }
}

/// "1   [− 10 +] reps   [− 100 +] kg   ✓" — or time (+ kg) for timed exercises,
/// distance + time for cardio.
class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.number,
    required this.set,
    required this.weights,
    required this.readOnly,
    required this.onChanged,
    required this.onToggle,
    required this.onRemove,
    this.tracking = Tracking.weight,
    this.onWeightTap,
  });

  final int number;
  final SessionSet set;
  final WeightFormat weights;
  final bool readOnly;
  final ValueChanged<SessionSet> onChanged;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;
  final Tracking tracking;

  /// Tap on the weight (kg) — the plate calculator.
  final ValueChanged<double>? onWeightTap;

  static const _timeStep = 15, _cardioTimeStep = 60, _distanceStep = 500.0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final editable = !readOnly;
    final display = weights.fromKg(set.weightKg);
    final seconds = set.durationSeconds ?? 0;
    final meters = set.distanceMeters ?? 0;

    Widget weightStepper() => _Stepper(
          key: const Key('weight'),
          text: weights.number(set.weightKg),
          unit: weights.label,
          onTextTap: onWeightTap == null || set.weightKg <= 0 ? null : () => onWeightTap!(set.weightKg),
          onMinus: editable && display > 0
              ? () => onChanged(set.copyWith(weightKg: weights.toKg((display - weights.step).clamp(0, weights.maxSetWeight))))
              : null,
          onPlus: editable && display < weights.maxSetWeight
              ? () => onChanged(set.copyWith(weightKg: weights.toKg(display + weights.step)))
              : null,
        );

    Widget timeStepper(int step) => _Stepper(
          key: const Key('time'),
          text: formatDuration(seconds),
          unit: t.metricTotalTime.toLowerCase(),
          onMinus: editable && seconds > step ? () => onChanged(set.copyWith(durationSeconds: seconds - step)) : null,
          onPlus: editable ? () => onChanged(set.copyWith(durationSeconds: seconds + step)) : null,
        );

    final fields = switch (tracking) {
      Tracking.weight => [
          _Stepper(
            key: const Key('reps'),
            text: '${set.reps}',
            unit: t.repsShort,
            onMinus: editable && set.reps > 1 ? () => onChanged(set.copyWith(reps: set.reps - 1)) : null,
            onPlus: editable && set.reps < 1000 ? () => onChanged(set.copyWith(reps: set.reps + 1)) : null,
          ),
          weightStepper(),
        ],
      Tracking.time => [timeStepper(_timeStep), weightStepper()],
      Tracking.distance => [
          _Stepper(
            key: const Key('distance'),
            text: formatDistance(meters).replaceAll(' km', '').replaceAll(' m', ''),
            unit: meters < 1000 ? 'm' : 'km',
            onMinus: editable && meters > _distanceStep
                ? () => onChanged(set.copyWith(distanceMeters: meters - _distanceStep))
                : null,
            onPlus: editable ? () => onChanged(set.copyWith(distanceMeters: meters + _distanceStep)) : null,
          ),
          timeStepper(_cardioTimeStep),
        ],
    };

    return Card(
      color: set.done ? colors.primaryContainer.withValues(alpha: 0.6) : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onLongPress: editable ? onRemove : null,
              child: CircleAvatar(radius: 14, child: Text('$number', style: Theme.of(context).textTheme.labelMedium)),
            ),
            for (final f in fields) Expanded(child: f),
            IconButton.filled(
              key: const Key('done'),
              tooltip: set.done ? t.sessionUndoSet : t.sessionDoneSet,
              isSelected: set.done,
              onPressed: editable ? onToggle : null,
              icon: const Icon(Icons.check),
              style: set.done ? null : IconButton.styleFrom(backgroundColor: colors.surfaceContainerHighest, foregroundColor: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({super.key, required this.text, required this.unit, required this.onMinus, required this.onPlus, this.onTextTap});

  /// Tap on the number (weight → plate calculator); shown underlined when set.
  final VoidCallback? onTextTap;

  final String text;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  void _tap(VoidCallback f) {
    HapticFeedback.selectionClick();
    f();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('minus'),
          visualDensity: VisualDensity.compact,
          onPressed: onMinus == null ? null : () => _tap(onMinus!),
          icon: const Icon(Icons.remove),
        ),
        Flexible(
          child: InkWell(
            onTap: onTextTap,
            borderRadius: BorderRadius.circular(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      decoration: onTextTap == null ? null : TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ),
                Text(unit, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
        IconButton(
          key: const Key('plus'),
          visualDensity: VisualDensity.compact,
          onPressed: onPlus == null ? null : () => _tap(onPlus!),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _SummaryDialog extends ConsumerWidget {
  const _SummaryDialog({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final weights = ref.watch(weightFormatProvider);
    final minutes = summary.duration.inMinutes;
    return AlertDialog(
      key: const Key('session.summary'),
      icon: const Icon(Icons.emoji_events_outlined, size: 40),
      title: Text(t.sessionSummaryTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.planName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(t.sessionSummaryStats(minutes, summary.exercises, summary.sets)),
          if (summary.volumeKg > 0) Text(t.sessionSummaryVolume(weights.withUnit(summary.volumeKg))),
          if (summary.records.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('🏆 ${t.sessionSummaryRecords(summary.records.join(', '))}'),
          ],
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(t.done))],
    );
  }
}
