import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// User-facing text for any error caught in the presentation layer.
///
/// Prefers the API's own message (it already follows the app language thanks
/// to the Accept-Language header) and falls back to a localized default.
String describeError(AppLocalizations t, Object? error) {
  if (error is! Failure) return t.errUnknown;

  final server = error.serverMessage;
  if (server != null && server.trim().isNotEmpty) return server;

  return switch (error) {
    NetworkFailure() => t.errNetwork,
    BadCertificateFailure() => t.errBadCertificate,
    TimeoutFailure() => t.errTimeout,
    CancelledFailure() => t.errCancelled,
    UnauthorizedFailure() => t.errSessionExpired,
    ForbiddenFailure() => t.errForbidden,
    NotFoundFailure() => t.errNotFound,
    ConflictFailure() => t.errConflict,
    RateLimitedFailure() => t.errTooManyRequests,
    ValidationFailure() => t.errValidation,
    ServerFailure(statusCode: final int status) => t.errServer(status),
    ServerFailure() => t.errUnknown, // np. nieczytelna odpowiedź serwera
    UnknownFailure() => t.errUnknown,
  };
}
