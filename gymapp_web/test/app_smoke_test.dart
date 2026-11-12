import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/features/auth/data/auth_local_storage.dart';
import 'package:gymapp_web/features/auth/data/models/auth_tokens.dart';
import 'package:gymapp_web/features/auth/presentation/auth_providers.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_providers.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart' show FakePlanRepository, FakeRestAlarm;

/// No saved session (the real storage needs the secure storage plugin).
class _EmptyStorage extends AuthLocalStorage {
  @override
  Future<AuthTokens?> restore() async => null;

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'settings.locale': 'en'}));

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authLocalStorageProvider.overrideWithValue(_EmptyStorage()),
        onboardingEnabledProvider.overrideWithValue(false),
        restAlarmProvider.overrideWithValue(FakeRestAlarm()),
        planRepositoryProvider.overrideWithValue(FakePlanRepository()),
      ],
      child: const GymApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('without a session the app starts on the login screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('login form validates locally before calling the API', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('register screen requires 8+ character passwords', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.pl');
    await tester.enterText(find.byType(TextFormField).at(1), '1234567');
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
  });
}
