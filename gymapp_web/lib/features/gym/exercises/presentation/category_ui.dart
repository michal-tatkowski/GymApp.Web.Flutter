import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../data/models/exercise.dart';

/// Localized label of an exercise category.
String categoryLabel(BuildContext context, ExerciseCategory cat) {
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

IconData categoryIcon(ExerciseCategory cat) => switch (cat) {
      ExerciseCategory.push => Icons.arrow_upward,
      ExerciseCategory.pull => Icons.arrow_downward,
      ExerciseCategory.legs => Icons.directions_run,
      ExerciseCategory.core => Icons.rotate_right,
      ExerciseCategory.cardio => Icons.favorite_outline,
      ExerciseCategory.other => Icons.fitness_center,
    };
