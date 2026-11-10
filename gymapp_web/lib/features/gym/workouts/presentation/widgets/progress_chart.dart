import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../../l10n/app_localizations.dart';
import '../../data/workout_models.dart';

/// What the line shows.
/// - volume: Σ reps × weight of the day (default),
/// - oneRepMax: best estimated 1RM — shows strength gains when volume drops (10×100 → 8×110),
/// - maxWeight: heaviest set,
/// - reps: total reps — the only metric for bodyweight exercises (all volumes 0).
enum ProgressMetric { volume, oneRepMax, maxWeight, reps }

bool isBodyweight(List<ProgressPoint> points) => points.isNotEmpty && points.every((p) => p.volume == 0);

/// Default metric for these points.
ProgressMetric metricFor(List<ProgressPoint> points) => isBodyweight(points) ? ProgressMetric.reps : ProgressMetric.volume;

double valueOf(ProgressPoint p, ProgressMetric m) => switch (m) {
      ProgressMetric.volume => p.volume,
      ProgressMetric.oneRepMax => p.estimatedOneRepMax,
      ProgressMetric.maxWeight => p.maxWeight,
      ProgressMetric.reps => p.totalReps.toDouble(),
    };

String formatValue(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Time ranges of the chart; null days = everything.
enum ProgressRange {
  month(30),
  quarter(91),
  year(365),
  all(null);

  const ProgressRange(this.days);
  final int? days;
}

List<ProgressPoint> inRange(List<ProgressPoint> points, ProgressRange range, DateTime today) {
  final days = range.days;
  if (days == null) return points;
  final from = DateUtils.dateOnly(today).subtract(Duration(days: days));
  return points.where((p) => !p.date.isBefore(from)).toList();
}

/// Indexes of points that beat every earlier point (personal records, the first point excluded).
List<int> recordIndexes(List<double> values) {
  final result = <int>[];
  var best = double.negativeInfinity;
  for (var i = 0; i < values.length; i++) {
    if (i > 0 && values[i] > best) result.add(i);
    best = math.max(best, values[i]);
  }
  return result;
}

/// Kind of record set by a newly saved entry, or null.
enum NewRecord { volume, oneRepMax }

/// Compares an entry saved for [date] with the chart points from before saving.
/// Entries of the same day are summed (like on the chart). No record on the first day.
NewRecord? newRecordFor(List<ProgressPoint> before, WorkoutEntry saved) {
  if (before.isEmpty) return null;
  final sameDay = before.where((p) => DateUtils.isSameDay(p.date, saved.date)).firstOrNull;
  final dayVolume = (sameDay?.volume ?? 0) + saved.volume;
  final others = before.where((p) => !DateUtils.isSameDay(p.date, saved.date)).toList();
  if (others.isEmpty) return null;

  final best1Rm = others.map((p) => p.estimatedOneRepMax).reduce(math.max);
  if (saved.estimatedOneRepMax > 0 && saved.estimatedOneRepMax > best1Rm) return NewRecord.oneRepMax;
  final bestVolume = others.map((p) => p.volume).reduce(math.max);
  if (dayVolume > 0 && dayVolume > bestVolume) return NewRecord.volume;
  return null;
}

/// Progress chart: time range and metric selectors, the latest value with its
/// change, and the line (x = real date, so gaps between trainings are visible).
/// Tap or drag over the chart to read a day (tap it again to go back to the latest);
/// records are marked with a ring.
class ProgressChart extends StatefulWidget {
  const ProgressChart({super.key, required this.points, this.height = 200, this.today});

  final List<ProgressPoint> points;
  final double height;

  /// For tests; defaults to now.
  final DateTime? today;

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  ProgressRange _range = ProgressRange.all;
  ProgressMetric? _metric;
  int? _selected;

  String _metricLabel(AppLocalizations t, ProgressMetric m) => switch (m) {
        ProgressMetric.volume => t.metricVolume,
        ProgressMetric.oneRepMax => t.metricOneRepMax,
        ProgressMetric.maxWeight => t.metricMaxWeight,
        ProgressMetric.reps => t.metricReps,
      };

  String _rangeLabel(AppLocalizations t, ProgressRange r) => switch (r) {
        ProgressRange.month => t.range1M,
        ProgressRange.quarter => t.range3M,
        ProgressRange.year => t.range1Y,
        ProgressRange.all => t.rangeAll,
      };

  String _unit(ProgressMetric m) => m == ProgressMetric.reps ? '' : ' kg';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final bodyweight = isBodyweight(widget.points);
    final metrics = bodyweight
        ? [ProgressMetric.reps]
        : [ProgressMetric.volume, ProgressMetric.oneRepMax, ProgressMetric.maxWeight];
    final metric = metrics.contains(_metric) ? _metric! : metrics.first;
    final points = inRange(widget.points, _range, widget.today ?? DateTime.now());
    final values = points.map((p) => valueOf(p, metric)).toList();
    final selected = _selected != null && _selected! < points.length ? _selected : null;

    final header = <Widget>[
      if (metrics.length > 1)
        SegmentedButton<ProgressMetric>(
          key: const Key('progress.metric'),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [for (final m in metrics) ButtonSegment(value: m, label: Text(_metricLabel(t, m)))],
          selected: {metric},
          onSelectionChanged: (v) => setState(() {
            _metric = v.single;
            _selected = null;
          }),
        ),
      const SizedBox(height: 8),
      SegmentedButton<ProgressRange>(
        key: const Key('progress.range'),
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [for (final r in ProgressRange.values) ButtonSegment(value: r, label: Text(_rangeLabel(t, r)))],
        selected: {_range},
        onSelectionChanged: (v) => setState(() {
          _range = v.single;
          _selected = null;
        }),
      ),
      const SizedBox(height: 12),
    ];

    if (points.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.points.length >= 2) ...header,
          SizedBox(
            height: widget.height,
            child: Center(
              child: Text(t.progressNeedsMoreDays, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      );
    }

    final first = values.first, last = values.last;
    final change = first == 0 ? null : (last - first) / first * 100;
    final up = last > first, down = last < first;
    final trendColor = up ? Colors.green.shade600 : (down ? theme.colorScheme.error : theme.colorScheme.outline);
    final records = recordIndexes(values);
    final shown = selected ?? points.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        // ── The number that matters: latest (or tapped) value + change ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${formatValue(values[shown])}${_unit(metric)}',
              key: const Key('progress.value'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            if (selected == null && change != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up ? Icons.trending_up : (down ? Icons.trending_down : Icons.trending_flat),
                      key: const Key('progress.trend'),
                      size: 18,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                      key: const Key('progress.change'),
                      style: theme.textTheme.labelLarge?.copyWith(color: trendColor),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                DateFormat.yMMMd(locale).format(points[shown].date),
                key: const Key('progress.date'),
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
        if (records.contains(shown))
          Text(t.personalRecord, key: const Key('progress.record'), style: theme.textTheme.labelMedium?.copyWith(color: Colors.amber.shade800)),
        const SizedBox(height: 8),
        Semantics(
          label: t.chartSemantics(
            _metricLabel(t, metric),
            formatValue(first),
            formatValue(last),
            points.length,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = _ProgressPainter(
                dates: points.map((p) => p.date).toList(),
                values: values,
                records: records,
                selected: selected,
                lineColor: theme.colorScheme.primary,
                recordColor: Colors.amber.shade700,
                gridColor: theme.colorScheme.outlineVariant,
                labelStyle: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              );
              int nearest(Offset local) => painter.nearestIndex(local.dx, Size(constraints.maxWidth, widget.height));

              // Tap = show that day; tapping the same day again goes back to the latest.
              // (No double-tap handler: it would delay every single tap by ~300 ms.)
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final i = nearest(d.localPosition);
                  setState(() => _selected = i == _selected ? null : i);
                },
                onHorizontalDragUpdate: (d) {
                  final i = nearest(d.localPosition);
                  if (i != _selected) setState(() => _selected = i);
                },
                child: CustomPaint(
                  key: const Key('progress.chart'),
                  size: Size(constraints.maxWidth, widget.height),
                  painter: painter,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: _ProgressPainter.leftGutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat.MMMd(locale).format(points.first.date), style: theme.textTheme.labelSmall),
              Text(DateFormat.MMMd(locale).format(points.last.date), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.dates,
    required this.values,
    required this.records,
    required this.selected,
    required this.lineColor,
    required this.recordColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<DateTime> dates;
  final List<double> values;
  final List<int> records;
  final int? selected;
  final Color lineColor;
  final Color recordColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const leftGutter = 44.0;
  static const _vPad = 10.0;

  /// x position from the real date: a two-week break looks like a break.
  double _x(int i, double width) {
    final span = dates.last.difference(dates.first).inHours;
    final chartW = width - leftGutter;
    if (span == 0) return leftGutter + chartW / 2;
    return leftGutter + chartW * dates[i].difference(dates.first).inHours / span;
  }

  ({double min, double max}) _bounds() {
    var minV = values.reduce(math.min), maxV = values.reduce(math.max);
    if (maxV == minV) {
      final pad = maxV == 0 ? 1.0 : maxV * 0.1;
      minV -= pad;
      maxV += pad;
    }
    return (min: minV, max: maxV);
  }

  Offset _at(int i, Size size) {
    final b = _bounds();
    final chartH = size.height - 2 * _vPad;
    return Offset(_x(i, size.width), _vPad + chartH * (1 - (values[i] - b.min) / (b.max - b.min)));
  }

  int nearestIndex(double dx, Size size) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if ((_x(i, size.width) - dx).abs() < (_x(best, size.width) - dx).abs()) best = i;
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = _bounds();
    final chartH = size.height - 2 * _vPad;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = _vPad + chartH * f;
      canvas.drawLine(Offset(leftGutter, y), Offset(size.width, y), grid);
      final label = TextPainter(
        text: TextSpan(text: formatValue(b.max - (b.max - b.min) * f), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftGutter - 6);
      label.paint(canvas, Offset(leftGutter - 6 - label.width, y - label.height / 2));
    }

    final line = Path()..moveTo(_at(0, size).dx, _at(0, size).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(_at(i, size).dx, _at(i, size).dy);
    }
    final bottom = size.height - _vPad;
    final area = Path.from(line)
      ..lineTo(_at(values.length - 1, size).dx, bottom)
      ..lineTo(_at(0, size).dx, bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = lineColor.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final p = _at(i, size);
      if (records.contains(i)) {
        canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = recordColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      canvas.drawCircle(p, 3.5, Paint()..color = lineColor);
    }

    if (selected != null) {
      final p = _at(selected!, size);
      canvas.drawLine(Offset(p.dx, _vPad), Offset(p.dx, bottom), Paint()..color = lineColor.withValues(alpha: 0.4));
      canvas.drawCircle(p, 6, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.values != values || old.dates != dates || old.selected != selected || old.lineColor != lineColor;
}
