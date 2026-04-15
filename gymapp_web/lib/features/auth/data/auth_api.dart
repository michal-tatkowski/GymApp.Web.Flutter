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

  /// Exchange refresh token for a new access token.
  /// Backend contract expected: POST /Auth/Refresh { refreshToken } -> { accessToken }
  Future<String> refresh(String refreshToken) async {
    final res = await _dio.post<dynamic>(
      'Auth/Refresh',
      data: {'refreshToken': refreshToken},
      options: AuthOptions.skipAuth(),
    );
    final data = res.data;
    if (data is Map && data['accessToken'] is String) {
      return data['accessToken'] as String;
    }
    if (data is String && data.isNotEmpty) return data;
    throw const FormatException(
      'Brak accessToken w odpowiedzi z /Auth/Refresh.',
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('Auth/Logout');
    } catch (_) {
      // Ignore — client will clear tokens regardless.
    }
  }
}
