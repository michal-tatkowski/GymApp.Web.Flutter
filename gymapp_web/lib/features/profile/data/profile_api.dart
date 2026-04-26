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
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }
    // 204, null, or empty string — re-fetch to get authoritative state.
    return getProfile();
  }
}
