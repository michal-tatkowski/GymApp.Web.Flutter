import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/progress/badges.dart';
import 'package:gymapp_web/features/gym/progress/progress_cards.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/my_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  TrainingDay day(DateTime d, {int sets = 10, double volume = 1000}) =>
      TrainingDay(date: d, volume: volume, exercises: 2, sets: sets);
  BadgeProgress badge(List<BadgeProgress> all, String id) => all.firstWhere((b) => b.def.id == id);

  test('activity level grows with the sets of the day', () {
    expect([0, 1, 5, 6, 11, 12, 19, 20, 40].map(activityLevel), [0, 1, 1, 2, 2, 3, 3, 4, 4]);
  });

  group('badges', () {
    test('workout count and volume: earned on the day the threshold was crossed', () {
      final days = [for (var i = 0; i < 12; i++) day(DateTime(2026, 9, 1 + i * 3), volume: 1000)];
      final b = computeBadges(WorkoutStats(days: days, records: const []), 3, 1);

      expect(badge(b, 'workouts1').earnedAt, DateTime(2026, 9, 1));
      expect(badge(b, 'workouts10').earnedAt, DateTime(2026, 9, 28)); // 10th day
      expect(badge(b, 'workouts50').earned, isFalse);
      expect(badge(b, 'workouts50').value, 12);
      expect(badge(b, 'volume10t').earnedAt, DateTime(2026, 9, 28)); // 10 × 1000 kg
      expect(badge(b, 'variety10').earned, isFalse);
    });

    test('week streak counts consecutive weeks; a gap starts over; busiest week', () {
      // Monday-first weeks: 3 weeks in a row (one with 3 workouts), a gap, then 1.
      final days = [
        day(DateTime(2026, 10, 5)), day(DateTime(2026, 10, 6)), day(DateTime(2026, 10, 8)),
        day(DateTime(2026, 10, 13)),
        day(DateTime(2026, 10, 21)),
        day(DateTime(2026, 11, 4)),
      ];
      final b = computeBadges(WorkoutStats(days: days, records: const []), 0, 1);
      expect(badge(b, 'streak4').value, 3);
      expect(badge(b, 'streak4').earned, isFalse);
      expect(badge(b, 'busyWeek3').earnedAt, DateTime(2026, 10, 8));
    });

    test('records and variety', () {
      final records = [
        for (var i = 0; i < 10; i++)
          PersonalRecord(date: DateTime(2026, 10, 1 + i), exerciseId: 'e$i', exerciseName: 'E$i', oneRepMax: true),
      ];
      final b = computeBadges(WorkoutStats(days: const [], records: records), 10, 1);
      expect(badge(b, 'record1').earnedAt, DateTime(2026, 10, 1));
      expect(badge(b, 'record10').earnedAt, DateTime(2026, 10, 10));
      expect(badge(b, 'variety10').earned, isTrue);
    });
  });

  group('Progress tab', () {
    final today = DateUtils.dateOnly(DateTime.now());

    Future<ProviderContainer> pumpProgress(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeWorkoutRepository()
        ..seed('bench', today, const [WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 10, weight: 100)])
        ..seed('squat', today.subtract(const Duration(days: 2)), const [WorkoutSet(reps: 5, weight: 120)]);
      await pumpScreen(tester, const MyWorkoutsScreen(), overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);
      return ProviderScope.containerOf(tester.element(find.byType(MyWorkoutsScreen)));
    }

    testWidgets('activity map: tap a day for its details', (tester) async {
      await pumpProgress(tester);

      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('2 workouts in the last 12 months'), findsOneWidget);
      await tester.tap(find.byKey(Key('activity.${DateFormat('yyyy-MM-dd').format(today)}')));
      await tester.pump();
      expect(find.textContaining('1 exercise · 2 sets'), findsOneWidget);

      await tester.tap(find.byKey(Key('activity.${DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)))}')));
      await tester.pump();
      expect(find.textContaining('rest day'), findsOneWidget);
    });

    testWidgets('badges: earned ones are remembered and a new one is announced', (tester) async {
      final c = await pumpProgress(tester);
      await tester.pumpAndSettle();

      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('1 of 19 earned'), findsOneWidget); // First step
      expect(find.textContaining('New badge: First step'), findsOneWidget); // one new badge is announced
      expect(c.read(earnedBadgesProvider).keys, ['workouts1']);
      expect((await SharedPreferences.getInstance()).getString('badges.earned'), contains('workouts1'));

      await tester.tap(find.byKey(const Key('badge.workouts10')));
      await tester.pumpAndSettle();
      expect(find.text('Train on 10 days'), findsOneWidget);
      expect(find.text('2/10'), findsWidgets);
    });

    testWidgets('a badge kept from before stays earned even when the data no longer shows it', (tester) async {
      await pumpProgress(tester, prefs: {'badges.earned': '{"record1":"2025-12-01T00:00:00.000"}'});
      await tester.pumpAndSettle();

      expect(find.text('2 of 19 earned'), findsOneWidget); // record1 (stored) + workouts1 (new)
      expect(find.textContaining('New badge: First step'), findsOneWidget);
    });
  });
}
