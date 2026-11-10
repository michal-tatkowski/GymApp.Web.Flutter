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
}
