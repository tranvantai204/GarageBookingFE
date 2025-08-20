import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class RefundApi {
  static Future<List<Map<String, dynamic>>> list({String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/refunds${status != null ? '?status=$status' : ''}',
    );
    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (resp.statusCode == 200 && jsonResp['success'] == true) {
      return List<Map<String, dynamic>>.from(jsonResp['data'] ?? []);
    }
    throw Exception(jsonResp['message'] ?? 'Load refunds failed');
  }

  static Future<Map<String, dynamic>> approve(
    String id, {
    required bool approve,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final resp = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/refunds/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': approve ? 'approve' : 'reject'}),
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    return {
      'success': resp.statusCode == 200 && jsonResp['success'] == true,
      'data': jsonResp['data'],
      'message': jsonResp['message'],
    };
  }
}

class AdminService {
  static Future<List<Map<String, dynamic>>> fetchDrivers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List list = (data['data'] ?? []);
      return list
          .where((u) => (u['vaiTro'] == 'driver' || u['vaiTro'] == 'tai_xe'))
          .map<Map<String, dynamic>>(
            (u) => {'id': u['_id'], 'name': u['hoTen'] ?? 'Tài xế'},
          )
          .toList();
    }
    throw Exception('Failed to load drivers');
  }

  static Future<List<Map<String, dynamic>>> fetchOverdueBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/overdue-bookings'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch overdue bookings');
  }

  static Future<void> setVip(String userId, bool isVip) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/vip'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isVip': isVip}),
    );
  }

  static Future<void> broadcast({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/broadcast'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'body': body}),
    );
  }

  static Future<List<Map<String, dynamic>>> fetchAdminNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/admin'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['items'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load admin notifications');
  }

  static Future<void> deleteAdminNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/notifications/admin/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> updateAdminNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/notifications/admin/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['item'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update admin notification');
  }
}
