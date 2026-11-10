import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/presentation/profile_providers.dart';
import 'package:gymapp_web/features/profile/profile_screen.dart';

import '../helpers/test_app.dart';

void main() {
  const profile = UserProfile(
    nickname: 'Tester',
    firstName: 'Jan',
    gender: Gender.male,
    height: 180,
    weight: 80.5,
    bmi: 24.8,
  );

  Future<FakeProfileRepository> pump(WidgetTester tester, {UserProfile p = profile, Object? loadError}) async {
    final repo = FakeProfileRepository(p)..loadError = loadError;
    await pumpScreen(tester, const ProfileScreen(),
        overrides: [profileRepositoryProvider.overrideWithValue(repo)]);
    return repo;
  }

  testWidgets('shows the profile with formatted values and dashes for missing ones', (tester) async {
    await pump(tester);

    expect(find.text('Tester'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('180 cm'), findsOneWidget); // not "180.0 cm"
    expect(find.text('80.5 kg'), findsOneWidget);
    expect(find.text('24.8'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2)); // last name, date of birth
    expect(find.text('JT'), findsOneWidget); // initials: first name + nickname
  });

  testWidgets('edit → change nickname → save sends the request and shows the result', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile.nickname')), '  Nowy  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final req = repo.saved.single;
    expect(req.nickname, 'Nowy');
    expect(req.firstName, 'Jan');
    expect(req.lastName, ''); // empty text field is sent so the API clears it
    expect(req.height, 180);
    expect(find.text('Profile saved'), findsOneWidget);
    expect(find.text('Nowy'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget); // back in view mode
  });

  testWidgets('invalid height is caught by the form, nothing is sent', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile.height')), '999');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value between 50 and 272'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('server rejection keeps the form and what the user typed', (tester) async {
    final repo = await pump(tester);
    repo.saveError = const ValidationFailure('Nickname is taken.');

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile.nickname')), 'Zajęty');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Nickname is taken.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget); // still editing
    expect(find.widgetWithText(TextFormField, 'Zajęty'), findsOneWidget);
  });

  testWidgets('cancel discards changes', (tester) async {
    final repo = await pump(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile.nickname')), 'Inny');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
    expect(find.text('Tester'), findsOneWidget);
  });

  testWidgets('load error shows the reason and "Try again" reloads', (tester) async {
    final repo = await pump(tester, loadError: const NetworkFailure());

    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);

    repo.loadError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Tester'), findsOneWidget);
    expect(repo.loads, 2);
  });

  testWidgets('Polish UI', (tester) async {
    final repo = FakeProfileRepository(profile);
    await pumpScreen(tester, const ProfileScreen(),
        overrides: [profileRepositoryProvider.overrideWithValue(repo)], locale: const Locale('pl'));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Mężczyzna'), findsOneWidget);
    expect(find.text('Wzrost'), findsOneWidget);
  });
}
