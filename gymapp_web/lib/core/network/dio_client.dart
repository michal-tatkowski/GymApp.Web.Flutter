import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import 'interceptors/logging_interceptor.dart';

/// Factory for a configured [Dio] instance.
///
/// Interceptors are attached externally (see [coreProvidersReady] in
/// `core_providers.dart`) so that feature modules (auth) can inject their
/// own logic without creating a circular dependency.
class DioClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.httpTimeout,
        receiveTimeout: AppConfig.httpTimeout,
        sendTimeout: AppConfig.httpTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Let us handle non-2xx in our error interceptor / repository layer.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (AppConfig.enableNetworkLogs) {
      dio.interceptors.add(LoggingInterceptor());
    }

    return dio;
  }
}
