import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class DriverApplicationService {
  static Future<Map<String, dynamic>> submit({
    required String hoTen,
    required String soDienThoai,
    required String email,
    String? gplxUrl,
    String? cccdUrl,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver-applications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        'email': email,
        if (gplxUrl != null && gplxUrl.isNotEmpty) 'gplxUrl': gplxUrl,
        if (cccdUrl != null && cccdUrl.isNotEmpty) 'cccdUrl': cccdUrl,
        'note': note,
      }),
    );
    return jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
  }

  static Future<List<Map<String, dynamic>>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/driver-applications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<bool> approve(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver-applications/$id/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return resp.statusCode == 200;
  }

  static Future<bool> reject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/driver-applications/$id/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return resp.statusCode == 200;
  }
}
