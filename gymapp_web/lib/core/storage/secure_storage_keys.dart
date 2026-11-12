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
  static const restTimerSeconds = 'settings.rest_timer_seconds';
  static const weightUnit = 'settings.weight_unit';
  static const reminders = 'settings.reminders';

  /// Workouts logged without a connection (JSON list), see PendingWorkouts.
  static const pendingWorkouts = 'workouts.pending';

  /// Last favorites list (JSON), so Today works offline.
  static const favoritesCache = 'exercises.favorites_cache';

  /// Last plans list (JSON), so a plan can be started offline.
  static const plansCache = 'plans.cache';

  /// Live workout session in progress (JSON), survives closing the app.
  static const activeSession = 'session.active';

  /// Badges earned on this device (JSON id → date), see EarnedBadges.
  static const earnedBadges = 'badges.earned';
}
