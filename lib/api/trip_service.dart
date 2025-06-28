import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';
import '../utils/constants.dart';

class TripService {
  // Lấy tất cả chuyến đi (để hiển thị danh sách)
  static Future<List<Trip>> fetchAllTrips() async {
    try {
      print(
        '🚌 Starting to fetch all trips from: ${ApiConstants.baseUrl}/trips',
      );

      // Thử gọi API trực tiếp với một tuyến đường cụ thể
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('📅 Using date: $dateString');

      // Test với một tuyến cụ thể trước
      final testUri = Uri.parse('${ApiConstants.baseUrl}/trips').replace(
        queryParameters: {
          'diemDi': 'Hà Nội',
          'diemDen': 'Sapa',
          'ngayDi': dateString,
        },
      );

      print('🔗 Test URL: $testUri');

      final response = await http.get(
        testUri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List data = jsonResponse['data'];
          print('✅ Found ${data.length} trips');

          if (data.isNotEmpty) {
            print('📋 First trip data: ${data[0]}');
          }

          final trips = data.map((e) => Trip.fromJson(e)).toList();
          return trips;
        } else {
          print('❌ API returned success: false or no data');
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 Error fetching trips: $e');
      return [];
    }
  }

  // Tìm kiếm chuyến đi theo điều kiện
  static Future<List<Trip>> searchTrips({
    required String diemDi,
    required String diemDen,
    required String ngayDi,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/trips').replace(
        queryParameters: {
          'diemDi': diemDi,
          'diemDen': diemDen,
          'ngayDi': ngayDi,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List data = jsonResponse['data'];
          return data.map((e) => Trip.fromJson(e)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to search trips: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching trips: $e');
      throw Exception('Failed to search trips: $e');
    }
  }

  // Lấy chi tiết một chuyến đi
  static Future<Trip> getTripById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/trips/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return Trip.fromJson(jsonResponse['data']);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to get trip: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting trip: $e');
      throw Exception('Failed to get trip: $e');
    }
  }
}
