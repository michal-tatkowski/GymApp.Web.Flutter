import 'dart:async';

import 'package:dio/dio.dart';

import '../../../features/auth/data/auth_local_storage.dart';
import '../../logging/app_logger.dart';

/// Attaches the access token to every request and transparently refreshes it
/// when a 401 is returned by the server.
///
/// Contract:
///  - [tokenStorage] persists and retrieves access/refresh tokens.
///  - [refreshTokenCall] is a callback that POSTs the refresh token to the
///    backend and returns the new access token (or throws on failure).
///  - [onAuthFailure] is invoked when refresh fails (sign the user out).
///
/// The interceptor is decoupled from the repository layer to keep the core/
/// layer free of auth feature imports other than the token storage.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshTokenCall,
    required this.onAuthFailure,
    required this.dio,
  });

  final AuthLocalStorage tokenStorage;
  final Future<String> Function(String refreshToken) refreshTokenCall;
  final Future<void> Function() onAuthFailure;
  final Dio dio;

  // Serialize refresh attempts — if many requests 401 at once, only refresh once.
  Completer<String>? _refreshCompleter;

  static const _skipAuthHeader = 'x-skip-auth';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers.remove(_skipAuthHeader) != null) {
      return handler.next(options);
    }
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;
    final isRefreshCall = requestPath.contains('Auth/Refresh');

    if (statusCode != 401 || isRefreshCall) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await onAuthFailure();
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshAccessToken(refreshToken);
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } catch (refreshError, st) {
      log.e('Token refresh failed', error: refreshError, stackTrace: st);
      await onAuthFailure();
      return handler.next(err);
    }
  }

  Future<String> _refreshAccessToken(String refreshToken) {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<String>();
    _refreshCompleter = completer;

    refreshTokenCall(refreshToken)
        .then((token) => completer.complete(token))
        .catchError((Object e, StackTrace s) => completer.completeError(e, s))
        .whenComplete(() => _refreshCompleter = null);

    return completer.future;
  }
}

/// Helper to mark a request as not requiring auth (e.g., login, register).
extension AuthOptions on Options {
  static Options skipAuth([Options? base]) {
    final headers = Map<String, dynamic>.from(base?.headers ?? {});
    headers['x-skip-auth'] = true;
    return (base ?? Options()).copyWith(headers: headers);
  }
}
