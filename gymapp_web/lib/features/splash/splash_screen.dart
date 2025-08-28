import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/routes.dart';
import '../../services/jwt_token_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    final token = await JwtTokenService.instance.initSession();

    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, TRoutes.home, (r) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, TRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
