import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/app_routes.dart';
import '../auth_providers.dart';
import 'email_code_screens.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text, rememberMe: _rememberMe);
    // Router auto-redirects on authenticated state. On success, let the password
    // manager offer to save the credentials (Android Autofill / iCloud Keychain).
    if (!ref.read(authControllerProvider).hasError) TextInput.finishAutofillContext();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);

    // Surface errors via SnackBar rather than dialog — less intrusive.
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          // Right password, email not confirmed yet → straight to the code screen.
          if (err is Failure && err.code == 'EmailNotConfirmed') {
            context.go(VerifyEmailScreen.location(_emailCtrl.text.trim(), rememberMe: _rememberMe, sendOnOpen: true));
            return;
          }
          final msg = describeError(t, err);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email, AutofillHints.username],
                      decoration: InputDecoration(labelText: t.email, prefixIcon: const Icon(Icons.alternate_email)),
                      validator: (v) => validateEmail(t, v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isLoading ? null : _onLogin(),
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) => validatePassword(t, v),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        key: const Key('login.forgot'),
                        onPressed: isLoading
                            ? null
                            : () => context.go(ForgotPasswordScreen.location(_emailCtrl.text.trim())),
                        child: Text(t.forgotPassword),
                      ),
                    ),
                    // Whole row is the tap target, not just the 18 dp box.
                    CheckboxListTile(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      title: Text(t.rememberMe),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: isLoading ? null : _onLogin,
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(t.login),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(t.or)),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: isLoading ? null : () => context.go(AppRoutes.register),
                      child: Text(t.register),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
