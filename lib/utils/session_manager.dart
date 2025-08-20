import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _tokenKey = 'token';
  static const String _tokenIssuedAtKey = 'tokenIssuedAt';
  static const Duration tokenMaxAge = Duration(hours: 2);

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(
      _tokenIssuedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token?.isNotEmpty == true ? token : null;
  }

  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;
    final issuedAtMs = prefs.getInt(_tokenIssuedAtKey);
    if (issuedAtMs == null) return false;
    final issuedAt = DateTime.fromMillisecondsSinceEpoch(issuedAtMs);
    final age = DateTime.now().difference(issuedAt);
    return age < tokenMaxAge;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenIssuedAtKey);
    await prefs.remove('userId');
    await prefs.remove('hoTen');
    await prefs.remove('vaiTro');
  }

  static Future<void> enforceOrLogout(BuildContext context) async {
    final valid = await isTokenValid();
    if (!valid) {
      // Show a gentle snackbar/toast before redirect
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phiên đã hết hạn, vui lòng đăng nhập lại'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }

      await clearSession();
      if (context.mounted) {
        // Delay slightly to allow snackbar to appear
        await Future.delayed(const Duration(milliseconds: 900));
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      }
    }
  }
}
