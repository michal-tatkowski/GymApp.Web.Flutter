import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/core/providers/retry.dart';
import 'package:gymapp_web/features/auth/data/auth_api.dart';
import 'package:gymapp_web/features/auth/data/auth_local_storage.dart';
import 'package:gymapp_web/features/auth/data/auth_repository.dart';
import 'package:gymapp_web/features/auth/data/models/auth_tokens.dart';
import 'package:gymapp_web/features/gym/exercises/data/exercise_api.dart';
import 'package:gymapp_web/features/gym/exercises/data/exercise_repository.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/create_exercise_request.dart';
import 'package:gymapp_web/features/gym/exercises/data/models/exercise.dart';
import 'package:gymapp_web/features/gym/onboarding/onboarding.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_models.dart';
import 'package:gymapp_web/features/gym/plans/data/plan_repository.dart';
import 'package:gymapp_web/features/gym/plans/presentation/plan_providers.dart';
import 'package:gymapp_web/features/gym/workouts/presentation/rest_alarm.dart';
import 'package:gymapp_web/features/profile/data/models/update_profile_request.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/data/profile_api.dart';
import 'package:gymapp_web/features/profile/data/profile_repository.dart';
import 'package:gymapp_web/features/settings/presentation/reminders.dart';
import 'package:gymapp_web/l10n/app_localizations.dart';

/// Pumps [screen] inside a MaterialApp with the app's localizations (English
/// unless [locale] says otherwise) and the given provider overrides.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  RestAlarm? restAlarm,
  PlanRepository? plans,
  ReminderScheduler? reminders,
  ThemeData? theme,
  double textScale = 1,
  bool onboarding = false,
}) async {
  OnboardingGate.checked = false;
  await tester.pumpWidget(ProviderScope(
    retry: noRetry,
    // Tests never talk to the real notification plugin.
    overrides: [
      restAlarmProvider.overrideWithValue(restAlarm ?? FakeRestAlarm()),
      planRepositoryProvider.overrideWithValue(plans ?? FakePlanRepository()),
      reminderSchedulerProvider.overrideWithValue(reminders ?? FakeReminderScheduler()),
      onboardingEnabledProvider.overrideWithValue(onboarding),
      ...overrides,
    ],
    child: MaterialApp(
      theme: theme,
      builder: textScale == 1
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

// ─── Fakes ────────────────────────────────────────────────────────────────

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository(this.profile) : super(api: ProfileApi(Dio()));

  UserProfile profile;
  Object? loadError;
  Object? saveError;
  final saved = <UpdateProfileRequest>[];
  int loads = 0;

  @override
  Future<UserProfile> getProfile() async {
    loads++;
    if (loadError != null) throw loadError!;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(UpdateProfileRequest req) async {
    saved.add(req);
    if (saveError != null) throw saveError!;
    return profile = UserProfile(
      nickname: (req.nickname?.isEmpty ?? true) ? null : req.nickname,
      firstName: (req.firstName?.isEmpty ?? true) ? null : req.firstName,
      lastName: (req.lastName?.isEmpty ?? true) ? null : req.lastName,
      gender: req.gender ?? profile.gender,
      height: req.height ?? profile.height,
      weight: req.weight ?? profile.weight,
      dateOfBirth: req.dateOfBirth ?? profile.dateOfBirth,
      bmi: profile.bmi,
    );
  }
}

class FakeExerciseRepository extends ExerciseRepository {
  FakeExerciseRepository(this.exercises) : super(api: ExerciseApi(Dio()));

  final List<Exercise> exercises;
  Object? createError;
  Object? loadError;
  final queries = <({ExerciseCategory? category, String? search, int page})>[];

  @override
  Future<List<Exercise>> getExercises({ExerciseCategory? category, String? search, bool favoritesOnly = false, int page = 1, int pageSize = 20}) async {
    if (loadError != null) throw loadError!;
    queries.add((category: category, search: search, page: page));
    final q = (search ?? '').toLowerCase();
    // Like the API: favorites first, then the original order.
    final sorted = [...exercises.where((e) => e.isFavorite), ...exercises.where((e) => !e.isFavorite)];
    return sorted
        .where((e) => category == null || e.category == category)
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .where((e) => !favoritesOnly || e.isFavorite)
        .skip((page - 1) * pageSize)
        .take(pageSize)
        .toList();
  }

  Object? favoriteError;
  final favoriteCalls = <(String, bool)>[];

  @override
  Future<void> setFavorite(String exerciseId, bool favorite) async {
    favoriteCalls.add((exerciseId, favorite));
    if (favoriteError != null) throw favoriteError!;
    final i = exercises.indexWhere((e) => e.id == exerciseId);
    if (i >= 0) exercises[i] = exercises[i].copyWith(isFavorite: favorite);
  }

  @override
  Future<Exercise> createExercise(CreateExerciseRequest req) async {
    if (createError != null) throw createError!;
    final created = Exercise(
      id: 'new-${exercises.length}',
      name: req.name,
      category: req.category,
      description: req.description,
      isCustom: true,
      source: ExerciseSource.community,
    );
    exercises.add(created);
    return created;
  }
}

/// No saved session (the real storage needs the secure storage plugin).
class EmptyAuthStorage extends AuthLocalStorage {
  @override
  Future<AuthTokens?> restore() async => null;

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens(AuthTokens tokens, {required bool rememberMe}) async {}

  @override
  Future<void> clear() async {}
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.loginError}) : super(api: AuthApi(Dio()), storage: EmptyAuthStorage());

  final Object? loginError;
  final logins = <String>[];

  @override
  Future<void> login({required String email, required String password, required bool rememberMe}) async {
    logins.add(email);
    if (loginError != null) throw loginError!;
  }

  @override
  Future<bool> restoreSession() async => false;

  /// The only code the fake accepts (API: 400 `InvalidCode` otherwise).
  static const validCode = '123456';
  final calls = <String>[];

  @override
  Future<void> register({required String email, required String password}) async => calls.add('register $email');

  @override
  Future<void> confirmEmail({required String email, required String code, required bool rememberMe}) async {
    calls.add('confirm $email $code');
    if (code != validCode) throw const ValidationFailure('The code is invalid or has expired.', 'InvalidCode');
  }

  @override
  Future<void> resendConfirmation(String email) async => calls.add('resend $email');

  @override
  Future<void> forgotPassword(String email) async => calls.add('forgot $email');

  @override
  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    calls.add('reset $email $code $newPassword');
    if (code != validCode) throw const ValidationFailure('The code is invalid or has expired.', 'InvalidCode');
  }

  /// Accepts only [validPassword], like the API (400 `WrongPassword` otherwise).
  static const validPassword = 'secret123';
  int deletions = 0;

  @override
  Future<void> deleteAccount(String password) async {
    if (password != validPassword) throw const ValidationFailure('Incorrect password.', 'WrongPassword');
    deletions++;
  }
}

/// Records what the rest timer asked the system notifications to do.
class FakeRestAlarm implements RestAlarm {
  final calls = <String>[];
  DateTime? endsAt;
  bool onTime = true;

  @override
  Future<void> requestPermission() async => calls.add('permission');
  @override
  Future<void> showInBackground({required DateTime endsAt, required AppLocalizations t}) async {
    this.endsAt = endsAt;
    calls.add('background');
  }

  @override
  Future<void> clear() async => calls.add('clear');
  @override
  Future<bool> canAlertOnTime() async => onTime;
  @override
  Future<void> openExactAlarmSettings() async => calls.add('exactSettings');

  final sessionNotes = <String>[];
  final actionController = StreamController<String>.broadcast();

  @override
  Future<void> showSession({required String title, required String body, required AppLocalizations t}) async =>
      sessionNotes.add('$title | $body');
  @override
  Future<void> clearSession() async => calls.add('clearSession');
  @override
  Stream<String> get actions => actionController.stream;
}

/// In-memory api/Plans.
class FakePlanRepository extends PlanRepository {
  FakePlanRepository([List<WorkoutPlan>? plans]) : plans = [...?plans], super(Dio());

  final List<WorkoutPlan> plans;
  Object? error;
  final saved = <PlanRequest>[];
  int _id = 0;

  List<PlanTemplate> templates = const [];

  @override
  Future<List<PlanTemplate>> getTemplates() async => templates;

  @override
  Future<List<WorkoutPlan>> getPlans() async {
    if (error != null) throw error!;
    return List.of(plans);
  }

  @override
  Future<WorkoutPlan> create(PlanRequest req) async {
    if (error != null) throw error!;
    saved.add(req);
    final plan = WorkoutPlan(id: 'p${_id++}', name: req.name.trim(), items: req.items);
    plans.insert(0, plan);
    return plan;
  }

  @override
  Future<WorkoutPlan> update(String id, PlanRequest req) async {
    if (error != null) throw error!;
    saved.add(req);
    final plan = WorkoutPlan(id: id, name: req.name.trim(), items: req.items);
    plans[plans.indexWhere((p) => p.id == id)] = plan;
    return plan;
  }

  @override
  Future<void> delete(String id) async => plans.removeWhere((p) => p.id == id);
}

/// Records what the reminders asked the system to schedule.
class FakeReminderScheduler implements ReminderScheduler {
  bool allow = true;
  final applied = <ReminderSettings>[];

  @override
  Future<bool> requestPermission() async => allow;
  @override
  Future<void> apply(ReminderSettings settings, AppLocalizations t) async => applied.add(settings);
}
