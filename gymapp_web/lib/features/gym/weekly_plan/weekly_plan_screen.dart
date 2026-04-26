import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

class WeeklyPlanScreen extends StatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  // Monday of the currently displayed week.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  bool get _isCurrentWeek =>
      _mondayOf(DateTime.now()).isAtSameMomentAs(_weekStart);

  void _goToPreviousWeek() {
    if (!_isCurrentWeek) {
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    }
  }

  void _goToNextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(t.weeklyPlan)),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.secondary.withOpacity(0.10),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Week header ──────────────────────────────────────
                  _WeekHeader(
                    weekStart: _weekStart,
                    weekEnd: _weekEnd,
                    canGoPrev: !_isCurrentWeek,
                    onPrev: _goToPreviousWeek,
                    onNext: _goToNextWeek,
                  ),
                  const SizedBox(height: 16),
                  // ── Day tiles ────────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final day = _weekStart.add(Duration(days: i));
                        final isToday = day.year == today.year &&
                            day.month == today.month &&
                            day.day == today.day;
                        return _DayTile(
                          day: day,
                          isToday: isToday,
                          onTap: () {
                            // TODO: navigate to day detail
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Week header ─────────────────────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.canGoPrev,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final bool canGoPrev;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('d MMM', Localizations.localeOf(context).toString());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canGoPrev ? onPrev : null,
            tooltip: 'Poprzedni tydzień',
          ),
          Text(
            '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Następny tydzień',
          ),
        ],
      ),
    );
  }
}

// ─── Day tile ─────────────────────────────────────────────────────────────────

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dayName = DateFormat('EEEE', locale).format(day);
    final dayDate = DateFormat('d MMM', locale).format(day);

    return Material(
      color: isToday
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Day abbreviation circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.12),
                ),
                alignment: Alignment.center,
                child: Text(
                  DateFormat('E', locale).format(day)[0].toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(dayName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      dayDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
