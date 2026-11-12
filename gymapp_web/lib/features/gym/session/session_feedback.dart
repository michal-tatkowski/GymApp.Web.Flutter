import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../workouts/data/workout_models.dart';
import '../workouts/presentation/workout_providers.dart';

/// Must match the API (SessionFeedback.MaxNoteLength).
const kWorkoutNoteMaxLength = 500;

const _moodIcons = [
  Icons.sentiment_very_dissatisfied,
  Icons.sentiment_dissatisfied,
  Icons.sentiment_neutral,
  Icons.sentiment_satisfied,
  Icons.sentiment_very_satisfied,
];

IconData moodIcon(int mood) => _moodIcons[(mood - 1).clamp(0, 4)];

String moodLabel(AppLocalizations t, int mood) => switch (mood) {
      1 => t.mood1,
      2 => t.mood2,
      3 => t.mood3,
      4 => t.mood4,
      _ => t.mood5,
    };

/// Five faces, very bad … great. Tapping the selected one again clears it.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.mood, required this.onChanged});

  final int? mood;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var m = 1; m <= 5; m++)
          IconButton(
            key: Key('mood.$m'),
            tooltip: moodLabel(t, m),
            isSelected: mood == m,
            iconSize: 32,
            color: scheme.onSurfaceVariant,
            selectedIcon: Icon(moodIcon(m), color: scheme.primary),
            style: mood == m ? IconButton.styleFrom(backgroundColor: scheme.primaryContainer) : null,
            onPressed: () => onChanged(mood == m ? null : m),
            icon: Icon(moodIcon(m)),
          ),
      ],
    );
  }
}

/// The note field under the faces (summary and history editor share it).
class WorkoutNoteField extends StatelessWidget {
  const WorkoutNoteField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TextField(
      key: const Key('workout.note'),
      controller: controller,
      maxLength: kWorkoutNoteMaxLength,
      minLines: 1,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: t.workoutNote, hintText: t.workoutNoteHint, border: const OutlineInputBorder()),
    );
  }
}

/// History: change mood and note of a past session.
Future<void> editSessionFeedback(BuildContext context, WidgetRef ref, WorkoutSessionInfo session) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<({int? mood, String? note})>(
    context: context,
    builder: (_) => _FeedbackDialog(session: session),
  );
  if (result == null) return;
  try {
    await ref.read(workoutRepositoryProvider).setSessionFeedback(session.id, mood: result.mood, note: result.note);
    ref.invalidate(trainingDaysProvider);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.session});

  final WorkoutSessionInfo session;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late int? _mood = widget.session.mood;
  late final _note = TextEditingController(text: widget.session.note ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const Key('session.feedback'),
      title: Text(t.sessionFeedback),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.moodQuestion),
            MoodPicker(mood: _mood, onChanged: (m) => setState(() => _mood = m)),
            const SizedBox(height: 8),
            WorkoutNoteField(controller: _note),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          key: const Key('session.feedback.save'),
          onPressed: () {
            final note = _note.text.trim();
            Navigator.pop(context, (mood: _mood, note: note.isEmpty ? null : note));
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
