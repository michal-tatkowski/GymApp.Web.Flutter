import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_web/core/errors/failure.dart';
import 'package:gymapp_web/features/profile/data/models/update_profile_request.dart';
import 'package:gymapp_web/features/profile/data/models/user_profile.dart';
import 'package:gymapp_web/features/profile/data/profile_api.dart';
import 'package:gymapp_web/features/profile/data/profile_repository.dart';
import 'package:gymapp_web/features/profile/presentation/profile_providers.dart';

class _FakeRepo extends ProfileRepository {
  _FakeRepo() : super(api: ProfileApi(Dio()));

  UserProfile profile = const UserProfile(nickname: 'nick', height: 180);
  Object? getError;
  Object? saveError;

  @override
  Future<UserProfile> getProfile() async {
    if (getError != null) throw getError!;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(UpdateProfileRequest req) async {
    if (saveError != null) throw saveError!;
    return profile = UserProfile(nickname: req.nickname, height: req.height ?? profile.height);
  }
}

void main() {
  group('UpdateProfileRequest', () {
    test('omits null fields (partial update) and keeps empty strings (clear)', () {
      final json = UpdateProfileRequest(
        nickname: '',
        firstName: 'Jan',
        gender: Gender.female,
        dateOfBirth: DateTime(1990, 5, 1, 23, 30),
      ).toJson();

      expect(json, {
        'nickname': '',
        'firstName': 'Jan',
        'gender': 2,
        'dateOfBirth': '1990-05-01', // date only — no time zone shift
      });
    });
  });

  test('UserProfile reads nulls of a fresh profile', () {
    final p = UserProfile.fromJson({
      'nickname': null, 'gender': '0', 'height': null, 'weight': null,
      'dateOfBirth': null, 'bmi': null,
    });
    expect(p.gender, Gender.notSpecified);
    expect(p.height, isNull);
    expect(p.dateOfBirth, isNull);
  });

  group('ProfileController', () {
    ProviderContainer container(_FakeRepo repo) {
      final c = ProviderContainer(overrides: [profileRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      return c;
    }

    test('load error is exposed (not swallowed into null)', () async {
      final repo = _FakeRepo()..getError = const NotFoundFailure('Nie znaleziono szczegółów użytkownika.');
      final c = container(repo);

      await expectLater(c.read(profileControllerProvider.future), throwsA(isA<NotFoundFailure>()));
      expect(c.read(profileControllerProvider).error, isA<NotFoundFailure>());
    });

    test('failed save returns the error and keeps the previous profile', () async {
      final repo = _FakeRepo();
      final c = container(repo);
      await c.read(profileControllerProvider.future);
      repo.saveError = const ValidationFailure('Wzrost musi wynosić od 50 do 272 cm.');

      final error = await c.read(profileControllerProvider.notifier).save(const UpdateProfileRequest(height: -5));

      expect(error, isA<ValidationFailure>());
      final state = c.read(profileControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.value!.nickname, 'nick');
    });

    test('successful save stores the profile returned by the API', () async {
      final repo = _FakeRepo();
      final c = container(repo);
      await c.read(profileControllerProvider.future);

      final error = await c.read(profileControllerProvider.notifier).save(const UpdateProfileRequest(nickname: 'nowy'));

      expect(error, isNull);
      expect(c.read(profileControllerProvider).value!.nickname, 'nowy');
    });
  });
}
