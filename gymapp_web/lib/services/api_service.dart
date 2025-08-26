import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService<T> {
  final String baseUrl = 'http://10.0.2.2:5035/api';

  Future<T> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return fromJson(jsonData);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => fromJson(item)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }
}
