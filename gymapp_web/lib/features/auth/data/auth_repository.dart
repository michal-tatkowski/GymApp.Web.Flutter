import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failure.dart';
import 'auth_api.dart';
import 'auth_local_storage.dart';
import 'models/auth_requests.dart';

/// Orchestrates auth API calls + local token storage.
/// Presentation layer should call this class (not [AuthApi] directly).
///
/// Throws [Failure] subclasses — never raw Dio exceptions.
class AuthRepository {
  AuthRepository({required this.api, required this.storage});

  final AuthApi api;
  final AuthLocalStorage storage;

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final tokens = await api.login(LoginRequest(email: email, password: password));
      await storage.saveTokens(tokens, rememberMe: rememberMe);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> register({required String email, required String password}) async {
    try {
      await api.register(RegisterRequest(email: email, password: password));
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    }
  }

  Future<void> logout() async {
    await api.logout();
    await storage.clear();
  }

  /// Restores tokens from secure storage (called on app startup).
  /// Returns true if a valid session was restored.
  Future<bool> restoreSession() async {
    final tokens = await storage.restore();
    return tokens != null;
  }
}
