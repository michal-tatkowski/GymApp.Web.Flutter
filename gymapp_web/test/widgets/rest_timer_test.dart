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
}
