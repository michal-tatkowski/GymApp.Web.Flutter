import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/home_widget_sync.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/session/session_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/today/week_summary.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/settings/data_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

class FakeHomeWidget implements HomeWidgetSync {
  final updates = <String>[];

  @override
  Future<void> update({required String title, required String days, required String line, required String streak}) async =>
      updates.add('$days | $line');

  @override
  Future<void> clear() async => updates.add('clear');
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('CSV: one row per set, by date, notes on the first set, quoted when needed', () {
    final csv = DataExport.workoutsCsv({
      'workouts': [
        {
          'exerciseName': 'Bench, flat',
          'entries': [
            {
              'date': '2026-11-10',
              'notes': 'felt "light"',
              'sets': [
                {'reps': 5, 'weight': 100},
                {'reps': 5, 'weight': 100},
              ],
            },
          ],
        },
        {
          'exerciseName': 'Plank',
          'entries': [
            {
              'date': '2026-11-02',
              'sets': [
                {'reps': 0, 'weight': 0, 'durationSeconds': 60},
              ],
            },
          ],
        },
      ],
    });

    expect(csv.split('\n'), [
      'date,exercise,set,reps,weight_kg,duration_s,distance_m,notes',
      '2026-11-02,Plank,1,0,0,60,,',
      '2026-11-10,"Bench, flat",1,5,100,,,"felt ""light"""',
      '2026-11-10,"Bench, flat",2,5,100,,,',
    ]);
  });

  testWidgets('the week card feeds the home screen widget', (tester) async {
    final widget = FakeHomeWidget();
    final repo = FakeWorkoutRepository()..seed('bench', today, const [WorkoutSet(reps: 10, weight: 100)]);
    await pumpScreen(tester, const Scaffold(body: WeekSummaryCard()), overrides: [
      workoutRepositoryProvider.overrideWithValue(repo),
      homeWidgetSyncProvider.overrideWithValue(widget),
    ]);

    expect(widget.updates.last, contains('●'));
    expect(widget.updates.last, contains('1 workout · 1 set · 1,000 kg'));
  });

  testWidgets('in the background a notification shows the next set; "Set done" ticks it', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final alarm = FakeRestAlarm();
    const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
      PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 2, repsMin: 8, repsMax: 8),
    ]);
    await pumpScreen(tester, const TodayScreen(), plans: FakePlanRepository([plan]), restAlarm: alarm, overrides: [
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
    ]);
    final c = ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));
    await tester.tap(find.byKey(const Key('plan.start.p1')));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(alarm.sessionNotes.single, 'Push · Bench press | Set 1 of 2 · 8');

    alarm.actionController.add(kSessionDoneAction);
    await tester.pump();
    expect(c.read(activeSessionProvider)!.currentExercise.sets.map((s) => s.done), [true, false]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(alarm.calls, contains('clearSession'));
    c.read(restTimerProvider.notifier).stop();
  });
}
