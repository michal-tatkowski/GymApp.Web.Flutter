import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Lightweight request/response logger. Avoid logging auth headers/bodies
/// in production — switch via AppConfig.enableNetworkLogs.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log.d(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.w(
      '✗ ${err.response?.statusCode ?? '-'} '
      '${err.requestOptions.method} ${err.requestOptions.uri}  '
      '${err.type.name}',
    );
    handler.next(err);
  }
}
