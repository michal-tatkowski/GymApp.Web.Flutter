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
        categoryFilter:
            clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

const _pageSize = 20;

class ExercisesNotifier extends StateNotifier<ExercisesState> {
  ExercisesNotifier(this._repo) : super(const ExercisesState()) {
    load();
  }

  final ExerciseRepository _repo;
  int _page = 1;

  String? get _categoryParam => state.categoryFilter?.toJson().toString();

  Future<void> load() async {
    _page = 1;
    state = state.copyWith(isLoading: true, hasMore: true, clearError: true);
    try {
      final items = await _repo.getExercises(
        category: _categoryParam,
        page: _page,
        pageSize: _pageSize,
      );
      state = state.copyWith(
        items: _applyQuery(items),
        isLoading: false,
        // If we got fewer items than pageSize, there are no more pages.
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    _page++;
    try {
      final more = await _repo.getExercises(
        category: _categoryParam,
        page: _page,
        pageSize: _pageSize,
      );
      state = state.copyWith(
        items: [...state.items, ..._applyQuery(more)],
        isLoadingMore: false,
        hasMore: more.length >= _pageSize,
      );
    } catch (e) {
      _page--;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  Future<void> setCategory(ExerciseCategory? cat) async {
    if (cat == state.categoryFilter) return;
    state = state.copyWith(
      categoryFilter: cat,
      clearCategory: cat == null,
    );
    await load();
  }

  Future<Exercise?> addExercise(CreateExerciseRequest req) async {
    try {
      final created = await _repo.createExercise(req);
      // Prepend to list so it's immediately visible.
      state = state.copyWith(items: [created, ...state.items]);
      return created;
    } catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }

  // Client-side query filter applied on top of backend results.
  List<Exercise> _applyQuery(List<Exercise> items) {
    final q = state.query.toLowerCase().trim();
    if (q.isEmpty) return items;
    return items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  // Filtered view for the UI (re-applies query on current items).
  List<Exercise> get filtered {
    final q = state.query.toLowerCase().trim();
    if (q.isEmpty) return state.items;
    return state.items.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
}

final exercisesProvider =
    StateNotifierProvider.autoDispose<ExercisesNotifier, ExercisesState>(
  (ref) => ExercisesNotifier(ref.watch(exerciseRepositoryProvider)),
);
