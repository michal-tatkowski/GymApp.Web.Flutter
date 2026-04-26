import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    AsyncNotifierProvider<ProfileController, UserProfile?>(ProfileController.new);

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return _fetch();
  }

  Future<UserProfile?> _fetch() async {
    try {
      return await ref.read(profileRepositoryProvider).getProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<bool> save(UpdateProfileRequest req) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateProfile(req),
    );
    state = result;
    return result.hasValue && result.value != null;
  }
}
