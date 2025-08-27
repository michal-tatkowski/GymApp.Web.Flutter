import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _authToken;
  
  ApiService({
    this.baseUrl = 'http://10.0.2.2:5035/api/',
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final Map<String, String> merged = {...defaultHeaders, ...?headers};
    final token = _authToken ?? await _storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }
  
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await _safe(() async => http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _buildHeaders(headers),
        ));
    return _handleResponse(response);
  }
  
  Future<dynamic> post(String endpoint, {Object? body, Map<String, String>? headers}) async {
    final response = await _safe(() async => http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        ));
    return _handleResponse(response);
  }
  
  Future<dynamic> put(String endpoint, {Object? body, Map<String, String>? headers}) async {
    final response = await _safe(() async => http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        ));
    return _handleResponse(response);
  }
  
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final response = await _safe(() async => http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _buildHeaders(headers),
        ));
    return _handleResponse(response);
  }

  // Bezpieczny wrapper na wywołania HTTP – zamienia błędy sieci na ApiException
  Future<http.Response> _safe(Future<http.Response> Function() call) async {
    try {
      // Możesz dodać timeout wg potrzeb, np. .timeout(const Duration(seconds: 20))
      return await call();
    } on SocketException {
      throw ApiException(-1, 'Brak połączenia z internetem.');
    } on TimeoutException {
      throw ApiException(-1, 'Przekroczono czas oczekiwania na odpowiedź serwera.');
    } catch (e) {
      throw ApiException(-1, 'Nieoczekiwany błąd sieci: $e');
    }
  }
  
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } else {
      final raw = response.body;
      String message = 'Wystąpił błąd (HTTP $statusCode).';
      if (raw.isNotEmpty) {
        try {
          final parsed = jsonDecode(raw);
          message = _extractErrorMessage(parsed, raw) ?? message;
        } catch (_) {
          // body nie jest JSON-em – użyj surowej treści
          message = raw;
        }
      }
      throw ApiException(statusCode, message);
    }
  }

  // Ekstrakcja czytelnego komunikatu błędu z popularnych formatów odpowiedzi API
  String? _extractErrorMessage(dynamic parsed, String rawBodyFallback) {
    if (parsed is Map<String, dynamic>) {
      // Typowe pola: message, error, detail
      final direct =
          parsed['message'] ?? parsed['error'] ?? parsed['detail'] ?? parsed['title'];
      if (direct is String && direct.trim().isNotEmpty) return direct;

      // ASP.NET Core ProblemDetails: "errors": { "Field": ["msg1","msg2"] }
      if (parsed['errors'] is Map<String, dynamic>) {
        final errors = parsed['errors'] as Map<String, dynamic>;
        final parts = <String>[];
        errors.forEach((key, value) {
          if (value is List) {
            final msgs = value.whereType<String>().join(', ');
            if (msgs.isNotEmpty) {
              parts.add('$key: $msgs');
            }
          } else if (value is String) {
            parts.add('$key: $value');
          }
        });
        if (parts.isNotEmpty) return parts.join('\n');
      }

      // Inne popularne kształty: { "errors": ["a","b"] } lub { "messages": [...] }
      for (final k in const ['errors', 'messages']) {
        final v = parsed[k];
        if (v is List) {
          final msgs = v.whereType<String>().toList();
          if (msgs.isNotEmpty) return msgs.join('\n');
        }
      }

      // Zdarza się: { "data": { "message": "..." } }
      if (parsed['data'] is Map<String, dynamic>) {
        final data = parsed['data'] as Map<String, dynamic>;
        final inner = data['message'] ?? data['error'];
        if (inner is String && inner.trim().isNotEmpty) return inner;
      }
    } else if (parsed is List) {
      final msgs = parsed.whereType<String>().toList();
      if (msgs.isNotEmpty) return msgs.join('\n');
    }

    // Fallback: surowy body
    return rawBodyFallback.isNotEmpty ? rawBodyFallback : null;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
