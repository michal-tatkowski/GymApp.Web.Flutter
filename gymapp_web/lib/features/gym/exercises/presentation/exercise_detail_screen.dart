import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../data/models/exercise.dart';
import 'exercises_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.secondary.withOpacity(0.10),
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
                            _categoryIcon(exercise.category),
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
                            _categoryIcon(exercise.category),
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          label: Text(_categoryLabel(context, exercise.category)),
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
                                    .withOpacity(0.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // ── Description ───────────────────────────────
                      Text(
                        t.description,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.85),
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
IconData _categoryIcon(ExerciseCategory cat) => switch (cat) {
      ExerciseCategory.push => Icons.arrow_upward,
      ExerciseCategory.pull => Icons.arrow_downward,
      ExerciseCategory.legs => Icons.directions_run,
      ExerciseCategory.core => Icons.rotate_right,
      ExerciseCategory.cardio => Icons.favorite_outline,
      ExerciseCategory.other => Icons.fitness_center,
    };

String _categoryLabel(BuildContext context, ExerciseCategory cat) {
  final t = AppLocalizations.of(context)!;
  return switch (cat) {
    ExerciseCategory.push => t.catPush,
    ExerciseCategory.pull => t.catPull,
    ExerciseCategory.legs => t.catLegs,
    ExerciseCategory.core => t.catCore,
    ExerciseCategory.cardio => t.catCardio,
    ExerciseCategory.other => t.catOther,
  };
}
