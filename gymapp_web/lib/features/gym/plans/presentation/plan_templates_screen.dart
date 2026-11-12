import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../exercises/presentation/category_ui.dart';
import '../data/plan_models.dart';
import 'plan_editor_screen.dart';
import 'plan_providers.dart';

/// Ready-made plans; "Use" opens the editor with the plan filled in — the user can
/// change anything before saving it as their own.
class PlanTemplatesScreen extends ConsumerWidget {
  const PlanTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final templates = ref.watch(planTemplatesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.planTemplates)),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: describeError(t, e), onRetry: () => ref.invalidate(planTemplatesProvider)),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [for (final template in items) _TemplateCard(template: template)],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      key: Key('template.${template.key}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(template.name, style: theme.textTheme.titleMedium),
        subtitle: Text('${t.daysPerWeek(template.daysPerWeek)} · ${t.planExercises(template.items.length)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(template.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < template.items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(categoryIcon(template.items[i].category), size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(template.items[i].exerciseName)),
                  Text(template.items[i].target, style: theme.textTheme.labelMedium),
                  if (template.items[i].supersetWithNext)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.link, size: 16, color: theme.colorScheme.tertiary),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: Key('template.use.${template.key}'),
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                builder: (_) => PlanEditorScreen(template: template),
                fullscreenDialog: true,
              )),
              icon: const Icon(Icons.playlist_add),
              label: Text(t.useTemplate),
            ),
          ),
        ],
      ),
    );
  }
}
