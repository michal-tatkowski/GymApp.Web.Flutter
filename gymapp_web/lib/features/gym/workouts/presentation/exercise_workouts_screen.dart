import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/units/measures.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/widgets/scroll_aware_fab.dart';
import '../../../../l10n/app_localizations.dart';
import '../../exercises/data/models/exercise.dart';
import '../../exercises/presentation/exercise_note.dart';
import '../../exercises/presentation/category_ui.dart';
import '../../exercises/presentation/exercises_providers.dart';
import '../../exercises/presentation/favorite_button.dart';
import '../../exercises/presentation/illustration/motion.dart';
import '../../exercises/presentation/illustration/motions.dart';
import '../data/workout_models.dart';
import '../../sharing/sharing.dart';
import 'widgets/progress_chart.dart';
import 'pending_workouts.dart';
import 'rest_timer.dart';
import 'widgets/workout_entry_sheet.dart';
import 'workout_providers.dart';

/// The one screen of an exercise: progress chart, "Repeat last", history and
/// "Log workout" first (that is what the user comes for at the gym), the
/// description folded underneath. Opened from the catalog or Today it also gets
/// the [exercise] itself (star, category, description); from the Progress tab
/// only the id and name are known, so it shows just the training log.
class ExerciseWorkoutsScreen extends ConsumerStatefulWidget {
  const ExerciseWorkoutsScreen({super.key, required this.exerciseId, required this.exerciseName, this.exercise});

  ExerciseWorkoutsScreen.forExercise(Exercise this.exercise, {super.key})
    : exerciseId = exercise.id,
      exerciseName = exercise.name;

  final String exerciseId;
  final String exerciseName;
  final Exercise? exercise;

  static Future<void> openEntrySheet(
    BuildContext context,
    WidgetRef ref,
    String exerciseId, {
    WorkoutEntry? entry,
    List<WorkoutSet>? prefill,
    Tracking tracking = Tracking.weight,
  }) {
    final t = AppLocalizations.of(context)!;
    final actions = WorkoutActions.of(context);
    final timer = ref.read(restTimerProvider.notifier);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => WorkoutEntrySheet(
        weights: ref.read(weightFormatProvider),
        initial: entry,
        prefillSets: prefill,
        tracking: tracking,
        onSave: (req) async {
          if (entry != null) {
            await actions.edit(exerciseId, entry.id, req);
            return null;
          }
          final (created, record) = await actions.addAndCheckRecord(exerciseId, req);
          timer.startAfterSet();
          return created.pending ? t.savedOffline : recordMessage(t, record);
        },
      ),
    );
  }

  /// One tap: saves [sets] for today, starts the rest timer, offers "Undo".
  static Future<void> repeatLast(BuildContext context, WidgetRef ref, String exerciseId, List<WorkoutSet> sets) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = WorkoutActions.of(context);
    final timer = ref.read(restTimerProvider.notifier);
    try {
      final (created, record) = await actions.addAndCheckRecord(
        exerciseId,
        WorkoutEntryRequest(date: DateUtils.dateOnly(DateTime.now()), sets: sets),
      );
      timer.startAfterSet();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(created.pending ? t.savedOffline : recordMessage(t, record) ?? t.workoutSaved),
            // With an action Flutter keeps the snackbar until tapped (persist defaults to true);
            // "Undo" is optional, so let it go away and uncover the rest timer.
            persist: false,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: t.undo, onPressed: () => actions.delete(exerciseId, created.id)),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  /// "3 × 10 × 100 kg" when all sets are equal, otherwise "10×100, 10×100, 8×105 kg" (in [w]'s unit).
  static String describeSets(List<WorkoutSet> sets, [WeightFormat w = WeightFormat.kg]) {
    if (sets.any((s) => s.durationSeconds != null || s.distanceMeters != null)) return describeTimedSets(sets, w);
    String one(WorkoutSet s) => s.weight == 0 ? '${s.reps}' : '${s.reps}×${w.number(s.weight)}';
    // "· RIR 2/1/0" when logged (– for sets without it).
    final rir = sets.any((s) => s.rir != null) ? ' · RIR ${sets.map((s) => s.rir?.toString() ?? '–').join('/')}' : '';
    final first = sets.first;
    if (sets.length > 1 && sets.every((s) => s.reps == first.reps && s.weight == first.weight)) {
      return (first.weight == 0
              ? '${sets.length} × ${first.reps}'
              : '${sets.length} × ${first.reps} × ${w.withUnit(first.weight)}') +
          rir;
    }
    final text = sets.map(one).join(', ');
    return (sets.any((s) => s.weight > 0) ? '$text ${w.label}' : text) + rir;
  }

  @override
  ConsumerState<ExerciseWorkoutsScreen> createState() => _ExerciseWorkoutsScreenState();
}

class _ExerciseWorkoutsScreenState extends ConsumerState<ExerciseWorkoutsScreen> {
  final _fabExtended = ValueNotifier(true);

  String get exerciseId => widget.exerciseId;

  /// Animated illustration: the system exercise's own, the category's for custom ones.
  Motion? get _motion => widget.exercise != null
      ? motionFor(exerciseId, widget.exercise!.category)
      : motionForId(exerciseId);

  @override
  void dispose() {
    _fabExtended.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // Pulling down is also "try to send what was saved offline".
    await ref.read(pendingWorkoutsProvider.notifier).sync();
    ref.invalidate(workoutLogProvider(exerciseId));
    ref.invalidate(workoutProgressProvider(exerciseId));
    await ref.read(workoutLogProvider(exerciseId).future);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final exercise = widget.exercise;
    final logAsync = ref.watch(workoutLogProvider(exerciseId));
    final progressAsync = ref.watch(workoutProgressProvider(exerciseId));
    // No connection: the log cannot load, but logging must still work (saved on the phone).
    final offline = logAsync.hasError && isOfflineFailure(logAsync.error!);
    final queued = [
      for (final p in ref.watch(pendingWorkoutsProvider).reversed)
        if (p.exerciseId == exerciseId) WorkoutEntry.pending(p.request),
    ];
    final entries = [...queued, ...?logAsync.value?.entries];
    final lastSets = entries.firstOrNull?.sets;
    // The catalog exercise (when opened from it) knows its type; otherwise the log (from Progress) does.
    final tracking = exercise?.tracking ?? logAsync.value?.tracking ?? Tracking.weight;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          if (exercise != null && exercise.isCustom)
            IconButton(
              key: const Key('exercise.share'),
              tooltip: AppLocalizations.of(context)!.share,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareItem(context, ref, name: exercise.name, exerciseId: exercise.id),
            ),
          if (exercise != null) _FavoriteAction(exercise: exercise),
        ],
      ),
      floatingActionButton: ScrollAwareFab(
        key: const Key('workout.log'),
        extended: _fabExtended,
        onPressed: logAsync.hasValue || offline
            ? () => ExerciseWorkoutsScreen.openEntrySheet(context, ref, exerciseId, prefill: lastSets, tracking: tracking)
            : null,
        icon: const Icon(Icons.add),
        label: t.logWorkout,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: switch (logAsync) {
            AsyncValue(isLoading: true, hasValue: false, hasError: false) =>
              const Center(child: CircularProgressIndicator()),
            AsyncValue(:final error?) when !offline => ErrorView(
                message: describeError(t, error),
                onRetry: () => ref.invalidate(workoutLogProvider(exerciseId)),
              ),
            _ => RefreshIndicator(
              onRefresh: _refresh,
              child: ScrollAwareFab.listener(
                extended: _fabExtended,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (offline) const _OfflineNotice(),
                    if (_motion case final motion?)
                      Center(child: MotionView(key: const Key('exercise.motion'), motion: motion, size: 150)),
                    if (exercise != null) ...[_ExerciseHeader(exercise: exercise), const SizedBox(height: 8)],
                    if (!offline) ...[ExerciseNoteTile(exerciseId: exerciseId), const SizedBox(height: 8)],
                    if (!offline) Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.progress, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            progressAsync.when(
                              loading: () =>
                                  const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                              error: (e, _) => SizedBox(height: 80, child: Center(child: Text(describeError(t, e)))),
                              data: (points) => ProgressChart(points: points, weights: ref.watch(weightFormatProvider), tracking: tracking),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (lastSets != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('workout.repeat'),
                        onPressed: () => ExerciseWorkoutsScreen.repeatLast(context, ref, exerciseId, lastSets),
                        icon: const Icon(Icons.replay),
                        label: Text(t.repeatLast(ExerciseWorkoutsScreen.describeSets(lastSets, ref.watch(weightFormatProvider)))),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(t.workoutHistory, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text(t.noEntriesForExercise)),
                      ),
                    for (final entry in entries) _EntryTile(exerciseId: exerciseId, entry: entry, tracking: tracking),
                    if (exercise != null) ...[
                      const SizedBox(height: 8),
                      // Folded once the user has trained it: by then they know the movement.
                      _AboutExercise(exercise: exercise, initiallyExpanded: entries.isEmpty),
                    ],
                  ],
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// Shown instead of the chart when the log cannot be loaded for lack of connection.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('workout.offline'),
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.cloud_off, color: colors.onSecondaryContainer),
        title: Text(t.offlineTitle),
        subtitle: Text(t.offlineLogHint),
      ),
    );
  }
}

/// Category (and "Custom") under the app bar.
class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      children: [
        Chip(
          avatar: Icon(categoryIcon(exercise.category), size: 16),
          label: Text(categoryLabel(context, exercise.category)),
          visualDensity: VisualDensity.compact,
        ),
        if (exercise.isCustom)
          Chip(
            avatar: const Icon(Icons.person_outline, size: 16),
            label: Text(t.customExercise),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _AboutExercise extends StatelessWidget {
  const _AboutExercise({required this.exercise, required this.initiallyExpanded});

  final Exercise exercise;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = exercise.description?.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('exercise.about'),
        initiallyExpanded: initiallyExpanded,
        leading: const Icon(Icons.info_outline),
        title: Text(t.aboutExercise),
        shape: const Border(),
        collapsedShape: const Border(),
        expandedAlignment: Alignment.centerLeft,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(text?.isNotEmpty == true ? text! : t.noDescription)],
      ),
    );
  }
}

/// Star in the app bar. Goes through the catalog list when it is open (so the
/// row there flips too), otherwise straight to the API; Today's favorites are
/// refreshed either way. Flips immediately and flips back if the call fails.
class _FavoriteAction extends ConsumerStatefulWidget {
  const _FavoriteAction({required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<_FavoriteAction> createState() => _FavoriteActionState();
}

class _FavoriteActionState extends ConsumerState<_FavoriteAction> {
  late bool _favorite = widget.exercise.isFavorite;

  Future<void> _toggle() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final id = widget.exercise.id;
    final target = !_favorite;
    setState(() => _favorite = target);
    try {
      final inList = ref.exists(exercisesProvider) && ref.read(exercisesProvider).items.any((e) => e.id == id);
      if (inList) {
        await ref.read(exercisesProvider.notifier).toggleFavorite(id);
      } else {
        await ref.read(exerciseRepositoryProvider).setFavorite(id, target);
        ref.invalidate(favoriteExercisesProvider);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorite = !target);
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) => FavoriteButton(isFavorite: _favorite, onPressed: _toggle);
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.exerciseId, required this.entry, required this.tracking});

  final String exerciseId;
  final WorkoutEntry entry;
  final Tracking tracking;


  /// Deletes right away and offers "Undo" (re-creates the entry) — no confirmation
  /// dialog: the action is reversible, so it should not interrupt.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final actions = WorkoutActions.of(context);
    try {
      await actions.delete(exerciseId, entry.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.entryDeleted),
            // With an action Flutter keeps the snackbar until tapped (persist defaults to true);
            // "Undo" is optional, so let it go away and uncover the rest timer.
            persist: false,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: t.undo,
              onPressed: () =>
                  actions.add(exerciseId, WorkoutEntryRequest(date: entry.date, sets: entry.sets, notes: entry.notes)),
            ),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final bodyweight = entry.volume == 0;
    final weights = ref.watch(weightFormatProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: entry.pending ? Key('workout.pending.${entry.id}') : null,
        leading: entry.pending
            ? Tooltip(message: t.waitingToSync, child: const Icon(Icons.cloud_upload_outlined))
            : null,
        title: Text(DateFormat.yMMMEd(locale).format(entry.date)),
        subtitle: Text([
          ExerciseWorkoutsScreen.describeSets(entry.sets, weights),
          if (entry.notes != null) entry.notes!,
          if (entry.pending) t.waitingToSync,
        ].join('\n')),
        isThreeLine: entry.notes != null || entry.pending,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              switch (tracking) {
                Tracking.time => formatDuration(totalDuration(entry.sets)),
                Tracking.distance => formatDistance(totalDistance(entry.sets), decimalSeparator: locale.startsWith('pl') ? ',' : '.'),
                Tracking.weight => bodyweight ? t.repsValue(entry.totalReps) : weights.withUnit(entry.volume),
              },
              style: Theme.of(context).textTheme.labelLarge,
            ),
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
        // Editing needs the server; a queued workout can only be deleted until it is sent.
        onTap: entry.pending ? null : () => ExerciseWorkoutsScreen.openEntrySheet(context, ref, exerciseId, entry: entry, tracking: tracking),
      ),
    );
  }
}

/// "New record!" texts for the snackbar after saving; null = no record.
String? recordMessage(AppLocalizations t, NewRecord? record) => switch (record) {
  NewRecord.oneRepMax => t.newRecordOneRepMax,
  NewRecord.volume => t.newRecordVolume,
  null => null,
};

/// "3 × 1:00", "1:00 × 20 kg, 0:45" (time) or "5 km · 25:00, 3 km · 15:30" (distance).
String describeTimedSets(List<WorkoutSet> sets, [WeightFormat w = WeightFormat.kg]) {
  String one(WorkoutSet s) {
    final time = s.durationSeconds == null ? null : formatDuration(s.durationSeconds!);
    if (s.distanceMeters != null) return [formatDistance(s.distanceMeters!), ?time].join(' · ');
    return s.weight > 0 ? '${time ?? s.reps} × ${w.withUnit(s.weight)}' : time ?? '${s.reps}';
  }

  if (sets.length > 1 && sets.every((s) => s == sets.first)) return '${sets.length} × ${one(sets.first)}';
  return sets.map(one).join(', ');
}

/// One set for a notification line: "8 × 100 kg", "1:30", "5 km · 25:00".
String describeTimedOrPlain(WorkoutSet s, WeightFormat w) =>
    s.durationSeconds != null || s.distanceMeters != null
        ? describeTimedSets([s], w)
        : s.weight > 0
            ? '${s.reps} × ${w.withUnit(s.weight)}'
            : '${s.reps}';
