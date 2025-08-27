import 'package:gymapp_web/services/api_service.dart';

class LoginService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final api = ApiService();
  
  LoginService({
    this.baseUrl = '',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });
  
  Future login() async {
    final response = await api.post("Auth/Login", body: {
      'email': 'test@test.pl',
      'password': '123123'
    });
  }
}