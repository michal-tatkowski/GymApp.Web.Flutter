import 'package:flutter/material.dart';
import 'package:gymapp_web/services/api_service.dart';

import '../../models/register_request.dart';

class RegisterApiService extends ChangeNotifier {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final api = ApiService();

  RegisterApiService({
    this.baseUrl = '',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  Future<dynamic> register(RegisterRequest request) async {
    return await api.post('Auth/Register', body: request.toJson());
  }
}
