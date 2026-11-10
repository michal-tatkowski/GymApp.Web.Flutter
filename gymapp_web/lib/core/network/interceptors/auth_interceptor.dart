import 'dart:async';

import 'package:dio/dio.dart';

import '../../../features/auth/data/auth_local_storage.dart';
import '../../logging/app_logger.dart';

/// Attaches the access token to every request and transparently refreshes it
/// when a 401 is returned by the server.
///
/// Contract:
///  - [tokenStorage] persists and retrieves access/refresh tokens.
///  - [refreshTokenCall] POSTs the refresh token to the backend, stores the new
///    pair and returns the new access token (or throws on failure).
///  - [onAuthFailure] is invoked when the session is definitely gone
///    (the server rejected the refresh token) — sign the user out.
///
/// Rules:
///  - Requests marked with [AuthOptions.skipAuth] (login, register, refresh,
///    logout) never get a token and never trigger a refresh — a 401 from login
///    means "wrong password", not "session expired".
///  - A request is retried at most once ([_retriedKey]), so a server that keeps
///    answering 401 cannot cause an endless refresh loop.
///  - Concurrent 401s share one refresh call. A 401 for a token that has
///    already been replaced is simply retried with the current token — the old
///    refresh token was rotated by the API and would be rejected.
///  - Network/server errors during refresh do NOT sign the user out.
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

  Completer<String>? _refreshCompleter;

  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'authRetried';
  static const _sentTokenKey = 'authSentToken';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) return handler.next(options);

    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_sentTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuthKey] == true ||
        options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    try {
      final sentToken = options.extra[_sentTokenKey] as String?;
      final currentToken = await tokenStorage.getAccessToken();

      // Someone else already refreshed while this request was in flight.
      final String newAccessToken;
      if (currentToken != null && currentToken.isNotEmpty && currentToken != sentToken) {
        newAccessToken = currentToken;
      } else {
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await onAuthFailure();
          return handler.next(err);
        }
        newAccessToken = await _refreshAccessToken(refreshToken);
      }

      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      options.extra[_sentTokenKey] = newAccessToken;
      return handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (refreshOrRetryError, st) {
      final refreshRejected = refreshOrRetryError.requestOptions.extra[skipAuthKey] == true &&
          const [400, 401, 403].contains(refreshOrRetryError.response?.statusCode);
      if (refreshRejected) {
        log.w('Refresh token rejected — signing out');
        await onAuthFailure();
        return handler.next(err);
      }
      log.e('Token refresh / retry failed', error: refreshOrRetryError, stackTrace: st);
      return handler.next(refreshOrRetryError);
    } catch (e, st) {
      log.e('Token refresh failed', error: e, stackTrace: st);
      return handler.next(err);
    }
  }

  Future<String> _refreshAccessToken(String refreshToken) {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<String>();
    _refreshCompleter = completer;

    refreshTokenCall(refreshToken)
        .then(completer.complete)
        .catchError((Object e, StackTrace s) => completer.completeError(e, s))
        .whenComplete(() => _refreshCompleter = null);

    return completer.future;
  }
}

/// Helper to mark a request as not requiring auth (login, register, refresh, logout).
extension AuthOptions on Options {
  static Options skipAuth([Options? base]) {
    final extra = Map<String, dynamic>.from(base?.extra ?? {});
    extra[AuthInterceptor.skipAuthKey] = true;
    return (base ?? Options()).copyWith(extra: extra);
  }
}
