import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

// ─── This period vs. the previous one ──────────────────────────────────────

typedef PeriodTotals = ({int days, int sets, double volume});

PeriodTotals _totals(List<TrainingDay> days, DateTime from, DateTime until) {
  var count = 0, sets = 0, volume = 0.0;
  for (final d in days) {
    final date = DateUtils.dateOnly(d.date);
    if (date.isBefore(from) || !date.isBefore(until)) continue;
    count++;
    sets += d.sets;
    volume += d.volume;
  }
  return (days: count, sets: sets, volume: volume);
}

/// This week / month so far against the same number of days of the previous one
/// (a fair race: 12 days of November vs. the first 12 of October). [firstDayOfWeek]:
/// 0 = Sunday … 6 = Saturday.
({PeriodTotals current, PeriodTotals previous}) comparePeriods(
  List<TrainingDay> days,
  DateTime today, {
  required bool month,
  int firstDayOfWeek = 1,
}) {
  final day = DateUtils.dateOnly(today);
  final tomorrow = DateUtils.addDaysToDate(day, 1);
  if (month) {
    final start = DateTime(day.year, day.month);
    final prevStart = DateTime(day.year, day.month - 1);
    final prevLength = DateUtils.getDaysInMonth(prevStart.year, prevStart.month);
    final prevUntil = DateUtils.addDaysToDate(prevStart, math.min(day.day, prevLength));
    return (current: _totals(days, start, tomorrow), previous: _totals(days, prevStart, prevUntil));
  }
  final start = DateUtils.addDaysToDate(day, -((day.weekday % 7 - firstDayOfWeek + 7) % 7));
  final elapsed = day.difference(start).inDays + 1;
  final prevStart = DateUtils.addDaysToDate(start, -7);
  return (current: _totals(days, start, tomorrow), previous: _totals(days, prevStart, DateUtils.addDaysToDate(prevStart, elapsed)));
}

class PeriodCompareCard extends ConsumerStatefulWidget {
  const PeriodCompareCard({super.key});

  @override
  ConsumerState<PeriodCompareCard> createState() => _PeriodCompareCardState();
}

class _PeriodCompareCardState extends ConsumerState<PeriodCompareCard> {
  bool _month = false;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(yearStatsProvider).value;
    if (stats == null || stats.days.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weights = ref.watch(weightFormatProvider);
    final count = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final r = comparePeriods(stats.days, DateTime.now(),
        month: _month, firstDayOfWeek: MaterialLocalizations.of(context).firstDayOfWeekIndex);

    Widget row(String label, num now, num before, String Function(num) format) {
      final Widget delta;
      if (before == 0) {
        delta = now == 0 ? const SizedBox.shrink() : Text(t.compareNew, style: TextStyle(color: context.appColors.success));
      } else {
        final change = ((now - before) / before * 100).round();
        final color = change > 0 ? context.appColors.success : (change < 0 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant);
        delta = Text(
          '${change > 0 ? '▲' : (change < 0 ? '▼' : '')} ${change.abs()}%',
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        );
      }
      // Label over "now / before" — fits a phone even with large text.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: format(now), style: theme.textTheme.titleMedium),
                    TextSpan(text: '  / ${format(before)}', style: theme.textTheme.bodySmall),
                  ])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            delta,
          ],
        ),
      );
    }

    return Card(
      key: const Key('progress.compare'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.compareTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              key: const Key('compare.period'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(t.compareWeek)),
                ButtonSegment(value: true, label: Text(t.compareMonth)),
              ],
              selected: {_month},
              onSelectionChanged: (v) => setState(() => _month = v.single),
            ),
            const SizedBox(height: 4),
            Text(_month ? t.compareHintMonth : t.compareHintWeek, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            row(t.lifetimeDays, r.current.days, r.previous.days, count.format),
            row(t.lifetimeSets, r.current.sets, r.previous.sets, count.format),
            if (r.current.volume > 0 || r.previous.volume > 0)
              row(t.lifetimeVolume, r.current.volume, r.previous.volume,
                  (v) => '${count.format(weights.fromKg(v.toDouble()).round())} ${weights.label}'),
          ],
        ),
      ),
    );
  }
}

// ─── Monthly challenges ────────────────────────────────────────────────────

enum ChallengeKind { workouts, sets, volume }

class Challenge {
  const Challenge(this.kind, this.target);

  final ChallengeKind kind;

  /// Training days, sets, or kg.
  final double target;

  Map<String, dynamic> toJson() => {'kind': kind.name, 'target': target};

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      Challenge(ChallengeKind.values.byName(json['kind'] as String), (json['target'] as num).toDouble());
}

String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

const _prefix = 'challenges.';

/// Three challenges for [month], a notch (+10 %) above the average of the three months
/// before it — training days, sets, and kilos (when weights are logged). With little
/// history: two workouts a week and 40 sets.
List<Challenge> proposeChallenges(List<TrainingDay> days, DateTime month) {
  final start = DateTime(month.year, month.month);
  final from = DateTime(month.year, month.month - 3);
  final past = _totals(days, from, start);
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  double roundTo(double v, double step) => (v / step).round() * step;
  final workouts = math.min(daysInMonth, math.max(8, (past.days / 3 * 1.1).ceil())).toDouble();
  final sets = math.max(40.0, roundTo(past.sets / 3 * 1.1, 10));
  final volume = past.volume <= 0 ? 0.0 : math.max(1000.0, roundTo(past.volume / 3 * 1.1, 1000));
  return [
    Challenge(ChallengeKind.workouts, workouts),
    Challenge(ChallengeKind.sets, sets),
    if (volume > 0) Challenge(ChallengeKind.volume, volume),
  ];
}

double challengeValue(Challenge c, PeriodTotals totals) => switch (c.kind) {
      ChallengeKind.workouts => totals.days.toDouble(),
      ChallengeKind.sets => totals.sets.toDouble(),
      ChallengeKind.volume => totals.volume,
    };

class MonthChallenges {
  const MonthChallenges({required this.month, required this.challenges, required this.totals, required this.completedBefore});

  final DateTime month;
  final List<Challenge> challenges;
  final PeriodTotals totals;

  /// Challenges completed in earlier months (on this phone).
  final int completedBefore;
}

/// This month's challenges. Fixed for the month once proposed (stored on the phone, so
/// the bar does not move while you chase it); past months count towards "completed".
/// Cleared on logout.
final challengesProvider = FutureProvider.autoDispose<MonthChallenges?>((ref) async {
  final stats = await ref.watch(yearStatsProvider.future);
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final prefs = await SharedPreferences.getInstance();
  final key = '$_prefix${_monthKey(month)}';

  List<Challenge> read(String k) =>
      [for (final c in jsonDecode(prefs.getString(k)!) as List) Challenge.fromJson(c as Map<String, dynamic>)];

  List<Challenge> challenges;
  try {
    challenges = prefs.containsKey(key) ? read(key) : const [];
  } catch (_) {
    challenges = const [];
  }
  if (challenges.isEmpty) {
    challenges = proposeChallenges(stats.days, month);
    await prefs.setString(key, jsonEncode([for (final c in challenges) c.toJson()]));
  }

  var completed = 0;
  for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix) && k != key)) {
    final parts = k.substring(_prefix.length).split('-');
    final m = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    if (!m.isBefore(month)) continue;
    final totals = _totals(stats.days, m, DateTime(m.year, m.month + 1));
    try {
      completed += read(k).where((c) => challengeValue(c, totals) >= c.target).length;
    } catch (_) {}
  }
  return MonthChallenges(
    month: month,
    challenges: challenges,
    totals: _totals(stats.days, month, DateTime(month.year, month.month + 1)),
    completedBefore: completed,
  );
});

/// Logout: the next account gets its own challenges.
Future<void> clearChallenges() async {
  final prefs = await SharedPreferences.getInstance();
  for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
    await prefs.remove(k);
  }
}

class ChallengesCard extends ConsumerWidget {
  const ChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(challengesProvider).value;
    if (data == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weights = ref.watch(weightFormatProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    final left = DateUtils.getDaysInMonth(today.year, today.month) - today.day + 1;
    final done = data.challenges.where((c) => challengeValue(c, data.totals) >= c.target).length;

    String title(Challenge c) => switch (c.kind) {
          ChallengeKind.workouts => t.badgeGoalWorkouts(c.target.toInt()),
          ChallengeKind.sets => t.challengeSets(c.target.toInt()),
          ChallengeKind.volume => t.badgeGoalVolume(weights.withUnit(c.target)),
        };
    String value(Challenge c) => switch (c.kind) {
          ChallengeKind.volume => '${NumberFormat.decimalPattern(locale).format(weights.fromKg(data.totals.volume).round())} / '
              '${NumberFormat.decimalPattern(locale).format(weights.fromKg(c.target).round())} ${weights.label}',
          _ => '${challengeValue(c, data.totals).toInt()} / ${c.target.toInt()}',
        };

    return Card(
      key: const Key('today.challenges'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.challengesTitle(DateFormat.LLLL(locale).format(data.month)), style: theme.textTheme.titleMedium),
                ),
                Text(t.challengeDaysLeft(left), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final c in data.challenges)
              Padding(
                key: Key('challenge.${c.kind.name}'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title(c))),
                        if (challengeValue(c, data.totals) >= c.target)
                          Text(t.challengeDone, style: theme.textTheme.labelLarge?.copyWith(color: context.appColors.success))
                        else
                          Text(value(c), style: theme.textTheme.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (challengeValue(c, data.totals) / c.target).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      color: challengeValue(c, data.totals) >= c.target ? context.appColors.success : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(t.challengesCompleted(data.completedBefore + done), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
