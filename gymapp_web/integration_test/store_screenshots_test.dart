// Google Play screenshots: the real app against a running API, signed in to an account with
// some history (e.g. the simulated one). Run through tool/store_screenshots.sh, which sets the
// emulator to a 16:9 screen with a clean status bar and runs it in Polish and English:
//
//   SCREENSHOT_EMAIL=… SCREENSHOT_PASSWORD=… tool/store_screenshots.sh
//
// PNGs land in fastlane/metadata/android/<pl-PL|en-US>/images/phoneScreenshots/.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/core/storage/secure_storage_keys.dart';
import 'package:gymapp_web/features/auth/data/auth_local_storage.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _email = String.fromEnvironment('SCREENSHOT_EMAIL');
const _password = String.fromEnvironment('SCREENSHOT_PASSWORD');
const _locale = String.fromEnvironment('SCREENSHOT_LOCALE', defaultValue: 'pl');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // A still pose instead of the looping animation (pumpAndSettle would wait forever).
  MotionView.animate = false;

  // Without an account (e.g. the CI emulator job running all of integration_test/) there is nothing to shoot.
  testWidgets('store screenshots ($_locale)', skip: _email.isEmpty, (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString(StorageKeys.locale, _locale);
    await prefs.setBool(StorageKeys.onboardingDone, true);
    await AuthLocalStorage().clear();

    await tester.pumpWidget(const ProviderScope(retry: noRetry, child: GymApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(GymApp)));

    // Sign in through the login screen.
    await tester.enterText(find.byType(TextFormField).at(0), _email);
    await tester.enterText(find.byType(TextFormField).at(1), _password);
    await tester.tap(find.byType(FilledButton).first);
    await _settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'sign-in failed — is the API running?');

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    var n = 0;
    Future<void> shot(String name) async {
      await _settle(tester);
      await binding.takeScreenshot('${++n}_$name');
    }

    Future<void> tab(int index) async {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination)).at(index));
      await _settle(tester);
    }

    // 1. Today: the week, goals with forecasts, plans.
    await shot('today');

    // 2. A workout from a plan: hint, note, warm-up.
    final start = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('plan.start.'));
    await _scrollTo(tester, start);
    await _settle(tester);
    await tester.tap(start.first);
    await _settle(tester);
    // Fold the warm-up checklist so the sets are in the picture.
    await tester.tap(find.descendant(of: find.byKey(const Key('routine.warmUp')), matching: find.byType(ListTile)).first);
    await _settle(tester);
    await shot('workout');
    container.read(activeSessionProvider.notifier).discard();
    container.read(restTimerProvider.notifier).stop();
    await tester.binding.handlePopRoute(); // Android Back
    await _settle(tester);

    // 3. Progress: activity map, comparison, muscle groups.
    await tab(2);
    await shot('progress');

    // 4. The bench press with its chart (further down the list of trained exercises).
    final bench = find.text(_locale == 'pl' ? 'Wyciskanie sztangi leżąc' : 'Barbell bench press');
    await _scrollTo(tester, bench);
    await _settle(tester);
    await tester.tap(bench);
    await _settle(tester);
    await shot('exercise');
    await tester.binding.handlePopRoute(); // Android Back
    await _settle(tester);

    // 5. History day by day with mood and notes (button in the app bar).
    await tester.tap(find.byKey(const Key('progress.history')));
    await _settle(tester);
    await shot('history');
    await tester.binding.handlePopRoute(); // Android Back
    await _settle(tester);

    // 6. Exercise catalog.
    await tab(1);
    await shot('exercises');
  });
}

/// Network replies arrive outside the test's clock: pump a little, then settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pumpAndSettle();
}

/// Scrolls the screen's main list down until [finder] is built, then brings it into view.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list.first, const Offset(0, -300));
    await _settle(tester);
  }
  await tester.ensureVisible(finder.first);
  await _settle(tester);
}
