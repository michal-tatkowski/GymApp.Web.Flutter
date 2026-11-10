import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/network/interceptors/locale_interceptor.dart';

/// Captures outgoing request headers instead of hitting the network.
class _CapturingAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> sentHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sentHeaders.add(Map.of(options.headers));
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends the current app language as Accept-Language on every request', () async {
    var language = 'pl';
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(LocaleInterceptor(() => language));

    await dio.get('/a');
    language = 'en'; // user switches language in settings
    await dio.get('/b');

    expect(adapter.sentHeaders[0]['Accept-Language'], 'pl');
    expect(adapter.sentHeaders[1]['Accept-Language'], 'en');
  });
}
