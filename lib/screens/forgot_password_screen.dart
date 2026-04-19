import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _emailController = TextEditingController();
  bool _requested = false;
  bool _loading = false;
  int _cooldown = 0; // giây còn lại
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập email')));
      return;
    }
    if (_cooldown > 0) return;
    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        setState(() => _requested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã gửi OTP' +
                  (data['otp'] != null ? ' (DEV OTP: ${data['otp']})' : ''),
            ),
          ),
        );
        // Bắt đầu đếm lùi 60s
        setState(() => _cooldown = 60);
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
          if (_cooldown == 0) t.cancel();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Không gửi được OTP'),
            backgroundColor: Colors.red,
          ),
        );
        // Nếu server rate-limit 429, cũng bật timer theo thông báo còn lại nếu cần
        if (resp.statusCode == 429) {
          setState(() => _cooldown = 60);
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!mounted) return;
            setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
            if (_cooldown == 0) t.cancel();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.trim().isEmpty || _newPassController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập OTP và mật khẩu mới')));
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'matKhauMoi': _newPassController.text,
        }),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thành công')),
        );
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Không đặt lại được mật khẩu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nhập email đã đăng ký để nhận mã OTP đặt lại mật khẩu.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Form card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: AppTheme.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước 1: Nhập email',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'tenban@example.com',
                      prefixIcon: Icon(Icons.email_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppGradientButton(
                    label: _cooldown > 0
                        ? 'Gửi lại OTP ($_cooldown s)'
                        : (_requested ? 'Gửi lại OTP' : 'Gửi OTP'),
                    onPressed: _loading || _cooldown > 0 ? null : _requestOtp,
                    isLoading: _loading && !_requested,
                    icon: Icons.send_rounded,
                  ),
                  if (_requested) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Bước 2: Nhập OTP và mật khẩu mới',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Mã OTP',
                        hintText: '6 chữ số',
                        prefixIcon: Icon(Icons.vpn_key_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _newPassController,
                      obscureText: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppGradientButton(
                      label: 'Đặt lại mật khẩu',
                      onPressed: _loading ? null : _resetPassword,
                      isLoading: _loading && _requested,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
