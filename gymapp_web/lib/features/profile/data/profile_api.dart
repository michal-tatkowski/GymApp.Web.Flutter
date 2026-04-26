import 'package:dio/dio.dart';

import 'models/update_profile_request.dart';
import 'models/user_profile.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    final res = await _dio.get<dynamic>('Profile');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest req) async {
    final res = await _dio.put<dynamic>('Profile', data: req.toJson());
    // Backend may return 204 (no body) or the updated profile.
    if (res.statusCode == 204 || res.data == null) {
      // Re-fetch to get the authoritative state.
      return getProfile();
    }
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}
