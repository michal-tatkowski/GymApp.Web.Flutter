import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_editor_screen.dart';
import 'package:gymapp_web/features/gym/sharing/sharing.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

class FakeSharing extends SharingRepository {
  FakeSharing() : super(Dio());

  final imported = <String>[];
  static const plan = WorkoutPlan(id: 'p9', name: 'Friend\'s legs', items: [
    PlanItem(exerciseId: 'squat', exerciseName: 'Squat', category: ExerciseCategory.legs, sets: 5, repsMin: 5, repsMax: 5),
  ]);

  @override
  Future<String> sharePlan(String planId) async => 'ABCD2345';

  @override
  Future<SharedItem> preview(String code) async {
    if (normalizeShareCode(code) != 'WXYZ6789') throw const NotFoundFailure('Nothing is shared under this code.', 'ShareCodeNotFound');
    return const SharedItem(code: 'WXYZ6789', plan: plan);
  }

  @override
  Future<SharedItem> import(String code) async {
    imported.add(normalizeShareCode(code));
    return const SharedItem(code: 'WXYZ6789', plan: plan);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('codes are shown in two halves and accepted however typed', () {
    expect(formatShareCode('ABCD2345'), 'ABCD-2345');
    expect(normalizeShareCode(' abcd-2345 '), 'ABCD2345');
  });

  testWidgets('sharing a plan shows its code', (tester) async {
    const plan = WorkoutPlan(id: 'p1', name: 'Push', items: [
      PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push),
    ]);
    await pumpScreen(tester, const PlanEditorScreen(plan: plan), overrides: [sharingRepositoryProvider.overrideWithValue(FakeSharing())]);

    await tester.tap(find.byKey(const Key('plan.share')));
    await tester.pumpAndSettle();
    expect(find.text('Share "Push"'), findsOneWidget);
    expect(find.text('ABCD-2345'), findsOneWidget);
  });

  testWidgets('a plan from a code: wrong code says so, the right one previews and adds', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sharing = FakeSharing();
    await pumpScreen(tester, const TodayScreen(), overrides: [
      sharingRepositoryProvider.overrideWithValue(sharing),
      exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [])),
      workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
    ]);

    await tester.tap(find.byKey(const Key('plans.new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plans.new.code')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('import.code')), 'aaaa-bbbb');
    await tester.pump();
    await tester.tap(find.byKey(const Key('import.look')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing is shared under this code.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('import.code')), 'wxyz-6789');
    await tester.pump();
    await tester.tap(find.byKey(const Key('import.look')));
    await tester.pumpAndSettle();
    expect(find.text("Friend's legs"), findsOneWidget);
    expect(find.text('• Squat · 5 × 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import.add')));
    await tester.pumpAndSettle();
    expect(sharing.imported, ['WXYZ6789']);
    expect(find.text('Plan "Friend\'s legs" added'), findsOneWidget);
  });
}
