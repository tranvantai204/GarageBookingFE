import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class RefundService {
  static Future<Map<String, dynamic>> create({
    required String bookingId,
    required int amount,
    String reason = 'Yêu cầu hoàn tiền',
    String method = 'wallet',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      return {'success': false, 'message': 'Chưa đăng nhập'};
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/refunds');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bookingId': bookingId,
        'amount': amount,
        'reason': reason,
        'method': method, // 'wallet' | 'bank'
      }),
    );

    try {
      final data = jsonDecode(resp.body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return {'success': true, 'data': data['data']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Tạo yêu cầu hoàn tiền thất bại',
      };
    } catch (_) {
      return {'success': false, 'message': 'Lỗi phản hồi từ server'};
    }
  }
}
