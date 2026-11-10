import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/failure_messages.dart';
import '../../../../../core/validation/validators.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/workout_models.dart';

/// Must match the API (WorkoutRules).
const kMaxSets = 30;
const kMinReps = 1, kMaxReps = 1000;
const kMinSetWeight = 0, kMaxSetWeight = 1000;

/// −/+ step for weight (most plates come in 1.25 kg pairs).
const kWeightStep = 2.5;

/// Bottom sheet for a new or edited entry: date + sets (reps × kg) + notes.
/// [onSave] sends the request and may return a message to show instead of
/// "Workout saved" (e.g. "New record!"); on a Failure the sheet stays open and shows it.
class WorkoutEntrySheet extends StatefulWidget {
  const WorkoutEntrySheet({super.key, this.initial, this.prefillSets, required this.onSave});

  /// Entry being edited; null = new entry (today, prefilled from [prefillSets]).
  final WorkoutEntry? initial;

  /// Sets of the most recent entry — a new entry starts from them, so repeating
  /// the last workout is one tap.
  final List<WorkoutSet>? prefillSets;

  final Future<String?> Function(WorkoutEntryRequest) onSave;

  @override
  State<WorkoutEntrySheet> createState() => _WorkoutEntrySheetState();
}

class _SetRow {
  _SetRow(WorkoutSet? s)
    : reps = TextEditingController(text: s == null ? '' : '${s.reps}'),
      weight = TextEditingController(text: s == null ? '' : _fmt(s.weight));

  final TextEditingController reps;
  final TextEditingController weight;

  static String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class _WorkoutEntrySheetState extends State<WorkoutEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = widget.initial?.date ?? DateUtils.dateOnly(DateTime.now());
  late final List<_SetRow> _rows = [
    for (final s in widget.initial?.sets ?? widget.prefillSets ?? const [WorkoutSet(reps: 10, weight: 0)]) _SetRow(s),
  ];
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  void _addSet() => setState(() {
    // A new set copies the last one — the usual case is "same again".
    final last = _rows.isEmpty ? null : _rows.last;
    _rows.add(
      _SetRow(
        last == null
            ? null
            : WorkoutSet(reps: int.tryParse(last.reps.text) ?? 0, weight: parseDecimal(last.weight.text) ?? 0),
      ),
    );
  });

  void _removeSet(int i) => setState(() => _rows.removeAt(i).dispose());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final req = WorkoutEntryRequest(
      date: _date,
      sets: [
        for (final r in _rows)
          WorkoutSet(reps: int.parse(r.reps.text.trim()), weight: parseDecimal(r.weight.text) ?? 0),
      ],
      notes: _notes.text,
    );

    setState(() => _saving = true);
    try {
      final message = await widget.onSave(req);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(message ?? t.workoutSaved)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.initial == null ? t.logWorkout : t.editWorkout, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('workout.date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(t.date),
                subtitle: Text(DateFormat.yMMMMEEEEd(locale).format(_date)),
                onTap: _saving ? null : _pickDate,
              ),
              const Divider(),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14, right: 8),
                        child: CircleAvatar(radius: 13, child: Text('${i + 1}', style: theme.textTheme.labelMedium)),
                      ),
                      Expanded(
                        child: _StepperField(
                          fieldKey: Key('workout.set$i.reps'),
                          controller: _rows[i].reps,
                          enabled: !_saving,
                          label: t.reps,
                          step: 1,
                          integer: true,
                          min: kMinReps.toDouble(),
                          max: kMaxReps.toDouble(),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null) return t.invalidNumber;
                            if (n < kMinReps || n > kMaxReps) return t.numberOutOfRange(kMinReps, kMaxReps);
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StepperField(
                          fieldKey: Key('workout.set$i.weight'),
                          controller: _rows[i].weight,
                          enabled: !_saving,
                          label: t.weightKgShort,
                          step: kWeightStep,
                          min: kMinSetWeight.toDouble(),
                          max: kMaxSetWeight.toDouble(),
                          validator: (v) => validateOptionalNumber(t, v, min: kMinSetWeight, max: kMaxSetWeight),
                        ),
                      ),
                      IconButton(
                        tooltip: t.removeSet,
                        onPressed: _saving || _rows.length == 1 ? null : () => _removeSet(i),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving || _rows.length >= kMaxSets ? null : _addSet,
                  icon: const Icon(Icons.add),
                  label: Text(t.addSet),
                ),
              ),
              TextFormField(
                controller: _notes,
                enabled: !_saving,
                maxLength: 500,
                decoration: InputDecoration(labelText: t.notesOptional),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('workout.save'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(t.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number field with −/+ buttons inside — fast to adjust between sets
/// without opening the keyboard (one-handed use at the gym).
class _StepperField extends StatelessWidget {
  const _StepperField({
    this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.label,
    required this.step,
    required this.min,
    required this.max,
    required this.validator,
    this.integer = false,
  });

  /// Key of the inner TextFormField (tests and focus).
  final Key? fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final double step;
  final double min;
  final double max;
  final bool integer;
  final FormFieldValidator<String> validator;

  void _change(int direction) {
    final current = parseDecimal(controller.text) ?? 0;
    final next = (current + direction * step).clamp(min, max);
    controller.text = integer || next == next.roundToDouble() ? '${next.round()}' : '$next';
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final stepText = step == step.roundToDouble() ? '${step.round()}' : '$step';
    const compact = BoxConstraints(minWidth: 36, minHeight: 36);
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: integer ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: integer ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        prefixIcon: IconButton(
          tooltip: t.decreaseBy(stepText),
          constraints: compact,
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? () => _change(-1) : null,
          icon: const Icon(Icons.remove),
        ),
        suffixIcon: IconButton(
          tooltip: t.increaseBy(stepText),
          constraints: compact,
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? () => _change(1) : null,
          icon: const Icon(Icons.add),
        ),
      ),
      validator: validator,
    );
  }
}
