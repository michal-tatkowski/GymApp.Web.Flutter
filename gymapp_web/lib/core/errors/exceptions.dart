import 'package:dio/dio.dart';

import 'failure.dart';

/// Raw exception type used inside the data layer.
/// Data sources throw [ApiException], repositories catch and map to [Failure].
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int statusCode;
  final String message;
  final Object? data;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Converts any Dio error into a domain [Failure].
/// User-facing texts live in l10n (`describeError`), not here.
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
      final status = error.response?.statusCode ?? -1;
      final serverMessage = _extractMessage(error.response?.data);
      if (status == 401) return UnauthorizedFailure(serverMessage);
      if (status == 422 || status == 400) return ValidationFailure(serverMessage);
      return ServerFailure(serverMessage, status);
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map) {
    return (data['message'] ?? data['error'] ?? data['title'])?.toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
