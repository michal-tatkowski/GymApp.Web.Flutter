import 'package:flutter/material.dart';
import 'package:gymapp_web/features/login/login_form.dart';
import 'package:gymapp_web/routing/app_router.dart';
import 'package:gymapp_web/routing/routes.dart';
import 'package:gymapp_web/services/navigation_service.dart';
import 'package:gymapp_web/services/theme_service.dart';

final NavigationService navigationService = NavigationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.loadTheme();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigationService.navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
          debugShowCheckedModeBanner: false,
          initialRoute: TRoutes.login,
          title: 'Login',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: currentMode,
          home: const LoginForm(),
        );
      },
    );
  }
}
