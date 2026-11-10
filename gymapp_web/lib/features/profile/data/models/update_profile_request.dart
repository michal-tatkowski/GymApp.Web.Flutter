import 'user_profile.dart';

/// PUT api/Profile body. The API does a partial update:
///  - a field that is `null` (omitted) stays unchanged,
///  - an empty string clears a text field.
/// The edit form always sends all text fields, so clearing a field works.
class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.nickname,
    this.firstName,
    this.lastName,
    this.gender,
    this.height,
    this.weight,
    this.dateOfBirth,
  });

  final String? nickname;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final double? height;
  final double? weight;
  final DateTime? dateOfBirth;

  Map<String, dynamic> toJson() => {
        if (nickname != null) 'nickname': nickname,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (gender != null) 'gender': gender!.toJson(),
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        // Date only — no time zone shift between the device and the server.
        if (dateOfBirth != null) 'dateOfBirth': _date(dateOfBirth!),
      };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
