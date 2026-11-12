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
    } on FormatException {
      throw const ServerFailure();
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
    await api.logout(await storage.getRefreshToken());
    await storage.clear();
  }

  Future<void> confirmEmail({required String email, required String code, required bool rememberMe}) =>
      _guard(() async {
        final tokens = await api.confirmEmail(email, code);
        await storage.saveTokens(tokens, rememberMe: rememberMe);
      });

  Future<void> resendConfirmation(String email) => _guard(() => api.resendConfirmation(email));

  Future<void> forgotPassword(String email) => _guard(() => api.forgotPassword(email));

  Future<void> resetPassword({required String email, required String code, required String newPassword}) =>
      _guard(() => api.resetPassword(email: email, code: code, newPassword: newPassword));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException {
      throw const ServerFailure();
    }
  }

  /// Deletes the account on the server, then forgets the tokens (they are
  /// already invalid). Throws [Failure] — e.g. [ValidationFailure] with code
  /// `WrongPassword`; the tokens stay so the user can try again.
  Future<void> deleteAccount(String password) async {
    try {
      await api.deleteAccount(password);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    }
    await storage.clear();
  }

  /// Restores tokens from secure storage (called on app startup).
  /// Returns true if a valid session was restored.
  Future<bool> restoreSession() async {
    final tokens = await storage.restore();
    return tokens != null;
  }
}
