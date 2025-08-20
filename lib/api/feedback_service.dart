import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class FeedbackService {
  static Future<Map<String, dynamic>> create({
    required String bookingId,
    required String tripId,
    required String driverId,
    required int ratingDriver,
    String? comment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/feedbacks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bookingId': bookingId,
        'tripId': tripId,
        'driverId': driverId,
        'ratingDriver': ratingDriver,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    return {
      'success': resp.statusCode == 201 && (jsonResp['success'] == true),
      'data': jsonResp['data'],
      'message': jsonResp['message'],
    };
  }

  // Admin: list all feedbacks
  static Future<List<Map<String, dynamic>>> adminList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/feedbacks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (resp.statusCode == 200 && jsonResp['success'] == true) {
      return List<Map<String, dynamic>>.from(jsonResp['data'] ?? []);
    }
    throw Exception(jsonResp['message'] ?? 'Load feedbacks failed');
  }

  static Future<Map<String, dynamic>> adminUpdateStatus(
    String id,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final resp = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/feedbacks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );
    final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    return {
      'success': resp.statusCode == 200 && jsonResp['success'] == true,
      'data': jsonResp['data'],
      'message': jsonResp['message'],
    };
  }
}
