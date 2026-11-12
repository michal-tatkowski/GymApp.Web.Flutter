import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/providers/retry.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../gym/workouts/data/workout_models.dart';
import '../../../gym/workouts/presentation/workout_providers.dart';

/// Body weight of the last 6 months, oldest first.
final bodyWeightsProvider = FutureProvider.autoDispose<List<BodyWeight>>(
  (ref) => ref
      .watch(workoutRepositoryProvider)
      .getBodyWeights(since: DateUtils.addDaysToDate(DateUtils.dateOnly(DateTime.now()), -180)),
  retry: noRetry,
);

/// Must match the API (BodyWeightLimits), in kg.
const kMinBodyWeightKg = 20.0, kMaxBodyWeightKg = 400.0;

/// "Body weight": latest value, change over 30 days, a small chart and "Log today".
class BodyWeightCard extends ConsumerWidget {
  const BodyWeightCard({super.key});

  Future<void> _log(BuildContext context, WidgetRef ref, List<BodyWeight> history) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final weights = ref.read(weightFormatProvider);
    final kg = await showDialog<double>(
      context: context,
      builder: (_) => _LogDialog(initialKg: history.lastOrNull?.kg, weights: weights),
    );
    if (kg == null) return;
    try {
      await ref.read(workoutRepositoryProvider).setBodyWeight(DateUtils.dateOnly(DateTime.now()), kg);
      ref.invalidate(bodyWeightsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  Future<void> _history(BuildContext context, WidgetRef ref, List<BodyWeight> history) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (_) => _HistorySheet(history: history),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weights = ref.watch(weightFormatProvider);
    final async = ref.watch(bodyWeightsProvider);
    final history = async.value ?? const <BodyWeight>[];
    final latest = history.lastOrNull;
    final monthAgo = DateUtils.addDaysToDate(DateUtils.dateOnly(DateTime.now()), -30);
    final base = history.where((w) => !w.date.isAfter(monthAgo)).lastOrNull ?? history.firstOrNull;
    final change = latest != null && base != null && base != latest ? latest.kg - base.kg : null;

    return Card(
      key: const Key('bodyWeight.card'),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: history.isEmpty ? null : () => _history(context, ref, history),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.monitor_weight_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.bodyWeight, style: theme.textTheme.titleMedium)),
                  FilledButton.tonalIcon(
                    key: const Key('bodyWeight.log'),
                    onPressed: async.isLoading && !async.hasValue ? null : () => _log(context, ref, history),
                    icon: const Icon(Icons.add),
                    label: Text(t.bodyWeightLog),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (async.hasError && !async.hasValue)
                Text(describeError(t, async.error), style: TextStyle(color: theme.colorScheme.error))
              else if (latest == null)
                Text(t.bodyWeightEmpty)
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(weights.withUnit(latest.kg), key: const Key('bodyWeight.latest'), style: theme.textTheme.headlineSmall),
                    const SizedBox(width: 12),
                    if (change != null && change != 0)
                      Text(
                        t.bodyWeightChange('${change > 0 ? '+' : '−'}${weights.withUnit(change.abs())}'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
                if (history.length >= 2) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _Sparkline(
                        values: history.map((w) => w.kg).toList(),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(
        values.length == 1 ? 0 : i / (values.length - 1) * size.width,
        size.height - 4 - (values[i] - lo) / span * (size.height - 8),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values || old.color != color;
}

/// Today's weight in the user's unit (prefilled with the last one); returns kg.
class _LogDialog extends StatefulWidget {
  const _LogDialog({required this.initialKg, required this.weights});

  final double? initialKg;
  final WeightFormat weights;

  @override
  State<_LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<_LogDialog> {
  late final _value = TextEditingController(
    text: widget.initialKg == null ? '' : WeightFormat.formatNumber(widget.weights.fromKg(widget.initialKg!)),
  );
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, widget.weights.toKg(parseDecimal(_value.text)!));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final w = widget.weights;
    final min = w.fromKg(kMinBodyWeightKg).floor(), max = w.fromKg(kMaxBodyWeightKg).ceil();
    return AlertDialog(
      title: Text(t.bodyWeightToday),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const Key('bodyWeight.value'),
          controller: _value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(suffixText: w.label),
          validator: (v) => (v == null || v.trim().isEmpty) ? t.invalidNumber : validateOptionalNumber(t, v, min: min, max: max),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(key: const Key('bodyWeight.save'), onPressed: _submit, child: Text(t.save)),
      ],
    );
  }
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.history});

  final List<BodyWeight> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final weights = ref.watch(weightFormatProvider);
    final locale = Localizations.localeOf(context).toString();
    final items = history.reversed.toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(t.bodyWeight, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final w in items)
          ListTile(
            title: Text(weights.withUnit(w.kg)),
            subtitle: Text(DateFormat.yMMMEd(locale).format(w.date)),
            trailing: IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref.read(workoutRepositoryProvider).deleteBodyWeight(w.date);
                ref.invalidate(bodyWeightsProvider);
                navigator.pop();
              },
            ),
          ),
      ],
    );
  }
}
