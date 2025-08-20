import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      // Enforce 2h session expiry
      final valid = await SessionManager.isTokenValid();
      if (token.isEmpty || !valid) {
        await SessionManager.clearSession();
        _goToLogin();
        return;
      }

      // Validate token with backend
      final uri = Uri.parse('${ApiConstants.baseUrl}/auth/me');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/trips');
      } else {
        await prefs.remove('token');
        await prefs.remove('userId');
        await prefs.remove('hoTen');
        await prefs.remove('vaiTro');
        _goToLogin();
      }
    } catch (_) {
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
