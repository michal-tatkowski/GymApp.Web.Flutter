import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpBar(WidgetTester tester) async {
    await pumpScreen(tester, const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: RestTimerBar())));
    return ProviderScope.containerOf(tester.element(find.byType(RestTimerBar)));
  }

  testWidgets('counts down, ±15 s, and announces the end', (tester) async {
    final c = await pumpBar(tester);
    expect(find.byKey(const Key('rest.bar')), findsNothing);

    c.read(restTimerProvider.notifier).startAfterSet(); // default 90 s
    await tester.pump();
    expect(find.text('Rest 1:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Rest 1:20'), findsOneWidget);

    await tester.tap(find.text('+15 s'));
    await tester.pump();
    expect(find.text('Rest 1:35'), findsOneWidget);

    await tester.pump(const Duration(seconds: 95));
    expect(find.text('Rest is over — next set!'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.byKey(const Key('rest.bar')), findsNothing);
  });

  testWidgets('"Off" in Settings disables the timer and is remembered', (tester) async {
    await pumpScreen(tester, const SettingsScreen());
    final c = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    c.read(restTimerProvider.notifier).startAfterSet();

    expect(c.read(restTimerProvider).visible, isFalse);
    expect((await SharedPreferences.getInstance()).getInt('settings.rest_timer_seconds'), 0);
  });

  test('format', () {
    expect(formatRest(const Duration(seconds: 90)), '1:30');
    expect(formatRest(const Duration(seconds: 5)), '0:05');
  });

  group('in the background (phone in the pocket)', () {
    Future<(ProviderContainer, FakeRestAlarm)> start(WidgetTester tester) async {
      final alarm = FakeRestAlarm();
      await pumpScreen(
        tester,
        const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: RestTimerBar())),
        restAlarm: alarm,
      );
      final c = ProviderScope.containerOf(tester.element(find.byType(RestTimerBar)));
      c.read(restTimerProvider.notifier).startAfterSet(); // 90 s
      await tester.pump();
      return (c, alarm);
    }

    void lifecycle(WidgetTester tester, List<AppLifecycleState> states) {
      for (final s in states) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
    }

    testWidgets('leaving the app shows the countdown and schedules the end alert; coming back clears them',
        (tester) async {
      final (_, alarm) = await start(tester);
      final started = clock.now();
      expect(alarm.calls, ['permission']); // asked in context, on first use

      await tester.pump(const Duration(seconds: 10));
      lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
      expect(alarm.calls.last, 'background');
      expect(alarm.endsAt, started.add(const Duration(seconds: 90)));

      lifecycle(tester, [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
      expect(alarm.calls.last, 'clear');
      await tester.pump();
      expect(find.text('Rest 1:20'), findsOneWidget);
    });

    testWidgets('no notifications when no rest is running; permission asked only once', (tester) async {
      final (c, alarm) = await start(tester);
      c.read(restTimerProvider.notifier).stop();
      c.read(restTimerProvider.notifier).startAfterSet();
      c.read(restTimerProvider.notifier).stop();
      alarm.calls.clear();

      lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
      expect(alarm.calls, isEmpty);
    });

    testWidgets('+15 s moves the end time', (tester) async {
      final (c, alarm) = await start(tester);
      final started = clock.now();
      c.read(restTimerProvider.notifier).adjust(const Duration(seconds: 15));

      lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
      expect(alarm.endsAt, started.add(const Duration(seconds: 105)));
      lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    });
  });

  testWidgets('Settings offers "exact alarms" only when Android does not allow them', (tester) async {
    await pumpScreen(tester, const SettingsScreen()); // fake default: alarms allowed
    expect(find.text('Alert exactly on time'), findsNothing);
    await tester.pumpWidget(const SizedBox()); // fresh tree for the second case

    final alarm = FakeRestAlarm()..onTime = false;
    await pumpScreen(tester, const SettingsScreen(), restAlarm: alarm);
    await tester.tap(find.text('Alert exactly on time'));
    expect(alarm.calls, ['exactSettings']);
  });
}
