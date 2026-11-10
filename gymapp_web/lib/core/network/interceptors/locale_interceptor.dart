import 'package:dio/dio.dart';

/// Sends the language chosen in the app (not the browser/OS one) as
/// `Accept-Language`, so API error messages match the UI language.
///
/// The API supports `pl` and `en` and falls back to Polish otherwise.
/// [languageCode] is read on every request, so changing the language in
/// settings takes effect immediately without rebuilding Dio.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this.languageCode);

  final String Function() languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = languageCode();
    handler.next(options);
  }
}
