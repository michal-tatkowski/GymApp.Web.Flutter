import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../../../core/network/interceptors/locale_interceptor.dart';
import '../../settings/presentation/settings_providers.dart';
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

  // API error messages follow the app language. `read`, not `watch`:
  // a language change must not rebuild Dio (and drop in-flight state).
  String currentLanguage() => ref.read(localeProvider).languageCode;
  dio.interceptors.add(LocaleInterceptor(currentLanguage));

  // Separate Dio for refresh calls so the refresh request itself never
  // triggers the auth interceptor (which would cause recursion).
  final refreshDio = DioClient.create()
    ..interceptors.add(LocaleInterceptor(currentLanguage));
  final refreshApi = AuthApi(refreshDio);

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: storage,
      refreshTokenCall: (refreshToken) async {
        final tokens = await refreshApi.refresh(refreshToken);
        await storage.updateAccessToken(tokens.accessToken);
        if (tokens.hasRefreshToken) {
          await storage.saveRefreshToken(tokens.refreshToken!);
        }
        return tokens.accessToken;
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

  /// Throws [Failure] (e.g. code `InvalidCode`) without touching the state, so
  /// the code screen shows the error in place; success signs in.
  Future<void> confirmEmail({required String email, required String code, required bool rememberMe}) async {
    await ref.read(authRepositoryProvider).confirmEmail(email: email, code: code, rememberMe: rememberMe);
    state = const AsyncData(AuthState.authenticated);
  }

  /// Throws [Failure] and stays logged in when the server refuses (e.g. wrong password).
  Future<void> deleteAccount(String password) async {
    await ref.read(authRepositoryProvider).deleteAccount(password);
    state = const AsyncData(AuthState.unauthenticated);
  }

  /// Called by the auth interceptor when refresh fails.
  void forceLogout() {
    state = const AsyncData(AuthState.unauthenticated);
  }
}
