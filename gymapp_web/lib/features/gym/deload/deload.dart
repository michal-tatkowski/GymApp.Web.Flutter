import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/retry.dart';
import '../../../core/storage/secure_storage_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

/// Share of the working weight in a deload week, and the plan's sets minus one.
const kDeloadShare = 0.85;
const kDeloadDays = 7;

// ─── When to suggest it ────────────────────────────────────────────────────

enum DeloadReason { hardSets, stalled, streak }

class DeloadAdvice {
  const DeloadAdvice(this.reason, {this.count = 0});

  final DeloadReason reason;

  /// Stalled exercises, or weeks in a row — depending on [reason].
  final int count;
}

/// Epley: estimated one-rep max of a set.
double _e1rm(WorkoutSet s) => s.weight <= 0 ? 0 : s.weight * (1 + s.reps / 30);

/// Suggests a lighter week when the last weeks look like accumulated fatigue:
/// - hard sets: in the last 14 days at least 4 exercises had their last set rated, and 60 %+ of
///   those were to failure (RIR 0),
/// - stalled: in 2+ exercises trained 3+ times in the last 28 days, the latest day's best set is
///   5 % under the best before it,
/// - streak: 8+ weeks in a row with a workout ([weekStarts]: the week starts with a workout, any
///   order) and no deload in the last 8 weeks.
/// Null when everything looks fine.
DeloadAdvice? deloadAdvice(
  List<TrainingDayDetails> days,
  Iterable<DateTime> weekStarts,
  DateTime today, {
  DateTime? lastDeload,
}) {
  final day = DateUtils.dateOnly(today);
  final recent = days.where((d) => !d.date.isBefore(DateUtils.addDaysToDate(day, -14)));

  var rated = 0, failure = 0;
  for (final d in recent) {
    for (final e in d.exercises) {
      final last = e.sets.where((s) => s.rir != null).lastOrNull;
      if (last == null) continue;
      rated++;
      if (last.rir == 0) failure++;
    }
  }
  if (rated >= 4 && failure / rated >= 0.6) return const DeloadAdvice(DeloadReason.hardSets);

  final byExercise = <String, List<(DateTime, double)>>{};
  for (final d in days.where((d) => !d.date.isBefore(DateUtils.addDaysToDate(day, -28)))) {
    for (final e in d.exercises) {
      final best = e.sets.fold(0.0, (m, s) => _e1rm(s) > m ? _e1rm(s) : m);
      if (best > 0) (byExercise[e.exerciseId] ??= []).add((d.date, best));
    }
  }
  var stalled = 0;
  for (final list in byExercise.values) {
    if (list.length < 3) continue;
    list.sort((a, b) => a.$1.compareTo(b.$1));
    final before = list.take(list.length - 1).fold(0.0, (m, p) => p.$2 > m ? p.$2 : m);
    if (list.last.$2 < before * 0.95) stalled++;
  }
  if (stalled >= 2) return DeloadAdvice(DeloadReason.stalled, count: stalled);

  final weeks = {for (final w in weekStarts) DateUtils.dateOnly(w)};
  var run = 0;
  var w = DateUtils.addDaysToDate(day, -((day.weekday - DateTime.monday) % 7));
  // This week may not have a workout yet: start counting from last week then.
  if (!weeks.contains(w)) w = DateUtils.addDaysToDate(w, -7);
  while (weeks.contains(w)) {
    run++;
    w = DateUtils.addDaysToDate(w, -7);
  }
  final recentDeload = lastDeload != null && day.difference(lastDeload).inDays < 56;
  if (run >= 8 && !recentDeload) return DeloadAdvice(DeloadReason.streak, count: run);
  return null;
}

/// Monday of each week with a workout.
Iterable<DateTime> weeksWithWorkouts(Iterable<DateTime> dates) =>
    {for (final d in dates) DateUtils.addDaysToDate(DateUtils.dateOnly(d), -((d.weekday - DateTime.monday) % 7))};

// ─── State: active / snoozed / last one ────────────────────────────────────

class DeloadState {
  const DeloadState({this.activeUntil, this.snoozedUntil, this.lastAt});

  /// Last day of the lighter week (inclusive).
  final DateTime? activeUntil;
  final DateTime? snoozedUntil;
  final DateTime? lastAt;

  bool activeOn(DateTime day) => activeUntil != null && !DateUtils.dateOnly(day).isAfter(activeUntil!);
  bool snoozedOn(DateTime day) => snoozedUntil != null && !DateUtils.dateOnly(day).isAfter(snoozedUntil!);

  Map<String, dynamic> toJson() => {
        if (activeUntil != null) 'activeUntil': toApiDate(activeUntil!),
        if (snoozedUntil != null) 'snoozedUntil': toApiDate(snoozedUntil!),
        if (lastAt != null) 'lastAt': toApiDate(lastAt!),
      };

  factory DeloadState.fromJson(Map<String, dynamic> j) => DeloadState(
        activeUntil: j['activeUntil'] == null ? null : fromApiDate(j['activeUntil'] as String),
        snoozedUntil: j['snoozedUntil'] == null ? null : fromApiDate(j['snoozedUntil'] as String),
        lastAt: j['lastAt'] == null ? null : fromApiDate(j['lastAt'] as String),
      );
}

/// On this phone, per account (cleared on logout).
final deloadProvider = NotifierProvider<DeloadNotifier, DeloadState>(DeloadNotifier.new);

class DeloadNotifier extends Notifier<DeloadState> {
  bool _changed = false;

  @override
  DeloadState build() {
    _restore();
    return const DeloadState();
  }

  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(StorageKeys.deload);
    if (raw == null || !ref.mounted || _changed) return;
    try {
      state = DeloadState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _save(DeloadState next) async {
    _changed = true;
    state = next;
    await (await SharedPreferences.getInstance()).setString(StorageKeys.deload, jsonEncode(next.toJson()));
  }

  /// A lighter week from today.
  Future<void> start([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return _save(DeloadState(activeUntil: DateUtils.addDaysToDate(today, kDeloadDays - 1), lastAt: today));
  }

  Future<void> end() => _save(DeloadState(lastAt: state.lastAt));

  /// "Not now": asked again in a week.
  Future<void> snooze([DateTime? now]) => _save(DeloadState(
        snoozedUntil: DateUtils.addDaysToDate(DateUtils.dateOnly(now ?? DateTime.now()), kDeloadDays),
        lastAt: state.lastAt,
      ));

  Future<void> clear() async {
    _changed = true;
    state = const DeloadState();
    await (await SharedPreferences.getInstance()).remove(StorageKeys.deload);
  }
}

/// Days of the last 4 weeks and the weeks with a workout (12 weeks of stats) → the advice.
final deloadAdviceProvider = FutureProvider.autoDispose<DeloadAdvice?>(
  (ref) async {
    final state = ref.watch(deloadProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    if (state.activeOn(today) || state.snoozedOn(today)) return null;
    final repo = ref.watch(workoutRepositoryProvider);
    final days = await repo.getDays(from: DateUtils.addDaysToDate(today, -28), to: today);
    final stats = await ref.watch(workoutStatsProvider.future);
    return deloadAdvice(days, weeksWithWorkouts(stats.days.map((d) => d.date)), today, lastDeload: state.lastAt);
  },
  retry: noRetry,
);

// ─── Card on Today ─────────────────────────────────────────────────────────

class DeloadCard extends ConsumerWidget {
  const DeloadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(deloadProvider);
    final today = DateUtils.dateOnly(DateTime.now());

    if (state.activeOn(today)) {
      final until = DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(state.activeUntil!);
      return Card(
        key: const Key('deload.active'),
        margin: const EdgeInsets.only(bottom: 12),
        color: theme.colorScheme.secondaryContainer,
        child: ListTile(
          leading: Icon(Icons.battery_charging_full, color: theme.colorScheme.onSecondaryContainer),
          title: Text(t.deloadActive(until)),
          subtitle: Text(t.deloadActiveHint),
          trailing: TextButton(
            key: const Key('deload.end'),
            onPressed: () => ref.read(deloadProvider.notifier).end(),
            child: Text(t.deloadEnd),
          ),
        ),
      );
    }

    final advice = ref.watch(deloadAdviceProvider).value;
    if (advice == null) return const SizedBox.shrink();
    final reason = switch (advice.reason) {
      DeloadReason.hardSets => t.deloadReasonHard,
      DeloadReason.stalled => t.deloadReasonStall(advice.count),
      DeloadReason.streak => t.deloadReasonStreak(advice.count),
    };
    return Card(
      key: const Key('deload.advice'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.battery_charging_full, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(t.deloadTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(reason, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(t.deloadExplain, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  key: const Key('deload.later'),
                  onPressed: () => ref.read(deloadProvider.notifier).snooze(),
                  child: Text(t.deloadLater),
                ),
                FilledButton.tonal(
                  key: const Key('deload.start'),
                  onPressed: () => ref.read(deloadProvider.notifier).start(),
                  child: Text(t.deloadStart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
