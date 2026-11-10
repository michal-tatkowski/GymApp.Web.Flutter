import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/exercise_workouts_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/widgets/progress_chart.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  final today = DateTime(2026, 11, 10);

  ProgressPoint point(int daysAgo, double volume, {double e1rm = 0, double max = 100, int reps = 10}) => ProgressPoint(
        date: today.subtract(Duration(days: daysAgo)),
        volume: volume,
        totalReps: reps,
        maxWeight: max,
        sets: 1,
        estimatedOneRepMax: e1rm,
      );

  Future<void> pumpChart(WidgetTester tester, List<ProgressPoint> points) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: ProgressChart(points: points, today: today))),
    );
  }

  String bigNumber(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('progress.value'))).data!;

  testWidgets('range buttons limit the chart to recent training days', (tester) async {
    await pumpChart(tester, [point(200, 800), point(60, 900), point(20, 1000), point(5, 1100)]);
    expect(find.text('+38%'), findsOneWidget); // 800 → 1100 (All)

    await tester.tap(find.text('1M'));
    await tester.pumpAndSettle();
    expect(find.text('+10%'), findsOneWidget); // 1000 → 1100

    await tester.tap(find.text('3M'));
    await tester.pumpAndSettle();
    expect(find.text('+22%'), findsOneWidget); // 900 → 1100
  });

  testWidgets('range with fewer than two days shows the hint but keeps the selectors', (tester) async {
    await pumpChart(tester, [point(200, 800), point(5, 1100)]);

    await tester.tap(find.text('1M'));
    await tester.pumpAndSettle();

    expect(find.text('Log at least two training days to see the trend.'), findsOneWidget);
    expect(find.byKey(const Key('progress.range')), findsOneWidget);
  });

  testWidgets('metric switch: volume dropped, but estimated 1RM went up', (tester) async {
    // 10×100 → 8×110
    await pumpChart(tester, [point(2, 1000, e1rm: 133.3, max: 100), point(1, 880, e1rm: 139.3, max: 110)]);
    expect(find.text('-12%'), findsOneWidget);

    await tester.tap(find.text('1RM'));
    await tester.pumpAndSettle();
    expect(bigNumber(tester), '139.3 kg');
    expect(find.text('+5%'), findsOneWidget);

    await tester.tap(find.text('Max'));
    await tester.pumpAndSettle();
    expect(bigNumber(tester), '110 kg');
  });

  testWidgets('tapping the chart shows that day; tapping it again goes back to the latest', (tester) async {
    await pumpChart(tester, [point(30, 1000), point(15, 1100), point(1, 1200)]);
    final chart = tester.getRect(find.byKey(const Key('progress.chart')));

    // Left edge of the plot = the first (oldest) day.
    await tester.tapAt(Offset(chart.left + 46, chart.center.dy));
    await tester.pump();
    expect(bigNumber(tester), '1000 kg');
    expect(find.byKey(const Key('progress.change')), findsNothing);

    await tester.tapAt(Offset(chart.left + 46, chart.center.dy));
    await tester.pump();
    expect(bigNumber(tester), '1200 kg');
  });

  testWidgets('a record day is labelled', (tester) async {
    await pumpChart(tester, [point(3, 1000), point(2, 900), point(1, 1100)]);

    expect(find.byKey(const Key('progress.record')), findsOneWidget); // latest = record

    final chart = tester.getRect(find.byKey(const Key('progress.chart')));
    await tester.tapAt(Offset(chart.left + 46 + (chart.width - 46) / 2, chart.center.dy)); // middle day, 900
    await tester.pump();
    expect(find.byKey(const Key('progress.record')), findsNothing);
  });

  testWidgets('screen readers get a summary of the chart', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, [point(2, 1000), point(1, 1200)]);

    expect(find.bySemanticsLabel('Volume chart: from 1000 to 1200 over 2 training days'), findsOneWidget);
    handle.dispose();
  });

  group('logic', () {
    test('x follows real dates: points are not evenly spaced', () {
      expect(recordIndexes([1000, 900, 1100, 1100, 1200]), [2, 4]);
      expect(inRange([point(200, 1), point(10, 2)], ProgressRange.month, today).length, 1);
      expect(inRange([point(200, 1), point(10, 2)], ProgressRange.all, today).length, 2);
    });

    test('new record: higher day volume or higher estimated 1RM; never on the first day', () {
      final before = [point(2, 1000, e1rm: 133.3), point(1, 1000, e1rm: 133.3)];
      WorkoutEntry entry(double volume, double e1rm) =>
          WorkoutEntry(id: 'x', date: today, sets: const [], volume: volume, estimatedOneRepMax: e1rm);

      expect(newRecordFor(before, entry(1200, 140)), NewRecord.oneRepMax);
      expect(newRecordFor(before, entry(1200, 120)), NewRecord.volume);
      expect(newRecordFor(before, entry(900, 120)), isNull);
      expect(newRecordFor(const [], entry(5000, 200)), isNull);
    });
  });

  testWidgets('saving a better workout says "New record"', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateUtils.dateOnly(DateTime.now());
    final repo = FakeWorkoutRepository()
      ..seed('bench', now.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 10, weight: 100)])
      ..seed('bench', now.subtract(const Duration(days: 1)), [const WorkoutSet(reps: 10, weight: 100)]);
    await pumpScreen(tester, const ExerciseWorkoutsScreen(exerciseId: 'bench', exerciseName: 'Bench press'),
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)]);

    await tester.tap(find.byKey(const Key('workout.log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('workout.set0.reps')), '12');
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();

    expect(find.text('🏆 New record: strongest so far (est. 1RM)!'), findsOneWidget);
  });
}
