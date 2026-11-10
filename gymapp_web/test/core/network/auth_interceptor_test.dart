import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/network/interceptors/auth_interceptor.dart';
import 'package:gymapp_web/features/auth/data/auth_local_storage.dart';
import 'package:gymapp_web/features/auth/data/models/auth_tokens.dart';

/// In-memory token storage (the real one needs the secure storage plugin).
class _MemoryStorage extends AuthLocalStorage {
  _MemoryStorage(this.access, this.refresh);

  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens(AuthTokens tokens, {required bool rememberMe}) async {
    access = tokens.accessToken;
    refresh = tokens.refreshToken;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    access = null;
    refresh = null;
  }
}

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

/// API stub: tokens "fresh-N" are valid, "expired" is not. Refresh works for [validRefresh] only.
class _Api {
  _Api({this.validRefresh = 'refresh-1', this.refreshDelay = Duration.zero, this.refreshStatus});

  final String validRefresh;
  final Duration refreshDelay;
  final int? refreshStatus;
  int refreshCalls = 0;

  Future<ResponseBody> handle(RequestOptions o) async {
    if (o.path.endsWith('Auth/Refresh')) {
      refreshCalls++;
      await Future<void>.delayed(refreshDelay);
      if (refreshStatus != null) return _json(refreshStatus!, {'title': 'nope'});
      final body = o.data as Map;
      if (body['refreshToken'] != validRefresh) return _json(401, {'code': 'InvalidRefreshToken'});
      return _json(200, {'accessToken': 'fresh-$refreshCalls', 'refreshToken': 'refresh-${refreshCalls + 1}'});
    }
    if (o.path.endsWith('Auth/Login')) return _json(401, {'code': 'InvalidCredentials', 'title': 'Wrong password'});
    final auth = o.headers['Authorization'] as String?;
    if (auth != null && auth.startsWith('Bearer fresh-')) return _json(200, {'ok': true});
    return _json(401, {'title': 'Unauthorized'});
  }
}

({Dio dio, _FakeAdapter adapter, _MemoryStorage storage, List<String> events}) _setup(
  _Api api, {
  String? access = 'expired',
  String? refresh = 'refresh-1',
  bool alwaysUnauthorized = false,
}) {
  final storage = _MemoryStorage(access, refresh);
  final events = <String>[];
  final adapter = _FakeAdapter(alwaysUnauthorized
      ? (o) async => o.path.endsWith('Auth/Refresh') ? api.handle(o) : _json(401, {})
      : api.handle);

  final refreshDio = Dio(BaseOptions(baseUrl: 'http://api.test/'))..httpClientAdapter = adapter;
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/'))..httpClientAdapter = adapter;
  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    tokenStorage: storage,
    refreshTokenCall: (refreshToken) async {
      final res = await refreshDio.post<dynamic>('Auth/Refresh',
          data: {'refreshToken': refreshToken}, options: AuthOptions.skipAuth());
      final tokens = AuthTokens.fromResponse(res.data);
      storage.access = tokens.accessToken;
      storage.refresh = tokens.refreshToken;
      return tokens.accessToken;
    },
    onAuthFailure: () async {
      events.add('logout');
      await storage.clear();
    },
  ));
  return (dio: dio, adapter: adapter, storage: storage, events: events);
}

void main() {
  test('401 → refresh → original request retried with the new token', () async {
    final api = _Api();
    final s = _setup(api);

    final res = await s.dio.get<dynamic>('Profile');

    expect(res.statusCode, 200);
    expect(api.refreshCalls, 1);
    expect(s.storage.access, 'fresh-1');
    expect(s.adapter.requests.last.headers['Authorization'], 'Bearer fresh-1');
    expect(s.events, isEmpty);
  });

  test('concurrent 401s share a single refresh call', () async {
    final api = _Api(refreshDelay: const Duration(milliseconds: 50));
    final s = _setup(api);

    final results = await Future.wait(List.generate(5, (_) => s.dio.get<dynamic>('Profile')));

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(api.refreshCalls, 1);
  });

  test('401 for an already replaced token is retried without another refresh', () async {
    final api = _Api();
    late _MemoryStorage storage;
    final s = _setup(api);
    storage = s.storage;
    // While the request with "expired" is in flight, another request finishes a refresh
    // (stores "fresh-0" and rotates the refresh token, so the old one would be rejected).
    s.dio.httpClientAdapter = _FakeAdapter((o) async {
      if (o.path == 'Profile' && o.headers['Authorization'] == 'Bearer expired') {
        storage.access = 'fresh-0';
        storage.refresh = 'rotated';
        return _json(401, {});
      }
      return api.handle(o);
    });

    final res = await s.dio.get<dynamic>('Profile');

    expect(res.statusCode, 200);
    expect(api.refreshCalls, 0);
    expect(s.events, isEmpty);
  });

  test('login 401 is passed through: no refresh, no logout', () async {
    final api = _Api();
    final s = _setup(api, access: null, refresh: 'refresh-1');

    final future = s.dio.post<dynamic>('Auth/Login', data: {}, options: AuthOptions.skipAuth());

    await expectLater(future, throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)));
    expect(api.refreshCalls, 0);
    expect(s.events, isEmpty);
    expect(s.adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('rejected refresh token signs the user out', () async {
    final api = _Api(validRefresh: 'something-else');
    final s = _setup(api);

    await expectLater(s.dio.get<dynamic>('Profile'), throwsA(isA<DioException>()));

    expect(s.events, ['logout']);
    expect(s.storage.cleared, isTrue);
  });

  test('server error during refresh does NOT sign the user out', () async {
    final api = _Api(refreshStatus: 503);
    final s = _setup(api);

    await expectLater(s.dio.get<dynamic>('Profile'), throwsA(isA<DioException>()));

    expect(s.events, isEmpty);
    expect(s.storage.refresh, 'refresh-1');
  });

  test('a request is retried at most once (no refresh loop)', () async {
    final api = _Api();
    final s = _setup(api, alwaysUnauthorized: true);

    await expectLater(s.dio.get<dynamic>('Profile'), throwsA(isA<DioException>()));

    expect(api.refreshCalls, 1);
    expect(s.adapter.requests.where((r) => r.path == 'Profile').length, 2);
  });

  test('missing refresh token signs the user out without calling the API', () async {
    final api = _Api();
    final s = _setup(api, refresh: null);

    await expectLater(s.dio.get<dynamic>('Profile'), throwsA(isA<DioException>()));

    expect(api.refreshCalls, 0);
    expect(s.events, ['logout']);
  });
}
