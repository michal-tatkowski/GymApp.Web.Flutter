import 'package:flutter/foundation.dart';

/// Compile-time configuration, injected via `--dart-define`.
///
/// ```
/// # Android emulator / iOS simulator / web against the API on this computer: nothing to pass.
/// flutter run
///
/// # Physical phone on the same Wi-Fi (API listens on 0.0.0.0:5035):
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5035/api/
///
/// # Staging / production:
/// flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com/api/
/// ```
class AppConfig {
  const AppConfig._();

  static const _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  /// Base URL for the REST API, always ending with `/`.
  static String get apiBaseUrl =>
      resolveApiBaseUrl(fromEnv: _apiBaseUrlFromEnv, isWeb: kIsWeb, platform: defaultTargetPlatform);

  /// `--dart-define=API_BASE_URL` wins. Otherwise the local development API:
  /// the Android emulator reaches the host computer at 10.0.2.2 ("localhost" there
  /// is the emulator itself); web, desktop and the iOS simulator use localhost.
  @visibleForTesting
  static String resolveApiBaseUrl({required String fromEnv, required bool isWeb, required TargetPlatform platform}) {
    final url = fromEnv.isNotEmpty
        ? fromEnv
        : (!isWeb && platform == TargetPlatform.android)
            ? 'http://10.0.2.2:5035/api/'
            : 'http://localhost:5035/api/';
    return url.endsWith('/') ? url : '$url/';
  }

  /// Request/receive timeout for HTTP calls.
  static const Duration httpTimeout = Duration(seconds: 15);

  /// Whether to log requests (method, URL, status). On by default in debug/profile,
  /// off in release builds; override with --dart-define=ENABLE_NETWORK_LOGS=true|false.
  static const bool enableNetworkLogs = bool.fromEnvironment(
    'ENABLE_NETWORK_LOGS',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );
}
