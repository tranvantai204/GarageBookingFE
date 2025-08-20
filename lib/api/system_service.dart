import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SystemService {
  static Future<Map<String, dynamic>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/system'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return {'items': data['data']};
    }
    throw Exception('Failed to load settings');
  }

  static Future<void> upsert(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/system'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'key': key, 'value': value}),
    );
  }
}
