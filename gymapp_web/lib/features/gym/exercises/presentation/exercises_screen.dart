import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/models/exercise.dart';
import 'add_exercise_sheet.dart';
import 'exercise_detail_screen.dart';
import 'exercises_providers.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(exercisesProvider.notifier).loadMore();
    }
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddExerciseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(exercisesProvider);
    final notifier = ref.read(exercisesProvider.notifier);

    // Show error snackbar
    ref.listen(exercisesProvider, (_, next) {
      if (next.error != null) {
        final msg = next.error is Failure
            ? (next.error as Failure).message
            : next.error.toString();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    final exercises = notifier.filtered;

    return Scaffold(
      appBar: AppBar(title: Text(t.exercises)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: Text(t.addExercise),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Search bar + category filter ─────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: t.searchExercises,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: state.query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    notifier.setQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: notifier.setQuery,
                      ),
                      const SizedBox(height: 8),
                      _CategoryChips(
                        selected: state.categoryFilter,
                        onSelected: notifier.setCategory,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── List ─────────────────────────────────────────────
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : exercises.isEmpty
                          ? _EmptyState(onRetry: notifier.load)
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              itemCount:
                                  exercises.length + (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i == exercises.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                return _ExerciseTile(
                                  exercise: exercises[i],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ExerciseDetailScreen(
                                        exercise: exercises[i],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final ExerciseCategory? selected;
  final ValueChanged<ExerciseCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: AppLocalizations.of(context)!.allCategories,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final cat in ExerciseCategory.values)
            _Chip(
              label: _categoryLabel(context, cat),
              isSelected: selected == cat,
              onTap: () => onSelected(cat),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        labelStyle: theme.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// ─── Exercise tile ────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _categoryIcon(exercise.category),
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(exercise.name),
        subtitle: Text(
          _categoryLabel(context, exercise.category),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exercise.isCustom)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.7)),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center,
              size: 64,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(t.noExercisesFound),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t.retry),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

IconData _categoryIcon(ExerciseCategory cat) => switch (cat) {
      ExerciseCategory.push => Icons.arrow_upward,
      ExerciseCategory.pull => Icons.arrow_downward,
      ExerciseCategory.legs => Icons.directions_run,
      ExerciseCategory.core => Icons.rotate_right,
      ExerciseCategory.cardio => Icons.favorite_outline,
      ExerciseCategory.other => Icons.fitness_center,
    };
