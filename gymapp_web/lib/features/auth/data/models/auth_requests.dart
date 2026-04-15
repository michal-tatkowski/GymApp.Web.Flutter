/// Auth request DTOs (data transfer objects).
///
/// Kept in `data/` because they are tied to the REST API contract —
/// the presentation layer should pass primitives (email, password) to
/// the repository and never touch these directly.

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
