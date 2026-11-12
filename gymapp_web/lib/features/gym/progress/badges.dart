import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_keys.dart';
import '../workouts/data/workout_models.dart';

enum BadgeKind { workouts, weekStreak, busyWeek, records, volume, variety }

class BadgeDef {
  const BadgeDef(this.id, this.kind, this.goal, this.icon);

  final String id;
  final BadgeKind kind;

  /// Workouts, weeks, records, kg or exercises — depending on [kind].
  final double goal;
  final IconData icon;
}

const badgeDefs = <BadgeDef>[
  BadgeDef('workouts1', BadgeKind.workouts, 1, Icons.flag_outlined),
  BadgeDef('workouts10', BadgeKind.workouts, 10, Icons.directions_run),
  BadgeDef('workouts50', BadgeKind.workouts, 50, Icons.military_tech_outlined),
  BadgeDef('workouts100', BadgeKind.workouts, 100, Icons.workspace_premium_outlined),
  BadgeDef('streak4', BadgeKind.weekStreak, 4, Icons.local_fire_department_outlined),
  BadgeDef('streak12', BadgeKind.weekStreak, 12, Icons.whatshot),
  BadgeDef('busyWeek3', BadgeKind.busyWeek, 3, Icons.event_available),
  BadgeDef('record1', BadgeKind.records, 1, Icons.emoji_events_outlined),
  BadgeDef('record10', BadgeKind.records, 10, Icons.emoji_events),
  BadgeDef('volume10t', BadgeKind.volume, 10000, Icons.fitness_center),
  BadgeDef('volume100t', BadgeKind.volume, 100000, Icons.landscape_outlined),
  BadgeDef('variety10', BadgeKind.variety, 10, Icons.explore_outlined),
];

class BadgeProgress {
  const BadgeProgress({required this.def, required this.value, this.earnedAt});

  final BadgeDef def;

  /// Best value reached so far (capped at the goal for display).
  final double value;

  /// When it was reached; null = not yet (or reached on a day the data no longer shows).
  final DateTime? earnedAt;

  bool get earned => value >= def.goal || earnedAt != null;
}

/// Badges from the training days/records the API returns (at most ~13 months)
/// and the number of different exercises ever trained. [firstDayOfWeek]:
/// 0 = Sunday … 6 = Saturday, as in [MaterialLocalizations.firstDayOfWeekIndex].
List<BadgeProgress> computeBadges(WorkoutStats stats, int distinctExercises, int firstDayOfWeek) {
  final days = [...stats.days]..sort((a, b) => a.date.compareTo(b.date));
  final records = [...stats.records]..sort((a, b) => a.date.compareTo(b.date));
  DateTime weekOf(DateTime d) => DateUtils.addDaysToDate(DateUtils.dateOnly(d), -((d.weekday % 7 - firstDayOfWeek + 7) % 7));

  // Running totals: when each threshold was crossed.
  DateTime? nth(List<DateTime> dates, double n) => n >= 1 && dates.length >= n ? dates[n.toInt() - 1] : null;

  DateTime? volumeReached(double goal) {
    var sum = 0.0;
    for (final d in days) {
      sum += d.volume;
      if (sum >= goal) return d.date;
    }
    return null;
  }

  // Longest run of consecutive weeks with a workout, and the busiest week.
  final perWeek = <DateTime, List<DateTime>>{};
  for (final d in days) {
    (perWeek[weekOf(d.date)] ??= []).add(d.date);
  }
  final weeks = perWeek.keys.toList()..sort();
  var bestStreak = 0, run = 0;
  DateTime? previous;
  final streakReached = <int, DateTime>{};
  for (final w in weeks) {
    run = previous != null && DateUtils.addDaysToDate(previous, 7) == w ? run + 1 : 1;
    previous = w;
    if (run > bestStreak) bestStreak = run;
    streakReached.putIfAbsent(run, () => perWeek[w]!.first);
  }
  final busiest = perWeek.values.fold(0, (m, list) => list.length > m ? list.length : m);
  DateTime? busyReached(double goal) {
    for (final w in weeks) {
      if (perWeek[w]!.length >= goal) return perWeek[w]![goal.toInt() - 1];
    }
    return null;
  }

  final totalVolume = days.fold(0.0, (v, d) => v + d.volume);
  return [
    for (final def in badgeDefs)
      switch (def.kind) {
        BadgeKind.workouts =>
          BadgeProgress(def: def, value: days.length.toDouble(), earnedAt: nth([for (final d in days) d.date], def.goal)),
        BadgeKind.weekStreak =>
          BadgeProgress(def: def, value: bestStreak.toDouble(), earnedAt: streakReached[def.goal.toInt()]),
        BadgeKind.busyWeek => BadgeProgress(def: def, value: busiest.toDouble(), earnedAt: busyReached(def.goal)),
        BadgeKind.records =>
          BadgeProgress(def: def, value: records.length.toDouble(), earnedAt: nth([for (final r in records) r.date], def.goal)),
        BadgeKind.volume => BadgeProgress(def: def, value: totalVolume, earnedAt: volumeReached(def.goal)),
        BadgeKind.variety => BadgeProgress(def: def, value: distinctExercises.toDouble()),
      },
  ];
}

/// Badges earned on this device (id → date). Once earned a badge stays, even when
/// the workouts behind it fall out of the period the API returns. Cleared on logout.
final earnedBadgesProvider = NotifierProvider<EarnedBadges, Map<String, DateTime>>(EarnedBadges.new);

class EarnedBadges extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(StorageKeys.earnedBadges);
    if (raw == null || !ref.mounted) return;
    try {
      final stored = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, DateTime.parse(v as String)));
      state = {...stored, ...state};
    } catch (_) {
      // Unreadable → start over; badges are recomputed from the data anyway.
    }
  }

  /// Adds newly earned badges; returns their ids (empty when nothing new).
  List<String> remember(List<BadgeProgress> badges) {
    final now = DateUtils.dateOnly(DateTime.now());
    final fresh = {
      for (final b in badges)
        if (b.earned && !state.containsKey(b.def.id)) b.def.id: b.earnedAt ?? now,
    };
    if (fresh.isEmpty) return const [];
    state = {...state, ...fresh};
    SharedPreferences.getInstance().then((prefs) => prefs.setString(
          StorageKeys.earnedBadges,
          jsonEncode(state.map((k, v) => MapEntry(k, v.toIso8601String()))),
        ));
    return fresh.keys.toList();
  }

  Future<void> clear() async {
    state = const {};
    await (await SharedPreferences.getInstance()).remove(StorageKeys.earnedBadges);
  }
}
