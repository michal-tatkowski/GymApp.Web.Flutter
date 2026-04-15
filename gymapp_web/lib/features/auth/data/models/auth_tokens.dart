/// Immutable container for JWT access + refresh tokens.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;

  /// Parses the tokens from typical backend responses.
  ///
  /// Supports multiple common shapes:
  ///   - `{"accessToken": "...", "refreshToken": "..."}`
  ///   - `{"token": "..."}`             (legacy, no refresh)
  ///   - `"<raw JWT string>"`           (legacy endpoint returning string)
  factory AuthTokens.fromResponse(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return AuthTokens(accessToken: data);
    }
    if (data is Map) {
      final access = (data['accessToken'] ?? data['token']) as String?;
      if (access == null || access.isEmpty) {
        throw const FormatException('Brak tokenu dostępu w odpowiedzi.');
      }
      return AuthTokens(
        accessToken: access,
        refreshToken: data['refreshToken'] as String?,
      );
    }
    throw const FormatException('Nieznany format odpowiedzi logowania.');
  }
}
