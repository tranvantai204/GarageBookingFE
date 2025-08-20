import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class VoucherService {
  static Future<List<Map<String, dynamic>>> fetchVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vouchers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch vouchers');
  }

  static Future<Map<String, dynamic>> createVoucher(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/vouchers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return (data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create voucher');
  }

  static Future<Map<String, dynamic>> updateVoucher(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update voucher');
  }

  static Future<void> deleteVoucher(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete voucher');
    }
  }

  static Future<int> validate(String code, int amount, {String? route}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/vouchers/validate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code, 'amount': amount, 'route': route}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['discount'] as num).toInt();
    }
    throw Exception('Voucher invalid');
  }
}
