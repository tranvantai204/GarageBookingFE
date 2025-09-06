import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'dart:async';

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
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bỏ số điện thoại: chỉ dùng email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            if (_requested) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mã OTP'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : (_requested
                          ? _resetPassword
                          : (_cooldown > 0 ? null : _requestOtp)),
                child: Text(
                  _requested
                      ? 'Đổi mật khẩu'
                      : (_cooldown > 0
                            ? 'Gửi lại OTP ($_cooldown s)'
                            : 'Gửi OTP'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
