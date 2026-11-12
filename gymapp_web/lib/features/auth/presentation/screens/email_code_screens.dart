import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/validation/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/app_routes.dart';
import '../auth_providers.dart';

/// Must match the API (IEmailCodeService.CodeLength / ResendInterval).
const kEmailCodeLength = 6;
const kResendCooldown = Duration(seconds: 60);

/// Six digits from the email; also accepts a pasted "123 456".
class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, this.errorText, this.onSubmitted, this.onChanged});

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback? onSubmitted;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TextField(
      key: const Key('code.field'),
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(kEmailCodeLength)],
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
      decoration: InputDecoration(labelText: t.codeLabel, errorText: errorText, counterText: ''),
      onChanged: (_) => onChanged?.call(),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

/// "Send a new code" with the server's one-minute cooldown shown as a countdown.
mixin _ResendCooldown<T extends StatefulWidget> on State<T> {
  Timer? _ticker;
  int _wait = 0;

  void startCooldown() {
    _ticker?.cancel();
    setState(() => _wait = kResendCooldown.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _wait--);
      if (_wait <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email, this.rememberMe = true, this.sendOnOpen = false});

  final String email;
  final bool rememberMe;

  /// Coming from login: the code from sign-up may be long gone, so ask for a fresh one.
  final bool sendOnOpen;

  static String location(String email, {bool rememberMe = true, bool sendOnOpen = false}) => Uri(
        path: AppRoutes.verifyEmail,
        queryParameters: {'email': email, if (!rememberMe) 'remember': '0', if (sendOnOpen) 'send': '1'},
      ).toString();

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> with _ResendCooldown {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resend(announce: false));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => startCooldown()); // just sent at sign-up
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_code.text.length != kEmailCodeLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .confirmEmail(email: widget.email, code: _code.text, rememberMe: widget.rememberMe);
      // Router moves on to Today once signed in.
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(AppLocalizations.of(context)!, e);
        });
      }
    }
  }

  Future<void> _resend({bool announce = true}) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    startCooldown();
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(widget.email);
      if (announce) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(t.codeSent)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(describeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return _CodeScaffold(
      icon: Icons.mark_email_unread_outlined,
      title: t.verifyEmailTitle,
      body: t.verifyEmailBody(widget.email),
      children: [
        _CodeField(controller: _code, errorText: _error, onSubmitted: _confirm, onChanged: () => setState(() {})),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('verify.confirm'),
          onPressed: _busy || _code.text.length != kEmailCodeLength ? null : _confirm,
          child: _busy ? const _Spinner() : Text(t.confirmCode),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('verify.resend'),
          onPressed: _wait > 0 ? null : _resend,
          child: Text(_wait > 0 ? t.resendIn(_wait) : t.resendCode),
        ),
        TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(t.backToLogin)),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  final String email;

  static String location(String email) =>
      Uri(path: AppRoutes.forgotPassword, queryParameters: {if (email.isNotEmpty) 'email': email}).toString();

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with _ResendCooldown {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _codeError;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_emailForm.currentState!.validate() || _busy) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (!mounted) return;
      startCooldown();
      setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(t, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate() || _code.text.length != kEmailCodeLength || _busy) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(email: _email.text.trim(), code: _code.text, newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(t.passwordChanged)));
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _codeError = describeError(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (!_codeSent) {
      return _CodeScaffold(
        icon: Icons.lock_reset,
        title: t.forgotTitle,
        body: t.forgotBody,
        children: [
          Form(
            key: _emailForm,
            child: TextFormField(
              key: const Key('forgot.email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: t.email, prefixIcon: const Icon(Icons.alternate_email)),
              validator: (v) => validateEmail(t, v),
              onFieldSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('forgot.send'),
            onPressed: _busy ? null : _send,
            child: _busy ? const _Spinner() : Text(t.sendCode),
          ),
          TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(t.backToLogin)),
        ],
      );
    }

    return _CodeScaffold(
      icon: Icons.lock_reset,
      title: t.forgotTitle,
      body: t.resetBody(_email.text.trim()),
      children: [
        _CodeField(controller: _code, errorText: _codeError, onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        Form(
          key: _resetForm,
          child: TextFormField(
            key: const Key('forgot.password'),
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: t.newPassword,
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) => validatePassword(t, v, checkLength: true),
            onFieldSubmitted: (_) => _reset(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('forgot.reset'),
          onPressed: _busy || _code.text.length != kEmailCodeLength ? null : _reset,
          child: _busy ? const _Spinner() : Text(t.setNewPassword),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _wait > 0 || _busy ? null : _send,
          child: Text(_wait > 0 ? t.resendIn(_wait) : t.resendCode),
        ),
        TextButton(onPressed: () => context.go(AppRoutes.login), child: Text(t.backToLogin)),
      ],
    );
  }
}

class _CodeScaffold extends StatelessWidget {
  const _CodeScaffold({required this.icon, required this.title, required this.body, required this.children});

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
}
