import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class VehicleService {
  static Future<List<Map<String, dynamic>>> fetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/vehicles'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = (data['data'] as List).cast<Map<String, dynamic>>();
      return list;
    }
    throw Exception('Failed to fetch vehicles');
  }

  static Future<Map<String, dynamic>> createVehicle({
    required String bienSoXe,
    required String loaiXe,
    required int soGhe,
    String? tenXe,
    String? hangXe,
    List<String>? hinhAnh,
    String? moTa,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bienSoXe': bienSoXe,
        'loaiXe': loaiXe,
        'soGhe': soGhe,
        if (tenXe != null) 'tenXe': tenXe,
        if (hangXe != null) 'hangXe': hangXe,
        if (hinhAnh != null) 'hinhAnh': hinhAnh,
        if (moTa != null) 'moTa': moTa,
      }),
    );
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return (data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create vehicle');
  }

  static Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/vehicles/$id'),
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
    throw Exception(
      'Failed to update vehicle: ${resp.statusCode} - ${resp.body}',
    );
  }

  static Future<void> deleteVehicle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final resp = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/vehicles/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete vehicle');
    }
  }

  static Future<String> uploadImage(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('${ApiConstants.baseUrl}/upload/image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
      // New backend shape: { success, data: { imageUrl } }
      if (data['data'] is Map && data['data']['imageUrl'] != null) {
        return data['data']['imageUrl'].toString();
      }
      // Legacy fallbacks
      if (data['imageUrl'] != null) return data['imageUrl'].toString();
      if (data['url'] != null) return data['url'].toString();
    }
    throw Exception('Upload thất bại: ${resp.statusCode}');
  }

  static Future<List<String>> uploadImages(List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('${ApiConstants.baseUrl}/upload/images');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    for (final p in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', p));
    }
    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
      // New backend shape: { success, data: [ { imageUrl } ] }
      if (data['data'] is List) {
        final List list = data['data'];
        return list
            .map(
              (e) => (e is Map && e['imageUrl'] != null)
                  ? e['imageUrl'].toString()
                  : null,
            )
            .whereType<String>()
            .toList();
      }
      // Legacy shape: { urls: [ ... ] }
      if (data['urls'] is List) {
        return (data['urls'] as List).map((e) => e.toString()).toList();
      }
    }
    throw Exception('Upload thất bại: ${resp.statusCode}');
  }
}
