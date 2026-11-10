import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../../l10n/app_localizations.dart';
import '../../data/workout_models.dart';

/// What the line shows. Volume (Σ reps × weight) by default; for bodyweight
/// exercises (all volumes 0) the number of reps.
enum ProgressMetric { volume, reps }

ProgressMetric metricFor(List<ProgressPoint> points) =>
    points.isNotEmpty && points.every((p) => p.volume == 0) ? ProgressMetric.reps : ProgressMetric.volume;

double valueOf(ProgressPoint p, ProgressMetric m) => m == ProgressMetric.volume ? p.volume : p.totalReps.toDouble();

String formatValue(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Progress line: one point per training day, x = day (evenly spaced, in order),
/// y = volume or reps. Kept dependency-free on purpose (a CustomPainter).
class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key, required this.points, this.height = 200});

  final List<ProgressPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final metric = metricFor(points);
    final locale = Localizations.localeOf(context).toString();

    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(t.progressNeedsMoreDays, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final values = points.map((p) => valueOf(p, metric)).toList();
    final first = values.first, last = values.last;
    final trendUp = last > first, trendDown = last < first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(metric == ProgressMetric.volume ? t.progressVolume : t.progressReps,
                style: theme.textTheme.labelLarge),
            const Spacer(),
            Icon(
              trendUp ? Icons.trending_up : (trendDown ? Icons.trending_down : Icons.trending_flat),
              key: const Key('progress.trend'),
              color: trendUp ? Colors.green.shade600 : (trendDown ? theme.colorScheme.error : theme.colorScheme.outline),
            ),
            const SizedBox(width: 4),
            Text('${formatValue(first)} → ${formatValue(last)}', style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            key: const Key('progress.chart'),
            painter: _ProgressPainter(
              values: values,
              lineColor: theme.colorScheme.primary,
              gridColor: theme.colorScheme.outlineVariant,
              labelStyle: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMd(locale).format(points.first.date), style: theme.textTheme.labelSmall),
            Text(DateFormat.MMMd(locale).format(points.last.date), style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const _leftGutter = 44.0;
  static const _verticalPadding = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    var minV = values.reduce(math.min), maxV = values.reduce(math.max);
    if (maxV == minV) {
      // Flat line: give it some room so it sits in the middle.
      final pad = maxV == 0 ? 1.0 : maxV * 0.1;
      minV -= pad;
      maxV += pad;
    }
    final chartW = size.width - _leftGutter;
    final chartH = size.height - 2 * _verticalPadding;

    Offset at(int i) => Offset(
          _leftGutter + (values.length == 1 ? chartW / 2 : chartW * i / (values.length - 1)),
          _verticalPadding + chartH * (1 - (values[i] - minV) / (maxV - minV)),
        );

    // Grid + y labels (min, middle, max).
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = _verticalPadding + chartH * f;
      canvas.drawLine(Offset(_leftGutter, y), Offset(size.width, y), grid);
      final label = TextPainter(
        text: TextSpan(text: formatValue(maxV - (maxV - minV) * f), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _leftGutter - 6);
      label.paint(canvas, Offset(_leftGutter - 6 - label.width, y - label.height / 2));
    }

    // Area under the line, the line, and the points.
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(line)
      ..lineTo(at(values.length - 1).dx, size.height - _verticalPadding)
      ..lineTo(at(0).dx, size.height - _verticalPadding)
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
    final dot = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.values != values || old.lineColor != lineColor;
}
