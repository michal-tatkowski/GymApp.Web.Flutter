import 'user_profile.dart';

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.nickname,
    this.firstName,
    this.lastName,
    this.gender = Gender.notSpecified,
    this.height,
    this.weight,
    this.dateOfBirth,
  });

  final String? nickname;
  final String? firstName;
  final String? lastName;
  final Gender gender;
  final double? height;
  final double? weight;
  final DateTime? dateOfBirth;

  factory UpdateProfileRequest.fromProfile(UserProfile p) => UpdateProfileRequest(
        nickname: p.nickname,
        firstName: p.firstName,
        lastName: p.lastName,
        gender: p.gender ?? Gender.notSpecified,
        height: p.height,
        weight: p.weight,
        dateOfBirth: p.dateOfBirth,
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender.toJson(),
        'height': height,
        'weight': weight,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
      };
}
