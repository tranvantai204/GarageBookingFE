import 'dart:convert'; // Để mã hóa và giải mã JSON
import 'package:http/http.dart' as http; // Package để gọi API
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart'; // Import file hằng số

class LoginResponse {
  final String token;
  final String userId;
  final String hoTen;
  final String vaiTro;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.hoTen,
    required this.vaiTro,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('Parsing login response: $json'); // Debug log
    return LoginResponse(
      token: json['token'] ?? '',
      userId: json['_id'] ?? '',
      hoTen: json['hoTen'] ?? '',
      vaiTro: json['vaiTro'] ?? 'user',
    );
  }
}

class AuthApiService {
  // Hàm đăng nhập
  // Sẽ trả về LoginResponse nếu thành công, hoặc null nếu thất bại
  Future<LoginResponse?> login(String soDienThoai, String matKhau) async {
    // 1. Xây dựng URL đầy đủ
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    // 2. Chuẩn bị dữ liệu gửi đi (Body)
    final body = jsonEncode({'soDienThoai': soDienThoai, 'matKhau': matKhau});

    // 3. Chuẩn bị Headers, nói cho server biết chúng ta gửi dữ liệu dạng JSON
    final headers = {'Content-Type': 'application/json'};

    try {
      // 4. Gửi yêu cầu POST và chờ kết quả
      final response = await http.post(url, headers: headers, body: body);

      // 5. Xử lý kết quả trả về
      if (response.statusCode == 200) {
        // 200 OK - Đăng nhập thành công
        final jsonResponse = jsonDecode(response.body);
        print('Đăng nhập thành công! Response: $jsonResponse');

        // Kiểm tra xem response có chứa token không
        if (jsonResponse.containsKey('token')) {
          return LoginResponse.fromJson(jsonResponse);
        } else {
          // Nếu không có token, có thể response trả về user object trực tiếp
          // Cần tạo một response giả với token
          print('Response không có token, có thể cần xử lý khác');
          return null;
        }
      } else {
        // Các trường hợp lỗi khác (401, 500...)
        print('Đăng nhập thất bại. Status code: ${response.statusCode}');
        print('Lỗi: ${response.body}');
        return null;
      }
    } catch (e) {
      // Lỗi mạng hoặc không kết nối được tới server
      print('Đã xảy ra lỗi khi gọi API: $e');
      return null;
    }
  }

  // Lấy thông tin user hiện tại để xác định role
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/me');

      // Lấy token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return null;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print('Get current user failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Bạn có thể thêm hàm register() ở đây sau này
}
