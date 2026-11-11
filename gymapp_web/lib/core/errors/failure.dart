/// Domain-level error representation, safe to show to the user.
///
/// Use [Failure] in presentation/state layers — never throw raw [Exception]s
/// out of repositories. Convert low-level exceptions (Dio, Socket, etc.) to
/// [Failure] in the data layer.
///
/// [serverMessage] is the (already localized, via Accept-Language) message
/// from the API. When it is missing the UI shows a localized default for the
/// failure type — see `describeError` in `failure_messages.dart`.
/// [code] is the API's stable error code (ProblemDetails `code`, e.g.
/// `UserAlreadyExists`) — use it for logic, never the message text.
sealed class Failure {
  const Failure({this.serverMessage, this.code});

  final String? serverMessage;
  final String? code;

  @override
  String toString() => '$runtimeType(${code ?? ''} ${serverMessage ?? ''})';
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class BadCertificateFailure extends Failure {
  const BadCertificateFailure();
}

class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

class CancelledFailure extends Failure {
  const CancelledFailure();
}

/// 401 — wrong credentials or expired session.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String? serverMessage, String? code])
      : super(serverMessage: serverMessage, code: code);
}

/// 403 — e.g. inactive account.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String? serverMessage, String? code])
      : super(serverMessage: serverMessage, code: code);
}

/// 404.
class NotFoundFailure extends Failure {
  const NotFoundFailure([String? serverMessage, String? code])
      : super(serverMessage: serverMessage, code: code);
}

/// 409 — e.g. email already registered, duplicate exercise name.
class ConflictFailure extends Failure {
  const ConflictFailure([String? serverMessage, String? code])
      : super(serverMessage: serverMessage, code: code);
}

/// 429 — rate limit (API limits login/register attempts).
class RateLimitedFailure extends Failure {
  const RateLimitedFailure();
}

/// 400 / 422. [fieldErrors]: ASP.NET model validation errors (field → first message).
class ValidationFailure extends Failure {
  const ValidationFailure([String? serverMessage, String? code, this.fieldErrors = const {}])
      : super(serverMessage: serverMessage, code: code);
  final Map<String, String> fieldErrors;
}

/// 5xx and other unexpected responses.
class ServerFailure extends Failure {
  const ServerFailure([String? serverMessage, this.statusCode, String? code])
      : super(serverMessage: serverMessage, code: code);
  final int? statusCode;
}

class UnknownFailure extends Failure {
  const UnknownFailure();
}

/// No connection or no answer — worth trying again later (offline queue, cached
/// data). Anything else (e.g. the server rejects the request) would fail the same
/// way every time.
bool isOfflineFailure(Object e) => e is NetworkFailure || e is TimeoutFailure;
