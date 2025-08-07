import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../api/user_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get users by role
  List<User> get admins =>
      _users.where((user) => user.vaiTro == 'admin').toList();
  List<User> get drivers =>
      _users.where((user) => user.vaiTro == 'driver').toList();
  List<User> get customers =>
      _users.where((user) => user.vaiTro == 'user').toList();

  Future<void> loadUsers() async {
    print('🔄 UserProvider: Starting loadUsers...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await UserService.getAllUsers();
      print('✅ UserProvider: Loaded ${_users.length} users');
      for (var user in _users) {
        print('👤 User: ${user.hoTen} (${user.vaiTro})');
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ UserProvider Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(User user) async {
    try {
      final newUser = await UserService.createUser(user);
      _users.add(newUser);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error creating user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final updatedUser = await UserService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error updating user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await UserService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error deleting user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(vaiTro: newRole);
      return await updateUser(updatedUser);
    } catch (e) {
      _error = e.toString();
      print('Error changing user role: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId) async {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(isActive: !user.isActive);
      return await updateUser(updatedUser);
    } catch (e) {
      _error = e.toString();
      print('Error toggling user status: $e');
      notifyListeners();
      return false;
    }
  }

  // Search and filter methods
  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.hoTen.toLowerCase().contains(query.toLowerCase()) ||
          user.soDienThoai.contains(query) ||
          user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<User> getUsersByRole(String role) {
    if (role == 'tai_xe') {
      return drivers; // Use the drivers getter which handles both 'tai_xe' and 'driver'
    }
    return _users.where((user) => user.vaiTro == role).toList();
  }

  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Statistics
  int get totalUsers => _users.length;
  int get totalAdmins => admins.length;
  int get totalDrivers => drivers.length;
  int get totalCustomers => customers.length;
  int get activeUsers => _users.where((user) => user.isActive).length;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearUsers() {
    _users.clear();
    notifyListeners();
  }
}
