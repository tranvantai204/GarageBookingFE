import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';

class UserService {
  static Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🔍 Fetching all users...');
      print('🌐 API URL: ${ApiConstants.baseUrl}/auth/users');

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/auth/users'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📡 Users response status: ${response.statusCode}');
      print('📄 Users response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> usersData =
            jsonResponse['data'] ?? jsonResponse['users'] ?? [];

        return usersData.map((userData) => User.fromJson(userData)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  static Future<User> createUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('➕ Creating user: ${user.hoTen}');
      print('🌐 API URL: ${ApiConstants.baseUrl}/auth/users');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/users'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(user.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📡 Create user response status: ${response.statusCode}');
      print('📄 Create user response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return User.fromJson(jsonResponse['data'] ?? jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      print('❌ Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<User> updateUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('✏️ Updating user: ${user.id}');
      print('🌐 API URL: ${ApiConstants.baseUrl}/users/${user.id}');

      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/users/${user.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(user.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📡 Update user response status: ${response.statusCode}');
      print('📄 Update user response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return User.fromJson(jsonResponse['data'] ?? jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      print('❌ Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🗑️ Deleting user: $userId');
      print('🌐 API URL: ${ApiConstants.baseUrl}/users/$userId');

      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/users/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('📡 Delete user response status: ${response.statusCode}');
      print('📄 Delete user response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }
}
