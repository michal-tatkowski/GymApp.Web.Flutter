import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/auth_providers.dart';
import '../data/exercise_api.dart';
import '../data/exercise_repository.dart';
import '../data/models/create_exercise_request.dart';
import '../data/models/exercise.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final exerciseApiProvider = Provider<ExerciseApi>(
  (ref) => ExerciseApi(ref.watch(dioProvider)),
);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(api: ref.watch(exerciseApiProvider)),
);

// ─── State ────────────────────────────────────────────────────────────────────

class ExercisesState {
  const ExercisesState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.query = '',
    this.categoryFilter,
  });

  final List<Exercise> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String query;
  final ExerciseCategory? categoryFilter;

  ExercisesState copyWith({
    List<Exercise>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    String? query,
    ExerciseCategory? categoryFilter,
    bool clearCategory = false,
  }) =>
      ExercisesState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        query: query ?? this.query,
        categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

const exercisesPageSize = 20;
const searchDebounce = Duration(milliseconds: 300);

/// Paged exercise list. Search and category filter are applied by the API,
/// so "load more" continues the same filtered list.
class ExercisesNotifier extends StateNotifier<ExercisesState> {
  ExercisesNotifier(this._repo) : super(const ExercisesState()) {
    load();
  }

  final ExerciseRepository _repo;
  int _page = 1;
  Timer? _debounce;

  /// Incremented on every new query — responses for an older query are dropped,
  /// so a slow "push" response cannot overwrite a newer "pull" list.
  int _generation = 0;

  Future<List<Exercise>> _fetch(int page) => _repo.getExercises(
        category: state.categoryFilter,
        search: state.query,
        page: page,
        pageSize: exercisesPageSize,
      );

  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    state = state.copyWith(isLoading: true, isLoadingMore: false, hasMore: true, clearError: true);
    try {
      final items = await _fetch(1);
      if (generation != _generation || !mounted) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= exercisesPageSize,
      );
    } catch (e) {
      if (generation != _generation || !mounted) return;
      state = state.copyWith(items: const [], isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final more = await _fetch(_page + 1);
      if (generation != _generation || !mounted) return;
      _page++;
      final known = state.items.map((e) => e.id).toSet();
      state = state.copyWith(
        items: [...state.items, ...more.where((e) => !known.contains(e.id))],
        isLoadingMore: false,
        hasMore: more.length >= exercisesPageSize,
      );
    } catch (e) {
      if (generation != _generation || !mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Debounced server-side search.
  void setQuery(String q) {
    if (q == state.query) return;
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, load);
  }

  Future<void> setCategory(ExerciseCategory? cat) async {
    if (cat == state.categoryFilter) return;
    state = state.copyWith(categoryFilter: cat, clearCategory: cat == null);
    await load();
  }

  /// Creates the exercise and shows it at the top when it matches the current filter.
  /// Throws a Failure — the caller (add sheet) shows the error.
  Future<Exercise> addExercise(CreateExerciseRequest req) async {
    final created = await _repo.createExercise(req);
    final filter = state.categoryFilter;
    final query = state.query.trim().toLowerCase();
    final matches = (filter == null || filter == created.category) &&
        (query.isEmpty || created.name.toLowerCase().contains(query));
    if (matches && mounted) {
      state = state.copyWith(items: [created, ...state.items.where((e) => e.id != created.id)]);
    }
    return created;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final exercisesProvider =
    StateNotifierProvider.autoDispose<ExercisesNotifier, ExercisesState>(
  (ref) => ExercisesNotifier(ref.watch(exerciseRepositoryProvider)),
);
