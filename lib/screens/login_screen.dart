import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'test_accounts_screen.dart';
import 'register_screen.dart';
import '../services/push_notification_service.dart';
import '../utils/session_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../providers/socket_provider.dart';
import 'forgot_password_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    setState(() => _isLoading = true);
    try {
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

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        await _saveUserData(jsonResponse);
        await SessionManager.saveToken(jsonResponse['token'] ?? '');
        if (mounted) {
          _showSuccess('Chào mừng ${jsonResponse['hoTen']}!');
          await PushNotificationService.syncFcmTokenWithServer();
          try {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('userId');
            final token = prefs.getString('token') ?? '';
            if (userId != null && userId.isNotEmpty) {
              await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
              try {
                final sp = Provider.of<SocketProvider>(context, listen: false);
                if (!sp.isConnected) {
                  sp.connect('https://garagebooking.onrender.com', token, userId);
                } else {
                  sp.emit('join', userId);
                }
              } catch (_) {}
            }
          } catch (_) {}
          Navigator.pushReplacementNamed(context, '/trips');
        }
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        if (mounted) _showError('Sai số điện thoại hoặc mật khẩu');
        return;
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      bool serverConnected = await _tryAlternativeServers();
      if (!serverConnected && mounted) {
        _showError('Không thể kết nối đến server. Vui lòng thử lại sau.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _tryAlternativeServers() async {
    final alternativeUrls = [
      'https://garagebooking.onrender.com/api',
      'https://ha-phuong-app.onrender.com/api',
    ];
    for (final url in alternativeUrls) {
      try {
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
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          await _saveUserData(jsonResponse);
          await SessionManager.saveToken(jsonResponse['token'] ?? '');
          if (mounted) {
            _showSuccess('Đăng nhập thành công: ${jsonResponse['hoTen']}');
            await PushNotificationService.syncFcmTokenWithServer();
            try {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');
              final token = prefs.getString('token') ?? '';
              if (userId != null && userId.isNotEmpty) {
                await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
                try {
                  final sp = Provider.of<SocketProvider>(context, listen: false);
                  if (!sp.isConnected) {
                    sp.connect('https://garagebooking.onrender.com', token, userId);
                  } else {
                    sp.emit('join', userId);
                  }
                } catch (_) {}
              }
            } catch (_) {}
            Navigator.pushReplacementNamed(context, '/trips');
          }
          return true;
        } else if (response.statusCode == 401 || response.statusCode == 400) {
          if (mounted) _showError('Sai số điện thoại hoặc mật khẩu');
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final role = userData['vaiTro'] ?? 'user';
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('userId', userData['_id'] ?? '');
    await prefs.setString('hoTen', userData['hoTen'] ?? '');
    await prefs.setString('vaiTro', role);
    if (userData['soDienThoai'] != null) {
      await prefs.setString('soDienThoai', userData['soDienThoai'] ?? '');
    }
    if (userData['email'] != null) {
      await prefs.setString('email', userData['email'] ?? '');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          // Bottom background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.62,
            child: Container(color: AppTheme.background),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Top: Logo + title
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: AppTheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhà xe Hà Phương',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Đặt vé nhanh, đi xe tiện lợi',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Help button
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TestAccountsScreen(),
                            ),
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Card form
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        boxShadow: AppTheme.shadowCard,
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đăng nhập',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chào mừng bạn quay trở lại!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Phone field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại',
                              hintText: '0xxx xxx xxx',
                              prefixIcon: const Icon(
                                Icons.phone_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 0,
                                ),
                              ),
                              child: Text(
                                'Quên mật khẩu?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Login button
                          AppGradientButton(
                            label: 'Đăng nhập',
                            onPressed: _isLoading ? null : _handleLogin,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                          ),

                          const SizedBox(height: 20),

                          // Register link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Chưa có tài khoản? ',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Đăng ký ngay',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Features row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _featureItem(Icons.bolt_rounded, 'Đặt vé\nnhanh'),
                        _featureItem(Icons.shield_rounded, 'An toàn\n& tin cậy'),
                        _featureItem(Icons.support_agent_rounded, 'Hỗ trợ\n24/7'),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
