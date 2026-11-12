import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../exercises/data/models/exercise.dart';
import '../../exercises/presentation/category_ui.dart';
import '../../exercises/presentation/exercises_providers.dart';

/// Bottom sheet: search the catalog and pick one exercise (favorites first).
/// Returns null when dismissed.
Future<Exercise?> pickExercise(BuildContext context, {Set<String> alreadyAdded = const {}}) =>
    showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExercisePicker(alreadyAdded: alreadyAdded),
    );

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker({required this.alreadyAdded});

  final Set<String> alreadyAdded;

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  Timer? _debounce;
  late Future<List<Exercise>> _results = _search('');

  Future<List<Exercise>> _search(String q) =>
      ref.read(exerciseRepositoryProvider).getExercises(search: q.trim().isEmpty ? null : q, pageSize: 50);

  void _onChanged(String q) {
    _debounce?.cancel();
    // Block body: an arrow would return the Future from setState, which Flutter rejects.
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() {
          _results = _search(q);
        }));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('picker.search'),
              autofocus: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t.searchExercises),
              onChanged: _onChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _results,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text(describeError(t, snap.error)));
                final items = snap.data;
                if (items == null) return const Center(child: CircularProgressIndicator());
                if (items.isEmpty) return Center(child: Text(t.noExercisesFound));
                return ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final added = widget.alreadyAdded.contains(e.id);
                    return ListTile(
                      leading: Icon(categoryIcon(e.category)),
                      title: Text(e.name),
                      subtitle: Text(categoryLabel(context, e.category)),
                      trailing: added
                          ? const Icon(Icons.check)
                          : e.isFavorite
                              ? Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 18)
                              : null,
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
