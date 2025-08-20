import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class WalletService {
  static Future<Map<String, dynamic>> getMyWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/wallet/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    return {
      'success': resp.statusCode == 200 && jsonResp['success'] == true,
      'data': jsonResp['data'],
      'message': jsonResp['message'],
    };
  }
}
