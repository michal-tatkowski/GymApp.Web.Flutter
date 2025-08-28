import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymapp_web/services/api_service.dart';
import 'package:gymapp_web/services/jwt_token_service.dart';

class LoginApiService extends ChangeNotifier {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final api = ApiService();
  final _storage = const FlutterSecureStorage();

  LoginApiService({
    this.baseUrl = '',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  Future<(bool, String)> login(String email, String password) async {
    final response = await api.post(
      "Auth/Login",
      body: {'email': email, 'password': password},
    );

    String? token;
    if (response is String && response.isNotEmpty) {
      token = response;
    } else if (response is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        response,
      );
      token = map['token'] as String?;
    }

    if (token == null || token.isEmpty) {
      throw Exception(
        'Nieprawidłowa odpowiedź logowania: nie znaleziono tokenu',
      );
    }
    
    return (true, token);
  }

  Future<void> getUsers() async {
    final response = await api.get("User/GetUsers");
    print(response);
  }
}
