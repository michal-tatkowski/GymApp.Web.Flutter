import 'package:flutter/material.dart';
import 'package:gymapp_web/features/register/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.08),
                ],
              ),
            ),
          ),
          const RegisterForm(),
        ],
      ),
    );
  }
}
