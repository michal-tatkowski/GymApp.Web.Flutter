import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../exercises/presentation/category_ui.dart';
import '../data/plan_models.dart';
import 'exercise_picker_sheet.dart';
import 'plan_providers.dart';

/// Create or edit a plan: name + exercises in training order, each with a target
/// (sets × reps range). Drag the handle to reorder.
class PlanEditorScreen extends ConsumerStatefulWidget {
  const PlanEditorScreen({super.key, this.plan, this.template});

  /// null = new plan.
  final WorkoutPlan? plan;

  /// New plan prefilled from a ready-made one (saved as the user's own).
  final PlanTemplate? template;

  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends ConsumerState<PlanEditorScreen> {
  late final _name = TextEditingController(text: widget.plan?.name ?? widget.template?.name ?? '');
  late final List<PlanItem> _items = [...?(widget.plan?.items ?? widget.template?.items)];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    FocusScope.of(context).unfocus(); // keyboard must not jump back to the name after picking
    final exercise = await pickExercise(context, alreadyAdded: {for (final i in _items) i.exerciseId});
    if (exercise == null || !mounted) return;
    setState(() => _items.add(
          PlanItem(exerciseId: exercise.id, exerciseName: exercise.name, category: exercise.category, tracking: exercise.tracking),
        ));
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_name.text.trim().isEmpty || _items.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_name.text.trim().isEmpty ? t.planNameRequired : t.planNeedsExercise)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(planActionsProvider).save(widget.plan?.id, PlanRequest(name: _name.text, items: _items));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deletePlanTitle),
        content: Text(t.deletePlanBody(widget.plan!.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(planActionsProvider).delete(widget.plan!.id);
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? t.newPlan : t.editPlan),
        actions: [
          if (widget.plan != null)
            IconButton(tooltip: t.delete, icon: const Icon(Icons.delete_outline), onPressed: _saving ? null : _delete),
          TextButton(key: const Key('plan.save'), onPressed: _saving ? null : _save, child: Text(t.save)),
        ],
      ),
      floatingActionButton: _items.length >= kPlanMaxExercises
          ? null
          : FloatingActionButton.extended(
              key: const Key('plan.addExercise'),
              onPressed: _saving ? null : _addExercise,
              icon: const Icon(Icons.add),
              label: Text(t.addExercise),
            ),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          header: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              key: const Key('plan.name'),
              controller: _name,
              maxLength: kPlanMaxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t.planName, hintText: t.planNameHint),
            ),
          ),
          footer: _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(t.planEmptyHint, textAlign: TextAlign.center),
                )
              : null,
          itemCount: _items.length,
          onReorderItem: (from, to) => setState(() => _items.insert(to, _items.removeAt(from))),
          itemBuilder: (context, i) => _PlanItemCard(
            key: ValueKey(_items[i].exerciseId),
            index: i,
            item: _items[i],
            isLast: i == _items.length - 1,
            linkedFromPrevious: i > 0 && _items[i - 1].supersetWithNext,
            onChanged: (item) => setState(() => _items[i] = item),
            onRemove: () => setState(() => _items.removeAt(i)),
          ),
        ),
      ),
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.isLast,
    required this.linkedFromPrevious,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final PlanItem item;
  final bool isLast;
  final bool linkedFromPrevious;
  final ValueChanged<PlanItem> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final linked = item.supersetWithNext && !isLast;
    // Linked cards sit closer and share an accent edge, so a superset reads as one block.
    final accent = BorderSide(color: theme.colorScheme.tertiary, width: 3);
    return Card(
      margin: EdgeInsets.only(bottom: linked ? 2 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(linkedFromPrevious ? 4 : 12),
          bottom: Radius.circular(linked ? 4 : 12),
        ),
        side: linked || linkedFromPrevious ? accent : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_indicator)),
                ),
                Icon(categoryIcon(item.category), size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(item.exerciseName, style: theme.textTheme.titleMedium)),
                IconButton(tooltip: t.remove, icon: const Icon(Icons.close), onPressed: onRemove),
              ],
            ),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MiniStepper(
                  key: Key('plan.$index.sets'),
                  label: t.sets,
                  value: item.sets,
                  min: 1,
                  max: kPlanMaxSets,
                  onChanged: (v) => onChanged(item.copyWith(sets: v)),
                ),
                _MiniStepper(
                  key: Key('plan.$index.repsMin'),
                  label: t.repsFrom,
                  value: item.repsMin,
                  min: 1,
                  max: item.repsMax,
                  onChanged: (v) => onChanged(item.copyWith(repsMin: v)),
                ),
                _MiniStepper(
                  key: Key('plan.$index.repsMax'),
                  label: t.repsTo,
                  value: item.repsMax,
                  min: item.repsMin,
                  max: kPlanMaxReps,
                  onChanged: (v) => onChanged(item.copyWith(repsMax: v)),
                ),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  key: Key('plan.$index.superset'),
                  avatar: Icon(linked ? Icons.link : Icons.link_off, size: 18),
                  showCheckmark: false,
                  label: Text(t.supersetWithNext),
                  tooltip: t.supersetHint,
                  selected: linked,
                  onSelected: (v) => onChanged(item.copyWith(supersetWithNext: v)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Sets  − 3 +" — small integer stepper for plan targets.
class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  void _set(int v) {
    HapticFeedback.selectionClick();
    onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        IconButton(
          tooltip: t.decreaseBy('1'),
          // Standard density: 48 dp tap targets (compact was 40).
          onPressed: value > min ? () => _set(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          tooltip: t.increaseBy('1'),
          // Standard density: 48 dp tap targets.
          onPressed: value < max ? () => _set(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
