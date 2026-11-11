import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/today/week_summary.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/profile/presentation/widgets/body_weight_card.dart';
import 'package:gymapp_web/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('week summary', () {
    // Wednesday 2026-11-11; Monday-first week starts 2026-11-09.
    final wed = DateTime(2026, 11, 11);
    TrainingDay day(DateTime d, [int sets = 5]) => TrainingDay(date: d, volume: 1000, exercises: 2, sets: sets);

    test('days of this week, totals, records of this week only', () {
      final s = summarizeWeek(
        WorkoutStats(
          days: [day(DateTime(2026, 11, 2)), day(DateTime(2026, 11, 9)), day(DateTime(2026, 11, 11), 7)],
          records: [
            PersonalRecord(date: DateTime(2026, 11, 2), exerciseId: 'a', exerciseName: 'Old', oneRepMax: true),
            PersonalRecord(date: DateTime(2026, 11, 11), exerciseId: 'b', exerciseName: 'Squat', oneRepMax: false),
          ],
        ),
        wed,
        1, // Monday first
      );
      expect(s.weekStart, DateTime(2026, 11, 9));
      expect(s.trainedDays, {0, 2});
      expect((s.workouts, s.sets, s.volumeKg), (2, 12, 2000.0));
      expect(s.records.map((r) => r.exerciseName), ['Squat']);
      expect(s.weekStreak, 2);
    });

    test('Sunday-first week; streak not broken until the week ends without a workout', () {
      final stats = WorkoutStats(days: [day(DateTime(2026, 10, 28)), day(DateTime(2026, 11, 4))], records: const []);
      final s = summarizeWeek(stats, wed, 0);
      expect(s.weekStart, DateTime(2026, 11, 8)); // Sunday
      expect(s.workouts, 0);
      expect(s.weekStreak, 2); // last two weeks; this one is still open
      expect(summarizeWeek(stats, DateTime(2026, 11, 20), 0).weekStreak, 0); // a whole week skipped
    });
  });

  testWidgets('Today card: dots, totals and streak', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final repo = FakeWorkoutRepository()
      ..seed('bench', today, const [WorkoutSet(reps: 10, weight: 100), WorkoutSet(reps: 10, weight: 100)])
      ..seed('bench', today.subtract(const Duration(days: 7)), const [WorkoutSet(reps: 10, weight: 100)]);
    await pumpScreen(tester, const Scaffold(body: WeekSummaryCard()),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    expect(find.byKey(const Key('today.week')), findsOneWidget);
    expect(find.text('1 workout · 2 sets · 2000 kg'), findsOneWidget);
    expect(find.textContaining('2-week streak'), findsOneWidget);
  });

  testWidgets('body weight: log today in the chosen unit, latest and change shown', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.weight_unit': 'lb'});
    final today = DateUtils.dateOnly(DateTime.now());
    final repo = FakeWorkoutRepository()..bodyWeights.add(BodyWeight(date: today.subtract(const Duration(days: 40)), kg: 82));
    await pumpScreen(tester, const Scaffold(body: SingleChildScrollView(child: BodyWeightCard())),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);
    expect(find.text('180.8 lb'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bodyWeight.log')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byKey(const Key('bodyWeight.value'))).controller!.text, '180.8');
    await tester.enterText(find.byKey(const Key('bodyWeight.value')), '178');
    await tester.tap(find.byKey(const Key('bodyWeight.save')));
    await tester.pumpAndSettle();

    expect(repo.bodyWeights.last.kg, 80.74); // stored in kg
    expect(find.text('178 lb'), findsOneWidget);
    expect(find.textContaining('−2.8 lb in 30 days'), findsOneWidget);
  });

  testWidgets('reminders: turning on asks for permission and schedules the chosen days', (tester) async {
    final scheduler = FakeReminderScheduler();
    await pumpScreen(tester, const SettingsScreen(), reminders: scheduler);
    await tester.ensureVisible(find.byKey(const Key('settings.reminders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.reminders')));
    await tester.pumpAndSettle();

    expect(scheduler.applied.last.enabled, isTrue);
    expect(scheduler.applied.last.weekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});

    await tester.ensureVisible(find.byKey(const Key('settings.reminders.day${DateTime.saturday}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.reminders.day${DateTime.saturday}')));
    await tester.pumpAndSettle();
    expect(scheduler.applied.last.weekdays, contains(DateTime.saturday));
  });

  testWidgets('reminders: permission refused → stays off and says why', (tester) async {
    final scheduler = FakeReminderScheduler()..allow = false;
    await pumpScreen(tester, const SettingsScreen(), reminders: scheduler);
    await tester.ensureVisible(find.byKey(const Key('settings.reminders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings.reminders')));
    await tester.pumpAndSettle();

    expect(scheduler.applied, isEmpty);
    expect(find.textContaining('Allow notifications'), findsOneWidget);
  });
}
