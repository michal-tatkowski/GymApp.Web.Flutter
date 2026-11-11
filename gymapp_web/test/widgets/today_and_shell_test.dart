import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/features/auth/presentation/auth_providers.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/today/today_screen.dart';
import 'package:gymapp_web/features/gym/workouts/data/workout_models.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/presentation/profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_workouts.dart';
import '../helpers/test_app.dart';

void main() {
  final today = DateUtils.dateOnly(DateTime.now());

  List<Exercise> catalog() => [
        const Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push, isFavorite: true),
        const Exercise(id: 'squat', name: 'Squat', category: ExerciseCategory.legs, isFavorite: true),
        const Exercise(id: 'row', name: 'Barbell row', category: ExerciseCategory.pull),
      ];

  group('Today', () {
    Future<FakeWorkoutRepository> pumpToday(WidgetTester tester, {List<Exercise>? exercises}) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final workouts = FakeWorkoutRepository()
        ..seed('bench', today.subtract(const Duration(days: 2)), [const WorkoutSet(reps: 10, weight: 100)]);
      await pumpScreen(tester, const TodayScreen(), overrides: [
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(exercises ?? catalog())),
        workoutRepositoryProvider.overrideWithValue(workouts),
      ]);
      return workouts;
    }

    testWidgets('favorites are listed for quick log with the last workout', (tester) async {
      await pumpToday(tester);

      expect(find.text('Quick log'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Barbell row'), findsNothing); // not a favorite
      expect(find.textContaining('1000 kg'), findsOneWidget);
      expect(find.text('Not trained yet'), findsOneWidget);
      expect(find.text('Done today'), findsNothing);
    });

    testWidgets('"+" opens the form prefilled with the last workout; saving shows it under "Done today"', (tester) async {
      final workouts = await pumpToday(tester);

      await tester.tap(find.byKey(const Key('today.log.bench')));
      await tester.pumpAndSettle();

      expect(tester.widget<TextFormField>(find.byKey(const Key('workout.set0.reps'))).controller!.text, '10');
      await tester.enterText(find.byKey(const Key('workout.set0.reps')), '12');
      await tester.tap(find.byKey(const Key('workout.save')));
      await tester.pumpAndSettle();

      expect(workouts.entries['bench']!.length, 2);
      expect(find.text('Done today'), findsOneWidget);
      expect(find.text('1200 kg'), findsOneWidget);
    });

    testWidgets('no favorites: explains the star and links to the exercises', (tester) async {
      await pumpToday(tester, exercises: [const Exercise(id: 'x', name: 'X', category: ExerciseCategory.core)]);

      expect(find.textContaining('Star exercises'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Browse exercises'), findsOneWidget);
    });
  });

  group('Navigation', () {
    Future<void> pumpApp(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'settings.locale': 'en'});

      await tester.pumpWidget(ProviderScope(
        retry: noRetry,
        overrides: [
          authLocalStorageProvider.overrideWithValue(EmptyAuthStorage()),
          restAlarmProvider.overrideWithValue(FakeRestAlarm()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(catalog())),
          workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository(const UserProfile(nickname: 'Tester'))),
        ],
        child: const GymApp(),
      ));
      await tester.pumpAndSettle();
      // Log in through the real login screen.
      await tester.enterText(find.byType(TextFormField).at(0), 'jan@test.pl');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pumpAndSettle();
    }

    testWidgets('phone: bottom bar switches between the four tabs', (tester) async {
      await pumpApp(tester, const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Quick log'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Exercises')));
      await tester.pumpAndSettle();
      expect(find.text('Barbell row'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Progress')));
      await tester.pumpAndSettle();
      expect(find.textContaining('No workouts yet'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      expect(find.text('Tester'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('tab keeps its own stack: details stay open after switching tabs', (tester) async {
      await pumpApp(tester, const Size(400, 800));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Exercises')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbell row'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workout.log')), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Today')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Exercises')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workout.log')), findsOneWidget);
    });

    testWidgets('Android Back: pops the tab stack, then goes to Today, then leaves the app', (tester) async {
      await pumpApp(tester, const Size(400, 800));
      Future<bool> systemBack() async {
        final handled = await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        return handled;
      }

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Exercises')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbell row'));
      await tester.pumpAndSettle();

      expect(await systemBack(), isTrue); // details -> list
      expect(find.byKey(const Key('workout.log')), findsNothing);
      expect(find.text('Barbell row'), findsOneWidget);

      expect(await systemBack(), isTrue); // Exercises -> Today, app stays open
      expect(find.text('Quick log'), findsOneWidget);

      expect(await systemBack(), isFalse); // Today: Android closes the app
    });

    testWidgets('wide screen: navigation rail instead of the bottom bar', (tester) async {
      await pumpApp(tester, const Size(1200, 800));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('logout lives in Settings', (tester) async {
      await pumpApp(tester, const Size(400, 800));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Remember me'), findsOneWidget); // back on the login screen
    });
  });
}
