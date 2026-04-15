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
Failure mapDioErrorToFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const UnknownFailure('Żądanie zostało anulowane.');
    case DioExceptionType.badCertificate:
      return const NetworkFailure('Nieprawidłowy certyfikat serwera.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? -1;
      final data = error.response?.data;
      final serverMessage = _extractMessage(data);
      if (status == 401) return UnauthorizedFailure(serverMessage ?? 'Sesja wygasła.');
      if (status == 422 || status == 400) {
        return ValidationFailure(serverMessage ?? 'Nieprawidłowe dane.');
      }
      return ServerFailure(
        serverMessage ?? 'Błąd serwera ($status).',
        statusCode: status,
      );
    case DioExceptionType.unknown:
      return UnknownFailure(error.message ?? 'Nieoczekiwany błąd.');
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map) {
    return (data['message'] ?? data['error'] ?? data['title'])?.toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
