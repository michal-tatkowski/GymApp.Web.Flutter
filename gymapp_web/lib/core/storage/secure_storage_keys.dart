/// Central place for all keys used in FlutterSecureStorage.
/// Avoids typos across the codebase.
class StorageKeys {
  const StorageKeys._();

  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
  static const rememberMe = 'auth.remember_me';

  static const themeMode = 'settings.theme_mode';
  static const locale = 'settings.locale';
}
