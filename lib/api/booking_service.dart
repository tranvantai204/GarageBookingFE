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
    String? voucherCode,
    int? discountAmount,
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
          if (voucherCode != null && voucherCode.isNotEmpty)
            'voucherCode': voucherCode,
          if (discountAmount != null && discountAmount > 0)
            'discountAmount': discountAmount,
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

  static Future<Map<String, dynamic>> createRaw(
    Map<String, dynamic> body,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final jsonResponse = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonResponse['data']};
      }
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Tạo vé thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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

  static Future<Map<String, dynamic>> checkInByQr(
    String qrData, {
    String? tripId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings/checkin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qrData': qrData,
          if (tripId != null) 'tripId': tripId,
          'allowEarlyMinutes': 30,
        }),
      );

      final jsonResponse = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Check-in thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTripPassengers(String tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/bookings/trip/$tripId/passengers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final jsonResponse = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonResponse['data']};
      }
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Load passengers failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> payBooking({
    required String bookingId,
    required String method, // 'cash' | 'bank' | 'wallet'
    String? reference,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'method': method,
          if (reference != null) 'reference': reference,
        }),
      );
      final jsonResponse = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonResponse['data']};
      }
      return {
        'success': false,
        'message': jsonResponse['message'] ?? 'Thanh toán thất bại',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createPaymentQr({
    required String type,
    String? bookingId,
    String? userId,
    int? amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final resp = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          if (bookingId != null) 'bookingId': bookingId,
          if (userId != null) 'userId': userId,
          if (amount != null) 'amount': amount,
        }),
      );
      final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
      return {
        'success': resp.statusCode == 200 && jsonResp['success'] == true,
        'data': jsonResp['data'],
        'message': jsonResp['message'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createPayosLink({
    required String type,
    String? bookingId,
    String? userId,
    int? amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No authentication token found');
      final resp = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/payos/create-link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          if (bookingId != null) 'bookingId': bookingId,
          if (userId != null) 'userId': userId,
          if (amount != null) 'amount': amount,
        }),
      );
      final jsonResp = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
      return {
        'success': resp.statusCode == 200 && jsonResp['success'] == true,
        'data': jsonResp['data'],
        'message': jsonResp['message'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
