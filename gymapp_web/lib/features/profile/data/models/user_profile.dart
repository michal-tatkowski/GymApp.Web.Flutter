enum Gender { male, female, other }

extension GenderJson on Gender {
  static Gender? fromJson(dynamic v) {
    if (v == null) return null;
    if (v is int) {
      return Gender.values.elementAtOrNull(v);
    }
    switch (v.toString().toLowerCase()) {
      case 'male':
      case '0':
        return Gender.male;
      case 'female':
      case '1':
        return Gender.female;
      case 'other':
      case '2':
        return Gender.other;
    }
    return null;
  }

  int toJson() => index;
}

class UserProfile {
  const UserProfile({
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        gender: GenderJson.fromJson(json['gender']),
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        dateOfBirth: json['dateOfBirth'] == null
            ? null
            : DateTime.tryParse(json['dateOfBirth'] as String),
      );

  UserProfile copyWith({
    String? nickname,
    String? firstName,
    String? lastName,
    Gender? gender,
    double? height,
    double? weight,
    DateTime? dateOfBirth,
    bool clearGender = false,
    bool clearDateOfBirth = false,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        gender: clearGender ? null : (gender ?? this.gender),
        height: height ?? this.height,
        weight: weight ?? this.weight,
        dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      );
}
