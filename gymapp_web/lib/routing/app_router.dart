import 'package:flutter/material.dart';
import 'package:gymapp_web/features/home/home_menu.dart';
import 'package:gymapp_web/features/login/login_form.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:gymapp_web/routing/routes.dart';
import '../features/register/register_form.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case TRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeMenu());
      case TRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginForm());
      case TRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterForm());
      case TRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Nie znaleziono trasy'))),
        );
    }
  }
}
