import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import 'exercises_providers.dart';

/// Must match the API (SetExerciseNoteCommandHandler.MaxLength).
const kExerciseNoteMaxLength = 300;

/// The exercise's persistent note ("seat 4, wide grip") with a pencil to change it,
/// or a small "Add a note" button when there is none.
class ExerciseNoteTile extends ConsumerWidget {
  const ExerciseNoteTile({super.key, required this.exerciseId});

  final String exerciseId;

  Future<void> _edit(BuildContext context, WidgetRef ref, String current) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final note = await showDialog<String>(context: context, builder: (_) => _ExerciseNoteDialog(initial: current));
    if (note == null || note.trim() == current) return;
    try {
      await ref.read(exerciseNotesProvider.notifier).set(exerciseId, note);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final note = ref.watch(exerciseNotesProvider).value?[exerciseId];
    if (note == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('exerciseNote.add'),
          onPressed: () => _edit(context, ref, ''),
          icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
          label: Text(t.addExerciseNote),
        ),
      );
    }
    return Card(
      key: const Key('exerciseNote'),
      margin: const EdgeInsets.only(top: 8),
      color: theme.colorScheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.sticky_note_2_outlined, color: theme.colorScheme.onTertiaryContainer),
        title: Text(note, style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
        trailing: IconButton(
          key: const Key('exerciseNote.edit'),
          tooltip: t.editExerciseNote,
          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onTertiaryContainer),
          onPressed: () => _edit(context, ref, note),
        ),
      ),
    );
  }
}

class _ExerciseNoteDialog extends StatefulWidget {
  const _ExerciseNoteDialog({required this.initial});

  final String initial;

  @override
  State<_ExerciseNoteDialog> createState() => _ExerciseNoteDialogState();
}

class _ExerciseNoteDialogState extends State<_ExerciseNoteDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.exerciseNote),
      content: TextField(
        key: const Key('exerciseNote.field'),
        controller: _controller,
        autofocus: true,
        maxLength: kExerciseNoteMaxLength,
        minLines: 1,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: t.exerciseNoteHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          key: const Key('exerciseNote.save'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(t.save),
        ),
      ],
    );
  }
}
