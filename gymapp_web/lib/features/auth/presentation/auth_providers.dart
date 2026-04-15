import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../data/auth_api.dart';
import '../data/auth_local_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// ─── Infrastructure providers ────────────────────────────────────────────

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return AuthLocalStorage();
});

/// Dio instance with auth interceptor wired in.
/// The interceptor needs a reference to the repository for refresh calls,
/// so we build it lazily after the repository provider is in place.
final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  final storage = ref.watch(authLocalStorageProvider);

  // Separate Dio for refresh calls so the refresh request itself never
  // triggers the auth interceptor (which would cause recursion).
  final refreshDio = DioClient.create();
  final refreshApi = AuthApi(refreshDio);

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: storage,
      refreshTokenCall: (refreshToken) async {
        final newAccess = await refreshApi.refresh(refreshToken);
        await storage.updateAccessToken(newAccess);
        return newAccess;
      },
      onAuthFailure: () async {
        await storage.clear();
        // Flip auth state to unauthenticated; router will redirect to /login.
        ref.read(authControllerProvider.notifier).forceLogout();
      },
    ),
  );

  return dio;
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(authLocalStorageProvider),
  );
});

/// ─── Auth state ──────────────────────────────────────────────────────────

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final restored = await repo.restoreSession();
    return restored ? AuthState.authenticated : AuthState.unauthenticated;
  }

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
            rememberMe: rememberMe,
          );
      return AuthState.authenticated;
    });
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
          );
      // Registration does NOT auto-login; user enters credentials after.
      return AuthState.unauthenticated;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState.unauthenticated);
  }

  /// Called by the auth interceptor when refresh fails.
  void forceLogout() {
    state = const AsyncData(AuthState.unauthenticated);
  }
}
