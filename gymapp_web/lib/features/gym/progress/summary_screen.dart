import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/providers/retry.dart';
import '../../../core/units/weight_unit.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

enum SummaryPeriod { month, year }

/// Totals of a month or a year of training.
class PeriodSummary {
  const PeriodSummary({
    required this.workouts,
    required this.sets,
    required this.volumeKg,
    required this.minutes,
    required this.records,
    required this.topExercises,
  });

  final int workouts;
  final int sets;
  final double volumeKg;
  final int minutes;
  final int records;

  /// Most often trained, with the number of days.
  final List<(String name, int days)> topExercises;
}

PeriodSummary summarize(List<TrainingDayDetails> days, List<PersonalRecord> records, DateTime from, DateTime to) {
  final counts = <String, int>{};
  for (final d in days) {
    for (final e in d.exercises) {
      counts[e.exerciseName] = (counts[e.exerciseName] ?? 0) + 1;
    }
  }
  final top = counts.entries.toList()..sort((a, b) => b.value != a.value ? b.value - a.value : a.key.compareTo(b.key));
  return PeriodSummary(
    workouts: days.length,
    sets: days.fold(0, (n, d) => n + d.sets),
    volumeKg: days.fold(0.0, (v, d) => v + d.volumeKg),
    minutes: days.expand((d) => d.sessions).fold(Duration.zero, (sum, s) => sum + s.duration).inMinutes,
    records: records.where((r) => !r.date.isBefore(from) && !r.date.isAfter(to)).length,
    topExercises: [for (final e in top.take(3)) (e.key, e.value)],
  );
}

({DateTime from, DateTime to}) periodRange(SummaryPeriod period, DateTime anchor) => period == SummaryPeriod.month
    ? (from: DateTime(anchor.year, anchor.month), to: DateTime(anchor.year, anchor.month + 1, 0))
    : (from: DateTime(anchor.year), to: DateTime(anchor.year, 12, 31));

final _periodDaysProvider = FutureProvider.autoDispose.family<List<TrainingDayDetails>, ({DateTime from, DateTime to})>(
  (ref, range) => ref.watch(workoutRepositoryProvider).getDays(from: range.from, to: range.to),
  retry: noRetry,
);

/// "November: 14 workouts, 92 t, 5 records…" — month or year, with the previous ones
/// one tap away, shareable as an image.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final _shareKey = GlobalKey();
  SummaryPeriod _period = SummaryPeriod.month;
  DateTime _anchor = DateTime.now();
  bool _sharing = false;

  void _move(int step) => setState(() => _anchor = _period == SummaryPeriod.month
      ? DateTime(_anchor.year, _anchor.month + step)
      : DateTime(_anchor.year + step, _anchor.month));

  Future<void> _share(String title) async {
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(ShareParams(
        text: title,
        files: [XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png', name: 'gymapp-summary.png')],
      ));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final weights = ref.watch(weightFormatProvider);
    final range = periodRange(_period, _anchor);
    final title = _period == SummaryPeriod.month ? DateFormat.yMMMM(locale).format(range.from) : '${range.from.year}';
    final now = DateTime.now();
    final isCurrent = !range.to.isBefore(DateTime(now.year, now.month, now.day));
    final days = ref.watch(_periodDaysProvider(range));
    final records = ref.watch(yearStatsProvider).value?.records ?? const <PersonalRecord>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.summaryTitle),
        actions: [
          IconButton(
            key: const Key('summary.share'),
            tooltip: t.share,
            icon: const Icon(Icons.ios_share),
            onPressed: _sharing || !days.hasValue ? null : () => _share('GymApp · $title'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<SummaryPeriod>(
            key: const Key('summary.period'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: SummaryPeriod.month, label: Text(t.summaryMonth)),
              ButtonSegment(value: SummaryPeriod.year, label: Text(t.summaryYear)),
            ],
            selected: {_period},
            onSelectionChanged: (v) => setState(() => _period = v.single),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(key: const Key('summary.prev'), tooltip: t.previous, onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                key: const Key('summary.next'),
                tooltip: t.next,
                onPressed: isCurrent ? null : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          days.when(
            loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => ErrorView(message: describeError(t, e), onRetry: () => ref.invalidate(_periodDaysProvider(range))),
            data: (list) => RepaintBoundary(
              key: _shareKey,
              child: _SummaryCard(title: title, summary: summarize(list, records, range.from, range.to), weights: weights),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.summary, required this.weights});

  final String title;
  final PeriodSummary summary;
  final WeightFormat weights;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget stat(String value, String label, IconData icon) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
              Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
            ],
          ),
        );

    return Card(
      key: const Key('summary.card'),
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AppLogo(size: 28, showName: false),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.workouts == 0)
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(t.summaryEmpty, textAlign: TextAlign.center))
            else ...[
              Row(
                children: [
                  stat('${summary.workouts}', t.summaryWorkouts, Icons.event_available),
                  stat('${summary.sets}', t.summarySets, Icons.repeat),
                  stat(summary.volumeKg >= 1000 ? '${(weights.fromKg(summary.volumeKg) / 1000).toStringAsFixed(1)} t' : weights.withUnit(summary.volumeKg),
                      t.summaryVolume, Icons.fitness_center),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  stat(summary.minutes > 0 ? '${(summary.minutes / 60).toStringAsFixed(1)} h' : '–', t.summaryTime, Icons.timer_outlined),
                  stat('${summary.records}', t.summaryRecords, Icons.emoji_events_outlined),
                  stat(summary.workouts == 0 ? '–' : (summary.sets / summary.workouts).toStringAsFixed(1), t.summarySetsPerWorkout,
                      Icons.stacked_bar_chart),
                ],
              ),
              if (summary.topExercises.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(t.summaryTopExercises, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                for (final (i, (name, days)) in summary.topExercises.indexed)
                  Text('${i + 1}. $name · ${t.trainingDays(days)}', style: theme.textTheme.bodyMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
