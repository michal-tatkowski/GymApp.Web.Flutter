import 'package:dio/dio.dart';

import '../../../core/network/interceptors/auth_interceptor.dart';
import 'models/auth_requests.dart';
import 'models/auth_tokens.dart';

/// Thin wrapper around Dio for the auth REST endpoints.
/// This is the ONLY place that knows the URL paths for auth.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login(LoginRequest req) async {
    final res = await _dio.post<dynamic>(
      'Auth/Login',
      data: req.toJson(),
      options: AuthOptions.skipAuth(),
    );
    return AuthTokens.fromResponse(res.data);
  }

  Future<void> register(RegisterRequest req) async {
    await _dio.post<dynamic>(
      'Auth/Register',
      data: req.toJson(),
      options: AuthOptions.skipAuth(),
    );
  }

  /// Exchange refresh token for a new access+refresh token pair.
  /// Backend contract: POST /Auth/Refresh { refreshToken } -> { accessToken, refreshToken }
  Future<AuthTokens> refresh(String refreshToken) async {
    final res = await _dio.post<dynamic>(
      'Auth/Refresh',
      data: {'refreshToken': refreshToken},
      options: AuthOptions.skipAuth(),
    );
    return AuthTokens.fromResponse(res.data);
  }

  /// Revokes the refresh token on the server: POST /Auth/Logout { refreshToken }.
  /// Best effort — the client clears its tokens regardless of the outcome.
  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await _dio.post<dynamic>(
        'Auth/Logout',
        data: {'refreshToken': refreshToken},
        options: AuthOptions.skipAuth(),
      );
    } catch (_) {
      // Ignore — client will clear tokens regardless.
    }
  }

  /// Code from the email sent at sign-up → the account is confirmed and signed in (same reply as login).
  Future<AuthTokens> confirmEmail(String email, String code) async {
    final res = await _dio.post<dynamic>(
      'Auth/ConfirmEmail',
      data: {'email': email, 'code': code},
      options: AuthOptions.skipAuth(),
    );
    return AuthTokens.fromResponse(res.data);
  }

  /// Always 200 (the API does not reveal whether the account exists); at most one code per minute.
  Future<void> resendConfirmation(String email) =>
      _dio.post<dynamic>('Auth/ResendConfirmation', data: {'email': email}, options: AuthOptions.skipAuth());

  /// Always 200; emails a code for [resetPassword] if the account exists.
  Future<void> forgotPassword(String email) =>
      _dio.post<dynamic>('Auth/ForgotPassword', data: {'email': email}, options: AuthOptions.skipAuth());

  /// Sets a new password and signs out every session. Bad code → 400 `InvalidCode`.
  Future<void> resetPassword({required String email, required String code, required String newPassword}) =>
      _dio.post<dynamic>(
        'Auth/ResetPassword',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
        options: AuthOptions.skipAuth(),
      );

  /// Permanently deletes the account and all its data: DELETE /Account { password }.
  /// Wrong password → 400 with code `WrongPassword`.
  Future<void> deleteAccount(String password) async {
    await _dio.delete<dynamic>('Account', data: {'password': password});
  }
}
