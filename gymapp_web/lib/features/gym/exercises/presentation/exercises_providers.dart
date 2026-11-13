import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/providers/retry.dart';
import '../../../../core/storage/secure_storage_keys.dart';
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
    this.favoritesOnly = false,
  });

  final List<Exercise> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String query;
  final ExerciseCategory? categoryFilter;

  /// Only starred exercises (filtered on the server).
  final bool favoritesOnly;

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
    bool? favoritesOnly,
  }) =>
      ExercisesState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        query: query ?? this.query,
        categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

const exercisesPageSize = 20;
const searchDebounce = Duration(milliseconds: 300);

/// Paged exercise list. Search and category filter are applied by the API,
/// so "load more" continues the same filtered list.
class ExercisesNotifier extends Notifier<ExercisesState> {
  late ExerciseRepository _repo;
  int _page = 1;
  Timer? _debounce;

  /// Incremented on every new query — responses for an older query are dropped,
  /// so a slow "push" response cannot overwrite a newer "pull" list.
  int _generation = 0;

  @override
  ExercisesState build() {
    _repo = ref.watch(exerciseRepositoryProvider);
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(load);
    return const ExercisesState(isLoading: true);
  }

  Future<List<Exercise>> _fetch(int page) => _repo.getExercises(
        category: state.categoryFilter,
        search: state.query,
        favoritesOnly: state.favoritesOnly,
        page: page,
        pageSize: exercisesPageSize,
      );

  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    state = state.copyWith(isLoading: true, isLoadingMore: false, hasMore: true, clearError: true);
    try {
      final items = await _fetch(1);
      if (generation != _generation || !ref.mounted) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= exercisesPageSize,
      );
    } catch (e) {
      if (generation != _generation || !ref.mounted) return;
      state = state.copyWith(items: const [], isLoading: false, error: e);
    }
  }

  /// Pull-to-refresh: reloads page 1 but keeps the current list on screen until
  /// the new one arrives; on failure the list stays and the error is reported.
  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final items = await _fetch(1);
      if (generation != _generation || !ref.mounted) return;
      _page = 1;
      state = state.copyWith(
        items: items,
        isLoading: false,
        isLoadingMore: false,
        hasMore: items.length >= exercisesPageSize,
        clearError: true,
      );
    } catch (e) {
      if (generation != _generation || !ref.mounted) return;
      state = state.copyWith(error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final more = await _fetch(_page + 1);
      if (generation != _generation || !ref.mounted) return;
      _page++;
      final known = state.items.map((e) => e.id).toSet();
      state = state.copyWith(
        items: [...state.items, ...more.where((e) => !known.contains(e.id))],
        isLoadingMore: false,
        hasMore: more.length >= exercisesPageSize,
      );
    } catch (e) {
      if (generation != _generation || !ref.mounted) return;
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

  Future<void> setFavoritesOnly(bool value) async {
    if (value == state.favoritesOnly) return;
    state = state.copyWith(favoritesOnly: value);
    await load();
  }

  /// Stars / unstars an exercise. The star flips immediately; if the API call
  /// fails it flips back and the Failure is rethrown for the caller to show.
  /// The list is not re-sorted on the spot (no jumping rows) — favorites move
  /// to the top on the next load. In "favorites only" mode an unstarred row
  /// disappears right away.
  Future<void> toggleFavorite(String exerciseId) async {
    final current = state.items.where((e) => e.id == exerciseId).firstOrNull;
    if (current == null) return;
    final target = !current.isFavorite;

    _replace(exerciseId, (e) => e.copyWith(isFavorite: target));
    try {
      await _repo.setFavorite(exerciseId, target);
      ref.invalidate(favoriteExercisesProvider);
      if (ref.mounted && state.favoritesOnly && !target) {
        state = state.copyWith(items: state.items.where((e) => e.id != exerciseId).toList());
      }
    } catch (_) {
      if (ref.mounted) _replace(exerciseId, (e) => e.copyWith(isFavorite: !target));
      rethrow;
    }
  }

  void _replace(String id, Exercise Function(Exercise) update) {
    if (!ref.mounted) return;
    state = state.copyWith(items: [for (final e in state.items) e.id == id ? update(e) : e]);
  }

  /// Creates the exercise and shows it at the top when it matches the current filter.
  /// Throws a Failure — the caller (add sheet) shows the error.
  Future<Exercise> addExercise(CreateExerciseRequest req) async {
    final created = await _repo.createExercise(req);
    final filter = state.categoryFilter;
    final query = state.query.trim().toLowerCase();
    final matches = (filter == null || filter == created.category) &&
        (query.isEmpty || created.name.toLowerCase().contains(query));
    if (matches && ref.mounted) {
      state = state.copyWith(items: [created, ...state.items.where((e) => e.id != created.id)]);
    }
    return created;
  }
}

final exercisesProvider =
    NotifierProvider.autoDispose<ExercisesNotifier, ExercisesState>(ExercisesNotifier.new);

/// Starred exercises for the "Today" quick log. Refreshed whenever a star changes.
/// The last list is kept on the phone: opened without a connection (basement gym),
/// Today still offers quick logging, which then goes to the offline queue.
final favoriteExercisesProvider = FutureProvider.autoDispose<List<Exercise>>(
  (ref) async {
    try {
      final favorites = await ref.watch(exerciseRepositoryProvider).getExercises(favoritesOnly: true, pageSize: 100);
      // Best effort, in the background — the list is shown without waiting for storage.
      unawaited(SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(StorageKeys.favoritesCache, jsonEncode(favorites.map((e) => e.toJson()).toList())),
      ));
      return favorites;
    } catch (e) {
      if (!isOfflineFailure(e)) rethrow;
      final cached = (await SharedPreferences.getInstance()).getString(StorageKeys.favoritesCache);
      if (cached == null) rethrow;
      return (jsonDecode(cached) as List).cast<Map<String, dynamic>>().map(Exercise.fromJson).toList();
    }
  },
  retry: noRetry,
);

/// Persistent notes per exercise (exercise id → note), shown in a workout and in the
/// exercise's history. Empty while offline or with an older API.
final exerciseNotesProvider = AsyncNotifierProvider<ExerciseNotesNotifier, Map<String, String>>(ExerciseNotesNotifier.new);

class ExerciseNotesNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    try {
      return await ref.watch(exerciseRepositoryProvider).getNotes();
    } catch (_) {
      return const {}; // offline / older API: no notes, nothing breaks
    }
  }

  /// Saves the note (empty removes it); the screen shows it at once. Throws a Failure.
  Future<void> set(String exerciseId, String note) async {
    final trimmed = note.trim();
    await ref.read(exerciseRepositoryProvider).setNote(exerciseId, trimmed.isEmpty ? null : trimmed);
    final current = {...?state.value};
    trimmed.isEmpty ? current.remove(exerciseId) : current[exerciseId] = trimmed;
    state = AsyncData(current);
  }
}
