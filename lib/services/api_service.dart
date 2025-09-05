import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  final String baseUrl;
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    return _decode(resp);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(resp);
  }

  Map<String, dynamic> _decode(http.Response resp) {
    try {
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic>) return data;
      return {
        'success': resp.statusCode >= 200 && resp.statusCode < 300,
        'data': data,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid response',
        'status': resp.statusCode,
        'raw': resp.body,
      };
    }
  }
}
