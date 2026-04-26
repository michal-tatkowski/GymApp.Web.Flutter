import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failure.dart';
import 'models/update_profile_request.dart';
import 'models/user_profile.dart';
import 'profile_api.dart';

class ProfileRepository {
  ProfileRepository({required this.api});

  final ProfileApi api;

  Future<UserProfile> getProfile() async {
    try {
      return await api.getProfile();
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest req) async {
    try {
      return await api.updateProfile(req);
    } on DioException catch (e) {
      throw mapDioErrorToFailure(e);
    } on FormatException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
