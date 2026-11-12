import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/exceptions.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/core/network/offline_cache.dart';
import 'package:gymapp_web/core/widgets/offline_data_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// Answers from [replies] (path → JSON), or fails like a phone without signal.
class _Adapter implements HttpClientAdapter {
  final replies = <String, Object>{};
  bool offline = false;
  int status = 200;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    if (offline) throw DioException.connectionError(requestOptions: options, reason: 'no signal');
    return ResponseBody.fromString(jsonEncode(replies[options.path] ?? {}), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  (Dio, _Adapter, List<DateTime>, List<String>) client() {
    final adapter = _Adapter();
    final served = <DateTime>[];
    final events = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://api/', validateStatus: (s) => s != null && s < 400))
      ..httpClientAdapter = adapter
      ..interceptors.add(OfflineCacheInterceptor(
        cache: PrefsResponseCache(),
        onServedFromCache: served.add,
        onOnline: () => events.add('online'),
      ));
    return (dio, adapter, served, events);
  }

  test('offline GET gets the last saved reply, marked as such', () async {
    final (dio, adapter, served, events) = client();
    adapter.replies['Plans'] = [
      {'id': 'p1'},
    ];
    await dio.get<dynamic>('Plans');
    await Future<void>.delayed(Duration.zero); // the write is not awaited by the request
    expect(events, ['online']);

    adapter.offline = true;
    final res = await dio.get<dynamic>('Plans');

    expect(res.data, [
      {'id': 'p1'},
    ]);
    expect(res.extra[OfflineCacheInterceptor.fromCacheKey], isA<DateTime>());
    expect(served, hasLength(1));
  });

  test('nothing saved, a server error or a write → the error goes through', () async {
    final (dio, adapter, served, _) = client();
    adapter.offline = true;
    Future<Failure> failure(Future<void> Function() call) async {
      try {
        await call();
        fail('expected an error');
      } on DioException catch (e) {
        return mapDioErrorToFailure(e);
      }
    }

    expect(await failure(() => dio.get<dynamic>('Workouts')), isA<NetworkFailure>());
    expect(await failure(() => dio.post<dynamic>('Workouts', data: {})), isA<NetworkFailure>());

    adapter
      ..offline = false
      ..replies['Profile'] = {'nickname': 'Jan'};
    await dio.get<dynamic>('Profile');
    await Future<void>.delayed(Duration.zero);
    adapter.status = 500;
    expect(await failure(() => dio.get<dynamic>('Profile')), isA<ServerFailure>()); // real problems are not hidden
    expect(served, isEmpty);
  });

  test('the key includes the language and the query', () async {
    final (dio, adapter, _, _) = client();
    adapter.replies['Exercise'] = [
      {'name': 'Bench press'},
    ];
    await dio.get<dynamic>('Exercise', queryParameters: {'search': 'be'}, options: Options(headers: {'Accept-Language': 'en'}));
    await Future<void>.delayed(Duration.zero);
    adapter.offline = true;

    final same = await dio.get<dynamic>('Exercise', queryParameters: {'search': 'be'}, options: Options(headers: {'Accept-Language': 'en'}));
    expect(same.data, isNotEmpty);
    expect(
      () => dio.get<dynamic>('Exercise', queryParameters: {'search': 'be'}, options: Options(headers: {'Accept-Language': 'pl'})),
      throwsA(isA<DioException>()),
    );
    expect(() => dio.get<dynamic>('Exercise', queryParameters: {'search': 'sq'}), throwsA(isA<DioException>()));
  });

  test('keeps only the newest entries, skips oversized ones, clear removes everything', () async {
    final cache = PrefsResponseCache(maxEntries: 2, maxChars: 100);
    await cache.write('a', 1);
    await cache.write('b', 2);
    await cache.write('c', 3);
    await cache.write('big', 'x' * 200);

    expect(await cache.read('a'), isNull); // evicted
    expect((await cache.read('c'))!.data, 3);
    expect(await cache.read('big'), isNull);

    await cache.clear();
    expect(await cache.read('b'), isNull);
    expect((await SharedPreferences.getInstance()).getKeys().where((k) => k.startsWith('http_cache')), isEmpty);
  });

  testWidgets('the bar shows while saved data is on screen and goes away online', (tester) async {
    await pumpScreen(tester, const Scaffold(body: OfflineDataBar()));
    final c = ProviderScope.containerOf(tester.element(find.byType(OfflineDataBar)));
    expect(find.byKey(const Key('offline.bar')), findsNothing);

    final now = DateTime.now();
    c.read(offlineDataProvider.notifier).servedFromCache(DateTime(now.year, now.month, now.day, 14, 5));
    await tester.pump();
    expect(find.textContaining('showing data saved 14:05'), findsOneWidget);

    c.read(offlineDataProvider.notifier).online();
    await tester.pump();
    expect(find.byKey(const Key('offline.bar')), findsNothing);
  });
}
