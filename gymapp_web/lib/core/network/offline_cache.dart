import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/exceptions.dart';
import '../errors/failure.dart';

class CachedResponse {
  const CachedResponse({required this.data, required this.savedAt});

  final Object? data;
  final DateTime savedAt;
}

/// Last good JSON reply of each GET, so screens show something without signal.
abstract class ResponseCache {
  Future<CachedResponse?> read(String key);
  Future<void> write(String key, Object? data);
  Future<void> clear();
}

/// On the phone's key-value store (localStorage on web), newest [maxEntries]
/// replies, each at most [maxChars] of JSON — a long history of one exercise is
/// still fine, a runaway reply is simply not kept.
class PrefsResponseCache implements ResponseCache {
  PrefsResponseCache({this.maxEntries = 150, this.maxChars = 200000});

  final int maxEntries;
  final int maxChars;

  static const _prefix = 'http_cache.';
  static const _index = 'http_cache_index';

  @override
  Future<CachedResponse?> read(String key) async {
    final raw = (await SharedPreferences.getInstance()).getString(_prefix + key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return CachedResponse(data: j['d'], savedAt: DateTime.parse(j['t'] as String));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data) async {
    final encoded = jsonEncode({'t': DateTime.now().toIso8601String(), 'd': data});
    if (encoded.length > maxChars) return;
    final prefs = await SharedPreferences.getInstance();
    final index = [...?prefs.getStringList(_index)]
      ..remove(key)
      ..add(key);
    while (index.length > maxEntries) {
      await prefs.remove(_prefix + index.removeAt(0));
    }
    await prefs.setString(_prefix + key, encoded);
    await prefs.setStringList(_index, index);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(key);
    }
    await prefs.remove(_index);
  }
}

final responseCacheProvider = Provider<ResponseCache>((ref) => PrefsResponseCache());

/// When the screens show saved data because there is no connection: the time the
/// oldest such reply was saved. Null = everything shown is live.
final offlineDataProvider = NotifierProvider<OfflineData, DateTime?>(OfflineData.new);

class OfflineData extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void servedFromCache(DateTime savedAt) {
    final current = state;
    if (current == null || savedAt.isBefore(current)) state = savedAt;
  }

  void online() {
    if (state != null) state = null;
  }
}

/// Saves every successful GET; when a GET fails for lack of connection, answers
/// with the saved reply instead (marked in [Response.extra] as [fromCacheKey]).
/// Errors from the server itself (4xx/5xx) are passed on — only "no signal"
/// falls back, so stale data never hides a real problem.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({required this.cache, this.onServedFromCache, this.onOnline});

  final ResponseCache cache;
  final void Function(DateTime savedAt)? onServedFromCache;
  final void Function()? onOnline;

  static const fromCacheKey = 'offlineCacheSavedAt';

  static String keyFor(RequestOptions o) => '${o.headers['Accept-Language'] ?? ''}|${o.uri}';

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    onOnline?.call();
    final o = response.requestOptions;
    if (o.method == 'GET' && (response.statusCode ?? 0) < 300) {
      // Not awaited: the screen should not wait for the disk.
      cache.write(keyFor(o), response.data).catchError((_) {});
    }
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    if (o.method != 'GET' || !isOfflineFailure(mapDioErrorToFailure(err))) return handler.next(err);
    final saved = await cache.read(keyFor(o)).catchError((_) => null);
    if (saved == null) return handler.next(err);
    onServedFromCache?.call(saved.savedAt);
    handler.resolve(Response<dynamic>(
      requestOptions: o,
      data: saved.data,
      statusCode: 200,
      extra: {fromCacheKey: saved.savedAt},
    ));
  }
}
