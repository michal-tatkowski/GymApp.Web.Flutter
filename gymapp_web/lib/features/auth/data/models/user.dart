/// User entity — read-only representation of the authenticated account.
///
/// Note: never include the raw password here. Auth payloads are internal
/// to the data layer (see [LoginRequest] / [RegisterRequest]).
class User {
  const User({
    required this.id,
    required this.email,
    this.name,
  });

  final String id;
  final String email;
  final String? name;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['guid'] ?? json['id']).toString(),
        email: json['email'] as String,
        name: json['name'] as String?,
      );
}
