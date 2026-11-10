import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/retry.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../data/models/update_profile_request.dart';
import '../data/models/user_profile.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(api: ref.watch(profileApiProvider)),
);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new, retry: noRetry);

/// Errors are not swallowed: a failed load is an AsyncError with the real
/// Failure (network, 401, 404…), so the screen can say what went wrong.
class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.read(profileRepositoryProvider).getProfile();

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(profileRepositoryProvider).getProfile());
  }

  /// Returns null on success, the error otherwise. The state is not touched while
  /// saving (the screen shows its own progress) and stays unchanged on failure,
  /// so the edit form is not replaced by a spinner or an error view.
  Future<Object?> save(UpdateProfileRequest req) async {
    try {
      final updated = await ref.read(profileRepositoryProvider).updateProfile(req);
      if (ref.mounted) state = AsyncData(updated);
      return null;
    } catch (e) {
      return e;
    }
  }
}
