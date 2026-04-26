import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/gym/gym_screen.dart';
import '../features/gym/weekly_plan/weekly_plan_screen.dart';
import '../features/home/home_menu.dart';
import '../features/info/info_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/social/social_screen.dart';
import 'app_routes.dart';

/// Builds a [GoRouter] wired to Riverpod auth state.
///
/// Unauthenticated users are redirected to /login. While auth state is loading
/// (e.g., restoring session from secure storage on app start), the router
/// shows /splash instead of letting the user see protected screens.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AsyncValue<AuthState>>(
    ref.read(authControllerProvider),
  );
  ref.onDispose(authListenable.dispose);
  ref.listen<AsyncValue<AuthState>>(
    authControllerProvider,
    (_, next) => authListenable.value = next,
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final here = state.matchedLocation;

      // No value yet = initial session restore in progress → show splash.
      // Do NOT redirect to splash during login/register (isLoading + hasValue),
      // so the user stays on the auth screen while the request is in flight.
      if (!auth.hasValue) {
        return here == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Once we have a value, always leave splash immediately.
      final isAuthed = auth.value == AuthState.authenticated;
      if (here == AppRoutes.splash) {
        return isAuthed ? AppRoutes.home : AppRoutes.login;
      }

      final isOnAuthRoute =
          here == AppRoutes.login || here == AppRoutes.register;

      if (!isAuthed && !isOnAuthRoute) return AppRoutes.login;
      if (isAuthed && isOnAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeMenu()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.gym, builder: (_, __) => const GymScreen()),
      GoRoute(path: AppRoutes.gymWeeklyPlan, builder: (_, __) => const WeeklyPlanScreen()),
      GoRoute(path: AppRoutes.social, builder: (_, __) => const SocialScreen()),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.info, builder: (_, __) => const InfoScreen()),
    ],
  );
});
