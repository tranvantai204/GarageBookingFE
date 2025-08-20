import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../widgets/logo_widget.dart';
import '../widgets/simple_background.dart';
import 'test_accounts_screen.dart';
import 'register_screen.dart';
import '../services/push_notification_service.dart';
import '../utils/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validation
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Đăng nhập với: ${_phoneController.text}');

      // Thử kết nối server
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'soDienThoai': _phoneController.text.trim(),
              'matKhau': _passwordController.text.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Server timeout'),
          );

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        await _saveUserData(jsonResponse);
        await SessionManager.saveToken(jsonResponse['token'] ?? '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chào mừng ${jsonResponse['hoTen']}!'),
              backgroundColor: Colors.green,
            ),
          );
          await PushNotificationService.syncFcmTokenWithServer();
          Navigator.pushReplacementNamed(context, '/trips');
        }
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Sai thông tin đăng nhập - không thử server khác
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sai số điện thoại hoặc mật khẩu'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Dừng ở đây, không thử server khác
      } else {
        // Lỗi server khác (500, 503, etc.) - thử server khác
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi: $e');

      // Thử server khác
      bool serverConnected = await _tryAlternativeServers();

      if (!serverConnected) {
        // Không có server nào hoạt động - hiển thị lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể kết nối đến server. Vui lòng thử lại sau.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _tryAlternativeServers() async {
    final alternativeUrls = [
      'https://garagebooking.onrender.com/api', // Server chính đang hoạt động
      'https://ha-phuong-app.onrender.com/api',
    ];

    for (final url in alternativeUrls) {
      try {
        print('🔄 Thử server: $url');

        final response = await http
            .post(
              Uri.parse('$url/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'soDienThoai': _phoneController.text.trim(),
                'matKhau': _passwordController.text.trim(),
              }),
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Server timeout'),
            );

        print('📡 Server $url response: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Server hoạt động: $url');

          final jsonResponse = jsonDecode(response.body);
          print('🔍 Login response data: $jsonResponse');
          print('👤 User role from server: ${jsonResponse['vaiTro']}');
          print('📱 Phone number: ${jsonResponse['soDienThoai']}');
          print('🆔 User ID: ${jsonResponse['_id']}');

          await _saveUserData(jsonResponse);
          await SessionManager.saveToken(jsonResponse['token'] ?? '');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đăng nhập thành công: ${jsonResponse['hoTen']} (${jsonResponse['vaiTro']})',
                ),
                backgroundColor: Colors.green,
              ),
            );
            await PushNotificationService.syncFcmTokenWithServer();
            Navigator.pushReplacementNamed(context, '/trips');
          }
          return true;
        } else if (response.statusCode == 401 || response.statusCode == 400) {
          // Server hoạt động nhưng sai thông tin đăng nhập
          print('❌ Sai thông tin đăng nhập trên server: $url');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sai số điện thoại hoặc mật khẩu'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return true; // Server hoạt động, chỉ là sai thông tin
        }
      } catch (e) {
        print('❌ Server $url failed: $e');
        continue;
      }
    }

    print('❌ Tất cả server đều không hoạt động');
    return false;
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final role = userData['vaiTro'] ?? 'user';

    print('💾 Saving user data to SharedPreferences:');
    print('   - Role: $role');
    print('   - Name: ${userData['hoTen']}');
    print('   - Phone: ${userData['soDienThoai']}');

    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('userId', userData['_id'] ?? '');
    await prefs.setString('hoTen', userData['hoTen'] ?? '');
    await prefs.setString('vaiTro', role);

    // Verify saved data
    final savedRole = prefs.getString('vaiTro');
    print('✅ Verified saved role: $savedRole');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập Nhà xe Hà Phương'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestAccountsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tài khoản test',
          ),
        ],
      ),
      body: SimpleBackground(
        colors: [Colors.blue.shade50, Colors.blue.shade100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Simple Logo
              AnimatedLogo(size: 120, text: 'GarageBooking'),

              const SizedBox(height: 40),

              // Welcome text with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                    Colors.green.shade600,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Chào mừng đến với GarageBooking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Đặt vé xe khách dễ dàng và nhanh chóng',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Simple card container for form
              SimpleCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Phone input with beautiful styling
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: 'Nhập số điện thoại của bạn',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Colors.blue.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.blue.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Password input with beautiful styling
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu của bạn',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.blue.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.blue.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.blue.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                      obscureText: true,
                    ),

                    const SizedBox(height: 30),

                    // Beautiful gradient login button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.purple.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Register link with beautiful styling
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ).createShader(bounds),
                  child: const Text(
                    'Chưa có tài khoản? Đăng ký ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Simple demo info card
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
