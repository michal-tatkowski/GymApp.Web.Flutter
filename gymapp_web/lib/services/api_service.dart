import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../models/api_exception.dart';
import 'jwt_token_service.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiService({
    this.baseUrl = 'http://10.0.2.2:5035/api/',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? headers,
  ) async {
    final Map<String, String> merged = {...defaultHeaders, ...?headers};
    final token = JwtTokenService.instance.getToken();
    if (token is String) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await _safe(
      () async => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _safe(
      () async => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _safe(
      () async => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final response = await _safe(
      () async => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _buildHeaders(headers),
      ),
    );
    return _handleResponse(response);
  }

  Future<http.Response> _safe(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw ApiException(-1, 'Brak połączenia z internetem.');
    } on TimeoutException {
      throw ApiException(
        -1,
        'Przekroczono czas oczekiwania na odpowiedź serwera.',
      );
    } catch (e) {
      throw ApiException(-1, 'Nieoczekiwany błąd sieci: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : true;
    } else {
      final raw = response.body;
      String message = 'Wystąpił błąd (HTTP $statusCode).';
      throw ApiException(statusCode, message);
    }
  }
}
