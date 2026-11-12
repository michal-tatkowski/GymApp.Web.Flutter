import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/providers/retry.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../gym/workouts/data/workout_models.dart';

/// Body parts measured (API fields `<name>Cm`).
enum BodyPart { waist, chest, hips, arm, thigh, neck }

/// Must match the API (MeasurementLimits).
const kMinCm = 10, kMaxCm = 300;

/// Circumferences of one day, in cm; missing = not measured that day.
class BodyMeasurement {
  const BodyMeasurement({required this.date, required this.cm});

  final DateTime date;
  final Map<BodyPart, double> cm;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
        date: fromApiDate(json['date'] as String),
        cm: {
          for (final p in BodyPart.values)
            if (json['${p.name}Cm'] is num) p: (json['${p.name}Cm'] as num).toDouble(),
        },
      );
}

class MeasurementsRepository {
  MeasurementsRepository(this._dio);

  final Dio _dio;

  /// Oldest first.
  Future<List<BodyMeasurement>> list() => _guard(() async {
        final res = await _dio.get<dynamic>('BodyMeasurements');
        return (res.data as List).cast<Map<String, dynamic>>().map(BodyMeasurement.fromJson).toList();
      });

  Future<void> save(DateTime date, Map<BodyPart, double> cm) => _guard(() => _dio.put<dynamic>(
        'BodyMeasurements/${toApiDate(date)}',
        data: {for (final e in cm.entries) '${e.key.name}Cm': e.value},
      ));

  Future<void> delete(DateTime date) => _guard(() => _dio.delete<dynamic>('BodyMeasurements/${toApiDate(date)}'));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on TypeError {
      throw const ServerFailure();
    }
  }
}

final measurementsRepositoryProvider = Provider((ref) => MeasurementsRepository(ref.watch(dioProvider)));

final measurementsProvider = FutureProvider.autoDispose<List<BodyMeasurement>>(
  (ref) => ref.watch(measurementsRepositoryProvider).list(),
  retry: noRetry,
);

String bodyPartLabel(AppLocalizations t, BodyPart p) => switch (p) {
      BodyPart.waist => t.partWaist,
      BodyPart.chest => t.partChest,
      BodyPart.hips => t.partHips,
      BodyPart.arm => t.partArm,
      BodyPart.thigh => t.partThigh,
      BodyPart.neck => t.partNeck,
    };

String _cm(double v) => '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)} cm';

/// "Measurements": the latest value of each part and its change since the first
/// measurement; "+" records today's (any subset of parts).
class MeasurementsCard extends ConsumerWidget {
  const MeasurementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final all = ref.watch(measurementsProvider).value ?? const [];
    final locale = Localizations.localeOf(context).toString();

    // Latest and first value per part (parts are measured on different days).
    final latest = <BodyPart, (double, DateTime)>{};
    final first = <BodyPart, double>{};
    for (final m in all) {
      for (final e in m.cm.entries) {
        first.putIfAbsent(e.key, () => e.value);
        latest[e.key] = (e.value, m.date);
      }
    }

    return Card(
      key: const Key('measurements.card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.measurements, style: theme.textTheme.titleMedium)),
                IconButton(
                  key: const Key('measurements.add'),
                  tooltip: t.addMeasurement,
                  icon: const Icon(Icons.add),
                  onPressed: () => _showSheet(context, latest.map((k, v) => MapEntry(k, v.$1))),
                ),
              ],
            ),
            if (latest.isEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8, right: 8), child: Text(t.measurementsEmpty))
            else
              for (final p in BodyPart.values)
                if (latest[p] case (final value, final date))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(bodyPartLabel(t, p))),
                        Text(_cm(value), key: Key('measurements.${p.name}'), style: theme.textTheme.labelLarge),
                        SizedBox(
                          width: 72,
                          child: Text(
                            value == first[p] ? '' : '${value > first[p]! ? '+' : '−'}${_cm((value - first[p]!).abs())}',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(DateFormat.MMMd(locale).format(date), textAlign: TextAlign.end, style: theme.textTheme.labelSmall),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context, Map<BodyPart, double> last) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _MeasurementSheet(last: last),
      );
}

class _MeasurementSheet extends ConsumerStatefulWidget {
  const _MeasurementSheet({required this.last});

  /// Last values, shown as hints.
  final Map<BodyPart, double> last;

  @override
  ConsumerState<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<_MeasurementSheet> {
  final _form = GlobalKey<FormState>();
  late final _fields = {for (final p in BodyPart.values) p: TextEditingController()};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    final values = {
      for (final e in _fields.entries)
        if (parseDecimal(e.value.text) case final v?) e.key: v,
    };
    final messenger = ScaffoldMessenger.of(context);
    if (values.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(t.measurementsNeedOne)));
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(measurementsRepositoryProvider).save(DateUtils.dateOnly(DateTime.now()), values);
      ref.invalidate(measurementsProvider);
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.addMeasurement, style: Theme.of(context).textTheme.titleLarge),
              Text(t.measurementsHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  for (final p in BodyPart.values)
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        key: Key('measurement.${p.name}'),
                        controller: _fields[p],
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: bodyPartLabel(t, p),
                          suffixText: 'cm',
                          hintText: widget.last[p] == null ? null : _cm(widget.last[p]!).replaceAll(' cm', ''),
                        ),
                        validator: (v) => validateOptionalNumber(t, v, min: kMinCm, max: kMaxCm),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(key: const Key('measurement.save'), onPressed: _saving ? null : _save, child: Text(t.save)),
            ],
          ),
        ),
      ),
    );
  }
}
