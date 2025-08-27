import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;

  String? get token => _token;

  bool get isAuthenticated => _token != null;

  /// Wczytaj token z secure storage przy starcie aplikacji
  Future<void> loadToken() async {
    _token = await _storage.read(key: 'auth_token');
    notifyListeners();
  }

  /// Zaloguj użytkownika i zapisz token
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://twoje-api.com/login'),
      headers: {'Content-Type': 'application/json'},
      body: '{"email":"$email", "password":"$password"}',
    );

    if (response.statusCode == 200) {
      final token = response.body; // zakładamy, że API zwraca token w body
      _token = token;
      await _storage.write(key: 'auth_token', value: token);
      notifyListeners();
      return true;
    }

    return false;
  }
  
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  /// Pomocnicza metoda do wysyłania autoryzowanych requestów
  Future<http.Response> getAuthorized(String endpoint) async {
    if (_token == null) throw Exception('Brak tokena');

    return await http.get(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
  }
}
