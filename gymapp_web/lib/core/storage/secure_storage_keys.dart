/// Central place for storage keys used across the app.
/// Avoids typos across the codebase.
class StorageKeys {
  const StorageKeys._();

  // Secure storage (flutter_secure_storage)
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
  static const rememberMe = 'auth.remember_me';

  // Shared preferences (shared_preferences)
  static const themeMode = 'settings.theme_mode';
  static const locale = 'settings.locale';
}
