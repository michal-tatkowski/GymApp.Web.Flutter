/// Route path and name constants. Use these instead of hardcoded strings.
class AppRoutes {
  const AppRoutes._();

  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';

  /// Reachable without signing in.
  static const signedOut = {login, register, verifyEmail, forgotPassword};

  // Tabs of the bottom navigation (AppShell)
  static const today = '/today';
  static const exercises = '/exercises';
  static const progress = '/progress';
  static const profile = '/profile';

  /// Start page after login.
  static const home = today;

  // Full-screen pages on top of the tabs
  static const settings = '/settings';
}
