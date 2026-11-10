import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/models/create_exercise_request.dart';
import '../data/models/exercise.dart';
import 'exercises_providers.dart';
import 'category_ui.dart';

class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.other;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final req = CreateExerciseRequest(
      name: _nameCtrl.text.trim(),
      category: _category,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(exercisesProvider.notifier).addExercise(req);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.exerciseAdded)));
    } catch (e) {
      // e.g. 409 "You already have an exercise with this name" — the sheet stays open.
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.addExercise,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // ── Name ─────────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.exerciseName,
                prefixIcon: const Icon(Icons.fitness_center),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            // ── Category ──────────────────────────────────────────────
            DropdownButtonFormField<ExerciseCategory>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: t.category,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: ExerciseCategory.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(categoryLabel(context, cat)),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            // ── Description ───────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              enabled: !_saving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.descriptionOptional,
                prefixIcon: const Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            // ── Save button ───────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}
