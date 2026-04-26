import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/secure_storage_keys.dart';
import 'models/auth_tokens.dart';

/// Persists auth tokens using platform-level secure storage.
///
/// Semantics:
///  - `saveTokens(..., rememberMe: true)`  → tokens persist across restarts.
///  - `saveTokens(..., rememberMe: false)` → only kept in memory this session.
///  - `clear()`                            → wipes everything (logout).
class AuthLocalStorage {
  AuthLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // In-memory cache — avoids hitting secure storage on every request.
  AuthTokens? _cached;

  Future<void> saveTokens(AuthTokens tokens, {required bool rememberMe}) async {
    _cached = tokens;
    if (rememberMe) {
      await _storage.write(key: StorageKeys.accessToken, value: tokens.accessToken);
      if (tokens.refreshToken != null) {
        await _storage.write(key: StorageKeys.refreshToken, value: tokens.refreshToken);
      }
      await _storage.write(key: StorageKeys.rememberMe, value: 'true');
    } else {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
      await _storage.write(key: StorageKeys.rememberMe, value: 'false');
    }
  }

  /// Loads persisted tokens into memory at app start.
  /// Returns `null` if user did not tick "remember me" last session.
  Future<AuthTokens?> restore() async {
    final remember = await _storage.read(key: StorageKeys.rememberMe);
    if (remember != 'true') return null;

    final access = await _storage.read(key: StorageKeys.accessToken);
    if (access == null || access.isEmpty) return null;

    final refresh = await _storage.read(key: StorageKeys.refreshToken);
    _cached = AuthTokens(accessToken: access, refreshToken: refresh);
    return _cached;
  }

  Future<String?> getAccessToken() async =>
      _cached?.accessToken ?? await _storage.read(key: StorageKeys.accessToken);

  Future<String?> getRefreshToken() async =>
      _cached?.refreshToken ?? await _storage.read(key: StorageKeys.refreshToken);

  Future<void> saveRefreshToken(String newRefreshToken) async {
    final access = _cached?.accessToken ?? await _storage.read(key: StorageKeys.accessToken) ?? '';
    _cached = AuthTokens(accessToken: access, refreshToken: newRefreshToken);
    final remember = await _storage.read(key: StorageKeys.rememberMe);
    if (remember == 'true') {
      await _storage.write(key: StorageKeys.refreshToken, value: newRefreshToken);
    }
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    final refresh = _cached?.refreshToken ?? await _storage.read(key: StorageKeys.refreshToken);
    _cached = AuthTokens(accessToken: newAccessToken, refreshToken: refresh);
    final remember = await _storage.read(key: StorageKeys.rememberMe);
    if (remember == 'true') {
      await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);
    }
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.write(key: StorageKeys.rememberMe, value: 'false');
  }
}
