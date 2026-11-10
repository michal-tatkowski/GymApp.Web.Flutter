/// Compile-time configuration, injected via `--dart-define`.
///
/// Run with overrides:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://api.staging.gymapp.com/api/
/// ```
class AppConfig {
  const AppConfig._();

  /// Base URL for the REST API. MUST end with a trailing `/`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5035/api/',
  );

  /// Request/receive timeout for HTTP calls.
  static const Duration httpTimeout = Duration(seconds: 15);

  /// Whether to log requests (method, URL, status). On by default in debug/profile,
  /// off in release builds; override with --dart-define=ENABLE_NETWORK_LOGS=true|false.
  static const bool enableNetworkLogs = bool.fromEnvironment(
    'ENABLE_NETWORK_LOGS',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );
}
