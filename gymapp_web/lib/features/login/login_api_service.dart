import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_web/services/api_service.dart';

class LoginApiService extends ChangeNotifier {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final api = ApiService();
  final _storage = const FlutterSecureStorage();
  String? _token;

  LoginApiService({
    this.baseUrl = '',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  Future<bool> login(String email, String password) async {
    final response = await api.post(
      "Auth/Login",
      body: {'email': '$email', 'password': '$password'},
    );

    String? token;
    if (response is String && response.isNotEmpty) {
      token = response;
    } else if (response is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        response as Map,
      );
      token = map['token'] as String?;
    }

    if (token == null || token.isEmpty) {
      throw Exception(
        'Nieprawidłowa odpowiedź logowania: nie znaleziono tokenu',
      );
    }

    _token = token;
    await _storage.write(key: 'auth_token', value: token);
    api.setAuthToken(token);
    notifyListeners();
    return true;
  }

  Future<void> getUsers() async {
    final response = await api.get("User/GetUsers");
    print(response);
  }
  
  Future<void> removeToken() async {
    await _storage.delete(key: "aut_token");
    api.setAuthToken("");
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
    api.setAuthToken(null);
    notifyListeners();
  }
}
