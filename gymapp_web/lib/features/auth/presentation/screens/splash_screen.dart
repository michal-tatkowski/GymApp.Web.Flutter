import 'package:flutter/material.dart';

/// Briefly shown while the auth controller restores the session.
/// Navigation away happens in go_router's `redirect` based on auth state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
