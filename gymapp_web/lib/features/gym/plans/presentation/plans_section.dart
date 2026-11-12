import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/plan_models.dart';
import 'plan_editor_screen.dart';
import 'plan_templates_screen.dart';
import 'plan_providers.dart';

/// "Plans" on Today: each plan with "Start"; tap the card to edit it, "+" for a new one.
class PlansSection extends ConsumerWidget {
  const PlansSection({super.key, required this.onStart});

  final void Function(WorkoutPlan plan) onStart;

  static void openEditor(BuildContext context, [WorkoutPlan? plan]) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlanEditorScreen(plan: plan), fullscreenDialog: plan == null),
      );

  /// New plan: from scratch or from a ready-made one.
  static Future<void> newPlan(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final fromTemplate = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('plans.new.template'),
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(t.fromTemplate),
              subtitle: Text(t.fromTemplateHint),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              key: const Key('plans.new.empty'),
              leading: const Icon(Icons.edit_note),
              title: Text(t.emptyPlan),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (fromTemplate == null || !context.mounted) return;
    if (fromTemplate) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlanTemplatesScreen()));
    } else {
      openEditor(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plans = ref.watch(plansProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
          child: Row(
            children: [
              Expanded(child: Text(t.plans, style: theme.textTheme.titleMedium)),
              IconButton(
                key: const Key('plans.new'),
                tooltip: t.newPlan,
                icon: const Icon(Icons.add),
                onPressed: () => newPlan(context),
              ),
            ],
          ),
        ),
        plans.when(
          loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Card(
            child: ListTile(
              leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
              title: Text(describeError(t, e)),
              trailing: TextButton(onPressed: () => ref.invalidate(plansProvider), child: Text(t.retry)),
            ),
          ),
          data: (items) => items.isEmpty
              ? Card(
                  child: ListTile(
                    leading: const Icon(Icons.playlist_add),
                    title: Text(t.noPlansYet),
                    onTap: () => newPlan(context),
                  ),
                )
              : Card(
                  child: Column(
                    children: [
                      for (final plan in items)
                        ListTile(
                          key: Key('plan.${plan.id}'),
                          leading: const Icon(Icons.list_alt),
                          title: Text(plan.name),
                          subtitle: Text(
                            [t.planExercises(plan.items.length), plan.items.map((i) => i.exerciseName).take(3).join(', ')]
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => openEditor(context, plan),
                          trailing: FilledButton.icon(
                            key: Key('plan.start.${plan.id}'),
                            onPressed: plan.items.isEmpty ? null : () => onStart(plan),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(t.startWorkout),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
