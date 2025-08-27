import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtTokenService{
  JwtTokenService._privateConstructor();
  static final JwtTokenService instance = JwtTokenService._privateConstructor();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _key = 'jwt_token';
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _key);
  }
  
  Future<void> clearToken() async {
    await _storage.delete(key: _key);
  }
}