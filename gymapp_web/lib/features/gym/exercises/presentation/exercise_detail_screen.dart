import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/models/exercise.dart';
import 'category_ui.dart';
import 'exercises_providers.dart';
import 'favorite_button.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Live copy from the list, so the star reflects toggles made here and on the list.
    final live = ref.watch(exercisesProvider.select(
            (s) => s.items.where((e) => e.id == exercise.id).firstOrNull)) ??
        exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          FavoriteButton(
            isFavorite: live.isFavorite,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(exercisesProvider.notifier).toggleFavorite(exercise.id);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.secondary.withValues(alpha: 0.10),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon + name ──────────────────────────────
                      Center(
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Icon(
                            categoryIcon(exercise.category),
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Category chip ─────────────────────────────
                      Center(
                        child: Chip(
                          avatar: Icon(
                            categoryIcon(exercise.category),
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          label: Text(categoryLabel(context, exercise.category)),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (exercise.isCustom) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Chip(
                            avatar: Icon(Icons.person_outline,
                                size: 16,
                                color: theme.colorScheme.primary),
                            label: Text(t.customExercise),
                            backgroundColor:
                                theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // ── Description ───────────────────────────────
                      Text(
                        t.description,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          exercise.description?.isNotEmpty == true
                              ? exercise.description!
                              : t.noDescription,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// re-use helpers from exercises_screen.dart via export or duplicate