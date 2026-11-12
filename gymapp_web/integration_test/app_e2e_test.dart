// End-to-end on a real device / emulator: the whole app with its real plugins
// (encrypted token storage, shared preferences, notifications, files) and an
// in-memory backend in place of the HTTP API (the API repository is private, so
// CI cannot start it next to the app).
//
//   flutter test integration_test            # on a running emulator / phone
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/app/app.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/features/auth/data/auth_api.dart';
import 'package:gymapp_web/features/auth/data/auth_local_storage.dart';
import 'package:gymapp_web/features/auth/data/models/auth_requests.dart';
import 'package:gymapp_web/features/auth/data/models/auth_tokens.dart';
import 'package:gymapp_web/features/auth/presentation/auth_providers.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/exercises_providers.dart';
import 'package:gymapp_web/features/gym/exercises/presentation/illustration/motion.dart';
import 'package:gymapp_web/features/gym/goals/goals_data.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_providers.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_timer.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/workout_providers.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/presentation/profile_providers.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/fake_workouts.dart';
import '../test/helpers/test_app.dart';

/// The auth endpoints in memory: one account, the e-mail code is 123456. The real
/// AuthRepository and the real encrypted storage are used around it.
class _Backend extends AuthApi {
  _Backend() : super(Dio());

  static const code = '123456';
  final accounts = <String, String>{};
  final confirmed = <String>{};

  static const _tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

  @override
  Future<void> register(RegisterRequest req) async => accounts[req.email] = req.password;

  @override
  Future<AuthTokens> login(LoginRequest req) async {
    if (accounts[req.email] != req.password) {
      throw DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401, data: {'code': 'InvalidCredentials'}),
      );
    }
    if (!confirmed.contains(req.email)) {
      throw DioException.badResponse(
        statusCode: 403,
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 403, data: {'code': 'EmailNotConfirmed'}),
      );
    }
    return _tokens;
  }

  @override
  Future<AuthTokens> confirmEmail(String email, String code) async {
    if (code != _Backend.code) {
      throw DioException.badResponse(
        statusCode: 400,
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 400, data: {'title': 'Invalid code', 'code': 'InvalidCode'}),
      );
    }
    confirmed.add(email);
    return _tokens;
  }

  @override
  Future<void> resendConfirmation(String email) async {}

  @override
  Future<void> logout(String? refreshToken) async {}
}

class _NoGoals extends GoalRepository {
  _NoGoals() : super(Dio());

  @override
  Future<List<Goal>> list() async => const [];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The looping exercise illustration would keep pumpAndSettle waiting forever (like in test/flutter_test_config.dart).
  MotionView.animate = false;

  const plan = WorkoutPlan(id: 'p1', name: 'Push A', items: [
    PlanItem(exerciseId: 'bench', exerciseName: 'Bench press', category: ExerciseCategory.push, sets: 2, repsMin: 8, repsMax: 8),
  ]);

  Future<(FakeWorkoutRepository, ProviderContainer)> launch(WidgetTester tester, {FakeWorkoutRepository? workouts}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('settings.locale', 'en');
    await AuthLocalStorage().clear(); // start signed out, on the real encrypted storage
    final repo = workouts ?? FakeWorkoutRepository();
    final backend = _Backend();
    final container = ProviderContainer(
      retry: noRetry,
      overrides: [
        authApiProvider.overrideWithValue(backend),
        onboardingEnabledProvider.overrideWithValue(false),
        planRepositoryProvider.overrideWithValue(FakePlanRepository([plan])),
        workoutRepositoryProvider.overrideWithValue(repo),
        exerciseRepositoryProvider.overrideWithValue(FakeExerciseRepository(const [
          Exercise(id: 'bench', name: 'Bench press', category: ExerciseCategory.push, isFavorite: true),
        ])),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository(const UserProfile(nickname: 'E2E'))),
        goalRepositoryProvider.overrideWithValue(_NoGoals()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const GymApp()));
    await tester.pumpAndSettle();
    return (repo, container);
  }

  Future<void> signUpAndConfirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'e2e@test.pl');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Confirm your email'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('code.field')), _Backend.code);
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify.confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('sign up with the e-mail code; the tokens land in the encrypted storage', (tester) async {
    final (_, container) = await launch(tester);
    await signUpAndConfirm(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    // Tokens really are in the encrypted storage (a cold start would restore them).
    expect(await AuthLocalStorage().restore(), isNotNull);
    container.read(restTimerProvider.notifier).stop();
  });

  testWidgets('a workout from a plan, set by set, ends in the history', (tester) async {
    final (repo, container) = await launch(tester);
    await signUpAndConfirm(tester);

    await tester.tap(find.byKey(const Key('plan.start.p1')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      final done = find.descendant(of: find.byKey(Key('session.set$i')), matching: find.byKey(const Key('done')));
      // On a small screen the set can sit under the bottom bar: bring it to the middle first.
      await Scrollable.ensureVisible(tester.element(done), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('session.finish')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('session.summary')), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(repo.posted.single.sets, hasLength(2));
    expect(repo.sessions.single.name, 'Push A');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress.history')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Push A'), findsWidgets);
    container.read(restTimerProvider.notifier).stop();
  });

  testWidgets('offline: a quick log waits in the queue and is sent when back online', (tester) async {
    final repo = FakeWorkoutRepository();
    final (_, container) = await launch(tester, workouts: repo);
    await signUpAndConfirm(tester);

    repo.offline = true;
    await tester.tap(find.byKey(const Key('today.log.bench')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workout.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pending.bar')), findsOneWidget);
    expect(repo.posted, isEmpty);

    repo.offline = false;
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pending.bar')), findsNothing);
    expect(repo.posted, hasLength(1));
    container.read(restTimerProvider.notifier).stop();
  });
}
