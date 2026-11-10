import 'package:dio/dio.dart';

import 'failure.dart';

/// Converts any Dio error into a domain [Failure].
/// User-facing texts live in l10n (`describeError`), not here.
///
/// API errors are ProblemDetails (application/problem+json):
/// `{ "status": 409, "title": "<localized message>", "code": "UserAlreadyExists" }`
/// ASP.NET model validation errors additionally carry `errors: { field: [messages] }`.
Failure mapDioErrorToFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const CancelledFailure();
    case DioExceptionType.badCertificate:
      return const BadCertificateFailure();
    case DioExceptionType.badResponse:
      return _fromResponse(error.response?.statusCode ?? -1, error.response?.data);
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}

Failure _fromResponse(int status, dynamic data) {
  final problem = data is Map ? data : const {};
  final code = problem['code']?.toString();
  final fieldErrors = _fieldErrors(problem['errors']);
  // Model validation: the title is a generic English sentence — the field message is more useful.
  final message = fieldErrors.isNotEmpty ? fieldErrors.values.first : _message(data);

  return switch (status) {
    400 || 422 => ValidationFailure(message, code, fieldErrors),
    401 => UnauthorizedFailure(message, code),
    403 => ForbiddenFailure(message, code),
    404 => NotFoundFailure(message, code),
    409 => ConflictFailure(message, code),
    429 => const RateLimitedFailure(),
    _ => ServerFailure(status >= 500 ? null : message, status, code), // 5xx: no internals in the UI
  };
}

String? _message(dynamic data) {
  if (data is Map) return (data['title'] ?? data['message'] ?? data['error'])?.toString();
  if (data is String && data.trim().isNotEmpty && !data.trimLeft().startsWith('<')) return data;
  return null;
}

Map<String, String> _fieldErrors(dynamic errors) {
  if (errors is! Map) return const {};
  return {
    for (final entry in errors.entries)
      if (entry.value is List && (entry.value as List).isNotEmpty)
        entry.key.toString(): (entry.value as List).first.toString(),
  };
}
