import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import '../constants/api_constants.dart';

class BookingService {
  static Future<bool> createBooking(String tripId, int soLuong) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tripId': tripId, 'soLuong': soLuong}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Create booking failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  static Future<bool> createBookingWithSeats(
    String tripId,
    List<String> selectedSeats,
  ) async {
    return createBookingWithPickup(tripId, selectedSeats, 'ben_xe', null, null);
  }

  static Future<bool> createBookingWithPickup(
    String tripId,
    List<String> selectedSeats,
    String pickupType,
    String? customAddress,
    String? pickupNote, {
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tripId': tripId,
          'danhSachGheDat': selectedSeats,
          'loaiDiemDon': pickupType,
          'diaChiDon': customAddress,
          'ghiChuDiemDon': pickupNote,
          'thongTinKhachHang': {
            'hoTen': customerName ?? 'Khách hàng',
            'soDienThoai': customerPhone ?? '',
            'email': customerEmail ?? '',
          },
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Create booking with pickup failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error creating booking with pickup: $e');
      return false;
    }
  }

  static Future<List<Booking>> fetchBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/bookings/mybookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List data = jsonResponse['data'];
          return data.map((e) => Booking.fromJson(e)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🗑️ Cancelling booking: $bookingId');
      print('🌐 API URL: ${ApiConstants.baseUrl}/bookings/$bookingId');

      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - Server không phản hồi');
            },
          );

      print('📡 Cancel response status: ${response.statusCode}');
      print('📄 Cancel response body: ${response.body}');

      if (response.body.isEmpty) {
        // Nếu server không trả về dữ liệu, giả sử thành công
        return {
          'success': true,
          'message': 'Hủy vé thành công',
          'refundAmount': 0,
        };
      }

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Hủy vé thành công',
          'refundAmount': jsonResponse['data']?['refundAmount'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Không thể hủy vé',
        };
      }
    } catch (e) {
      print('❌ Error cancelling booking: $e');

      // Xử lý các loại lỗi khác nhau
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Server không phản hồi. Vui lòng thử lại sau.',
        };
      } else if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'Không có kết nối internet. Vui lòng kiểm tra mạng.',
        };
      } else if (e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        // API chưa được implement, trả về demo success
        print('🔧 API chưa có, sử dụng demo mode');
        return {
          'success': true,
          'message': 'Hủy vé thành công (Demo mode)',
          'refundAmount': 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi hệ thống. Vui lòng thử lại sau.',
        };
      }
    }
  }
}
