import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/features/auth/presentation/auth_providers.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_providers.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:gymapp_web/features/settings/presentation/settings_providers.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'settings.locale': 'en'}));

  group('Settings', () {
    testWidgets('theme follows the phone by default; Dark is chosen and persisted', (tester) async {
      late WidgetRef ref;
      await pumpScreen(tester, Consumer(builder: (context, r, _) {
        ref = r;
        return const SettingsScreen();
      }));

      expect(ref.read(themeProvider), ThemeMode.system);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(ref.read(themeProvider), ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.theme_mode'), 'dark');
    });

    testWidgets('language switch changes the whole app language', (tester) async {
      await tester.pumpWidget(ProviderScope(
        retry: noRetry,
        overrides: [
          authLocalStorageProvider.overrideWithValue(EmptyAuthStorage()),
          onboardingEnabledProvider.overrideWithValue(false),
          restAlarmProvider.overrideWithValue(FakeRestAlarm()),
          planRepositoryProvider.overrideWithValue(FakePlanRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const GymApp(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Remember me'), findsOneWidget);

      final container = ProviderScope.containerOf(tester.element(find.byType(GymApp)));
      await container.read(localeProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(find.text('Zapamiętaj mnie'), findsOneWidget);
    });
  });

  group('Login', () {
    Future<FakeAuthRepository> pumpLogin(WidgetTester tester, {Object? loginError}) async {
      final repo = FakeAuthRepository(loginError: loginError);
      await tester.pumpWidget(ProviderScope(
        retry: noRetry,
        overrides: [
          authLocalStorageProvider.overrideWithValue(EmptyAuthStorage()),
          onboardingEnabledProvider.overrideWithValue(false),
          restAlarmProvider.overrideWithValue(FakeRestAlarm()),
          planRepositoryProvider.overrideWithValue(FakePlanRepository()),
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const GymApp(),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'jan@test.pl');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('wrong password shows the API message and stays on login', (tester) async {
      final repo = await pumpLogin(tester,
          loginError: const UnauthorizedFailure('Invalid login or password.', 'InvalidCredentials'));

      expect(repo.logins, ['jan@test.pl']);
      expect(find.text('Invalid login or password.'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
    });

    testWidgets('too many attempts shows the localized rate-limit message', (tester) async {
      await pumpLogin(tester, loginError: const RateLimitedFailure());

      expect(find.text('Too many attempts. Wait a minute and try again.'), findsOneWidget);
    });

    testWidgets('unconfirmed email: login opens the code screen, sends a fresh code, the right code signs in',
        (tester) async {
      final repo = await pumpLogin(tester,
          loginError: const ForbiddenFailure('Confirm your email address with the code we sent you.', 'EmailNotConfirmed'));

      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.textContaining('jan@test.pl'), findsOneWidget);
      expect(repo.calls, contains('resend jan@test.pl'));
      expect(tester.widget<TextButton>(find.byKey(const Key('verify.resend'))).onPressed, isNull); // 60 s cooldown

      await tester.enterText(find.byKey(const Key('code.field')), '999999');
      await tester.pump();
      await tester.tap(find.byKey(const Key('verify.confirm')));
      await tester.pumpAndSettle();
      expect(find.text('The code is invalid or has expired.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('code.field')), FakeAuthRepository.validCode);
      await tester.pump();
      await tester.tap(find.byKey(const Key('verify.confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget); // signed in
      await tester.pump(const Duration(seconds: 61)); // let the cooldown timer finish
    });

    testWidgets('forgot password: email → code + new password → back to login', (tester) async {
      final repo = await pumpLogin(tester,
          loginError: const UnauthorizedFailure('Invalid login or password.', 'InvalidCredentials'));
      await tester.tap(find.byKey(const Key('login.forgot')));
      await tester.pumpAndSettle();

      expect(tester.widget<TextFormField>(find.byKey(const Key('forgot.email'))).controller!.text, 'jan@test.pl');
      await tester.tap(find.byKey(const Key('forgot.send')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'forgot jan@test.pl');

      await tester.enterText(find.byKey(const Key('code.field')), FakeAuthRepository.validCode);
      await tester.enterText(find.byKey(const Key('forgot.password')), 'short');
      await tester.pump();
      await tester.tap(find.byKey(const Key('forgot.reset')));
      await tester.pumpAndSettle();
      expect(find.textContaining('at least 8'), findsOneWidget); // validated before calling the API
      expect(repo.calls.where((c) => c.startsWith('reset')), isEmpty);

      await tester.enterText(find.byKey(const Key('forgot.password')), 'NoweHaslo123');
      await tester.tap(find.byKey(const Key('forgot.reset')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'reset jan@test.pl ${FakeAuthRepository.validCode} NoweHaslo123');
      expect(find.text('Password changed. Log in with the new one.'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('sign-up goes to the code screen for that email', (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(ProviderScope(
        retry: noRetry,
        overrides: [
          authLocalStorageProvider.overrideWithValue(EmptyAuthStorage()),
          onboardingEnabledProvider.overrideWithValue(false),
          restAlarmProvider.overrideWithValue(FakeRestAlarm()),
          planRepositoryProvider.overrideWithValue(FakePlanRepository()),
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const GymApp(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'nowy@test.pl');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.calls, ['register nowy@test.pl']); // no extra resend: sign-up already sent the code
      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.textContaining('nowy@test.pl'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('successful login opens the Today tab with the bottom navigation', (tester) async {
      await pumpLogin(tester);

      expect(find.text('Remember me'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
    });
  });
}
