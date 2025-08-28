import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtTokenService {
  JwtTokenService._privateConstructor();

  static final JwtTokenService instance = JwtTokenService._privateConstructor();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _key = 'jwt_token';
  static const _rememberKey = 'remember_me';
  String? _currentToken;

  Future<void> saveToken(String token, bool rememberMe) async {
    _currentToken = token;

    if (rememberMe) {
      await _storage.write(key: _key, value: token);
      await _storage.write(key: _rememberKey, value: 'true');
    } else {
      await _storage.delete(key: _key);
      await _storage.write(key: _rememberKey, value: 'false');
    }
  }
  
  Future<String?> getToken() async {
    if (_currentToken != null) return _currentToken;
    return await _storage.read(key: _key);
  }

  Future<bool> isRemembered() async {
    final isRemembered = await _storage.read(key: _rememberKey);
    return isRemembered == 'true'; //klucz ze storage przychodzi jako 'string' ; nie ma sensu rzutować
  }

  Future<String?> getTokenIfRemembered() async {
    if (await isRemembered()) {
      _currentToken ??= await _storage.read(key: _key);
      return _currentToken;
    }
    return null;
  }
  
  Future<String?> initSession() async {
    _currentToken = await getTokenIfRemembered();
    return _currentToken;
  }

  Future<void> clearToken() async {
    _currentToken = null;
    await _storage.delete(key: _key);
    await _storage.write(key: _rememberKey, value: 'false');
  }
  
  String? get currentToken => _currentToken;
}
