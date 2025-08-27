class User {
  final String guid;
  final String name;
  final String email;
  final String password;

  User({
    required this.guid,
    required this.name,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      guid: json['guid'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
    );
  }
}
