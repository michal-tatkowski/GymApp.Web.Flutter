import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/units/weight_unit.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/presentation/workout_providers.dart';
import 'badges.dart';

/// 0 = rest day, 1–4 = more sets that day.
int activityLevel(int sets) => switch (sets) {
      <= 0 => 0,
      <= 5 => 1,
      <= 11 => 2,
      <= 19 => 3,
      _ => 4,
    };

/// Training map of the last year: a column per week, a square per day, darker = more
/// sets. Scrolled to today; tap a day to see what was done.
class ActivityCard extends ConsumerStatefulWidget {
  const ActivityCard({super.key});

  static const weeks = 53;

  @override
  ConsumerState<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<ActivityCard> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(yearStatsProvider).value;
    if (stats == null) return const SizedBox.shrink(); // loading or offline: the list below still works
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = DateUtils.addDaysToDate(today, -((today.weekday % 7 - firstDay + 7) % 7));
    final start = DateUtils.addDaysToDate(weekStart, -7 * (ActivityCard.weeks - 1));
    final byDay = {for (final d in stats.days) DateUtils.dateOnly(d.date): d};
    final inYear = stats.days.where((d) => !d.date.isBefore(start)).length;

    Color colorFor(int level) => level == 0
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary.withValues(alpha: const [0.0, 0.3, 0.5, 0.75, 1.0][level]);

    const cell = 12.0, gap = 3.0;
    final selected = _selected;
    final selectedDay = selected == null ? null : byDay[selected];

    return Card(
      key: const Key('progress.activity'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.activityTitle, style: theme.textTheme.titleMedium),
            Text(t.activitySummary(inYear), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // today on screen; older weeks to the left
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month names above the week where a month starts.
                  SizedBox(
                    height: 16,
                    width: ActivityCard.weeks * (cell + gap),
                    child: Stack(
                      children: [
                        for (var w = 0; w < ActivityCard.weeks; w++)
                          if (DateUtils.addDaysToDate(start, 7 * w).day <= 7)
                            Positioned(
                              left: w * (cell + gap),
                              child: Text(
                                DateFormat.MMM(locale).format(DateUtils.addDaysToDate(start, 7 * w)),
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var w = 0; w < ActivityCard.weeks; w++)
                        Column(
                            children: [
                              for (var d = 0; d < 7; d++)
                                Builder(builder: (context) {
                                  final day = DateUtils.addDaysToDate(start, 7 * w + d);
                                  if (day.isAfter(today)) return const SizedBox(width: cell + gap, height: cell + gap);
                                  final level = activityLevel(byDay[day]?.sets ?? 0);
                                  // The gap around the square is part of the tap target — 12 px alone is too small.
                                  return GestureDetector(
                                    key: Key('activity.${DateFormat('yyyy-MM-dd').format(day)}'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _selected = day == _selected ? null : day),
                                    child: Container(
                                      width: cell,
                                      height: cell,
                                      margin: const EdgeInsets.only(right: gap, bottom: gap),
                                      decoration: BoxDecoration(
                                        color: colorFor(level),
                                        borderRadius: BorderRadius.circular(3),
                                        border: day == selected || day == today
                                            ? Border.all(color: theme.colorScheme.onSurface, width: day == selected ? 1.5 : 0.8)
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? t.activityTapHint
                        : selectedDay == null
                            ? t.activityRestDay(DateFormat.MMMEd(locale).format(selected))
                            : t.activityDay(DateFormat.MMMEd(locale).format(selected), selectedDay.exercises, selectedDay.sets),
                    key: const Key('activity.detail'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // Legend: less → more.
                for (var l = 0; l <= 4; l++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(color: colorFor(l), borderRadius: BorderRadius.circular(2)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Earned badges in colour, the rest greyed with their progress. A newly earned
/// one is announced once.
class BadgesCard extends ConsumerStatefulWidget {
  const BadgesCard({super.key, required this.distinctExercises});

  final int distinctExercises;

  @override
  ConsumerState<BadgesCard> createState() => _BadgesCardState();
}

class _BadgesCardState extends ConsumerState<BadgesCard> {
  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(yearStatsProvider).value;
    if (stats == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weights = ref.watch(weightFormatProvider);
    final earned = ref.watch(earnedBadgesProvider);
    final badges = computeBadges(stats, widget.distinctExercises, MaterialLocalizations.of(context).firstDayOfWeekIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fresh = ref.read(earnedBadgesProvider.notifier).remember(badges);
      // Nothing stored yet = first look at this screen: no fanfare for old achievements.
      if (fresh.isEmpty || earned.isEmpty && fresh.length > 1) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.badgeUnlocked(badgeTitle(t, badgeDefs.firstWhere((d) => d.id == fresh.first)))),
      ));
    });

    final count = badges.where((b) => b.earned || earned.containsKey(b.def.id)).length;
    return Card(
      key: const Key('progress.badges'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.badgesTitle, style: theme.textTheme.titleMedium),
            Text(t.badgesCount(count, badges.length), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (final b in badges)
                  _BadgeTile(
                    badge: b,
                    earnedAt: earned[b.def.id] ?? b.earnedAt,
                    isEarned: b.earned || earned.containsKey(b.def.id),
                    weights: weights,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String badgeTitle(AppLocalizations t, BadgeDef def) => switch (def.id) {
      'workouts1' => t.badgeWorkouts1,
      'workouts10' => t.badgeWorkouts10,
      'workouts50' => t.badgeWorkouts50,
      'workouts100' => t.badgeWorkouts100,
      'streak4' => t.badgeStreak4,
      'streak12' => t.badgeStreak12,
      'busyWeek3' => t.badgeBusyWeek,
      'record1' => t.badgeRecord1,
      'record10' => t.badgeRecord10,
      'volume10t' => t.badgeVolume10t,
      'volume100t' => t.badgeVolume100t,
      _ => t.badgeVariety,
    };

String badgeGoal(AppLocalizations t, BadgeDef def, WeightFormat weights) {
  final n = def.goal.toInt();
  return switch (def.kind) {
    BadgeKind.workouts => t.badgeGoalWorkouts(n),
    BadgeKind.weekStreak => t.badgeGoalStreak(n),
    BadgeKind.busyWeek => t.badgeGoalBusyWeek(n),
    BadgeKind.records => t.badgeGoalRecords(n),
    BadgeKind.volume => t.badgeGoalVolume(weights.withUnit(def.goal)),
    BadgeKind.variety => t.badgeGoalVariety(n),
  };
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earnedAt, required this.isEarned, required this.weights});

  final BadgeProgress badge;
  final DateTime? earnedAt;
  final bool isEarned;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final def = badge.def;
    final progress = (badge.value / def.goal).clamp(0.0, 1.0);
    final shown = def.kind == BadgeKind.volume
        ? '${(progress * 100).floor()}%'
        : '${badge.value.clamp(0, def.goal).toInt()}/${def.goal.toInt()}';
    final title = badgeTitle(t, def);
    final goal = badgeGoal(t, def, weights);

    return Semantics(
      label: '$title. $goal. ${isEarned ? t.badgeEarned : shown}',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        key: Key('badge.${def.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(def.icon, size: 40, color: isEarned ? colors.primary : colors.outline),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(goal, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                if (isEarned)
                  Text(
                    earnedAt == null
                        ? t.badgeEarned
                        : t.badgeEarnedOn(DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(earnedAt!)),
                    style: theme.textTheme.labelLarge,
                  )
                else ...[
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(shown, style: theme.textTheme.labelMedium),
                ],
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.close))],
          ),
        ),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isEarned ? colors.primaryContainer : colors.surfaceContainerHighest,
                child: Icon(def.icon, color: isEarned ? colors.onPrimaryContainer : colors.outline),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: isEarned ? null : colors.outline),
              ),
              if (!isEarned) Text(shown, style: theme.textTheme.labelSmall?.copyWith(color: colors.outline)),
            ],
          ),
        ),
      ),
    );
  }
}
