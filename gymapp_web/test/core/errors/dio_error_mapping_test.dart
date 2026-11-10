import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/exceptions.dart';
import 'package:gymapp_web/core/errors/failure.dart';

DioException _response(int status, dynamic data) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('ProblemDetails title and code are kept', () {
    final failure = mapDioErrorToFailure(_response(409, {
      'status': 409,
      'title': 'Użytkownik z takim e-mailem już istnieje.',
      'code': 'UserAlreadyExists',
    }));

    expect(failure, isA<ConflictFailure>());
    expect(failure.serverMessage, 'Użytkownik z takim e-mailem już istnieje.');
    expect(failure.code, 'UserAlreadyExists');
  });

  test('status codes map to failure types', () {
    expect(mapDioErrorToFailure(_response(400, {'title': 'x'})), isA<ValidationFailure>());
    expect(mapDioErrorToFailure(_response(401, {'title': 'x'})), isA<UnauthorizedFailure>());
    expect(mapDioErrorToFailure(_response(403, {'title': 'x'})), isA<ForbiddenFailure>());
    expect(mapDioErrorToFailure(_response(404, {'title': 'x'})), isA<NotFoundFailure>());
    expect(mapDioErrorToFailure(_response(429, '')), isA<RateLimitedFailure>());
    expect(mapDioErrorToFailure(_response(500, {'title': 'x'})), isA<ServerFailure>());
  });

  test('model validation errors: first field message instead of the generic title', () {
    final failure = mapDioErrorToFailure(_response(400, {
      'title': 'One or more validation errors occurred.',
      'errors': {
        'height': ['The JSON value could not be converted to System.Decimal.'],
      },
    })) as ValidationFailure;

    expect(failure.serverMessage, 'The JSON value could not be converted to System.Decimal.');
    expect(failure.fieldErrors.keys, ['height']);
  });

  test('5xx does not expose server text, HTML bodies are ignored', () {
    expect(mapDioErrorToFailure(_response(500, {'title': 'NullReferenceException at ...'})).serverMessage, isNull);
    expect(mapDioErrorToFailure(_response(400, '<html>Bad gateway</html>')).serverMessage, isNull);
  });

  test('transport errors', () {
    final o = RequestOptions(path: '/x');
    expect(mapDioErrorToFailure(DioException.connectionError(requestOptions: o, reason: 'x')), isA<NetworkFailure>());
    expect(mapDioErrorToFailure(DioException.receiveTimeout(timeout: Duration.zero, requestOptions: o)), isA<TimeoutFailure>());
  });
}
