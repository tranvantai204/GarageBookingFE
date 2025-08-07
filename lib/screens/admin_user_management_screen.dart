import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load users when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tài xế', icon: Icon(Icons.drive_eta)),
            Tab(text: 'Khách hàng', icon: Icon(Icons.people)),
            Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, số điện thoại...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('driver'),
                _buildUserList('user'),
                _buildUserList('admin'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserList(String role) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${userProvider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => userProvider.loadUsers(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        List<User> users = userProvider.getUsersByRole(role);

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            return user.hoTen.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                user.soDienThoai.contains(_searchQuery) ||
                (user.email.isNotEmpty &&
                    user.email.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ));
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForRole(role),
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Không tìm thấy kết quả'
                      : 'Chưa có ${_getRoleDisplayName(role).toLowerCase()}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                if (_searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(defaultRole: role),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Thêm ${_getRoleDisplayName(role).toLowerCase()}',
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => userProvider.loadUsers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForRole(user.vaiTro),
          child: Icon(_getIconForRole(user.vaiTro), color: Colors.white),
        ),
        title: Text(
          user.hoTen,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📱 ${user.soDienThoai}', overflow: TextOverflow.ellipsis),
            if (user.email.isNotEmpty)
              Text('📧 ${user.email}', overflow: TextOverflow.ellipsis),
            if (user.vaiTro == 'driver' &&
                user.bienSoXe != null &&
                user.bienSoXe!.isNotEmpty)
              Text('🚗 ${user.bienSoXe}', overflow: TextOverflow.ellipsis),
            Text(
              _getRoleDisplayName(user.vaiTro),
              style: TextStyle(
                color: _getColorForRole(user.vaiTro),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'change_role',
              child: ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('Đổi vai trò'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: user.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                title: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'change_role':
        _showChangeRoleDialog(user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteConfirmDialog(user);
        break;
    }
  }

  void _showAddUserDialog({String? defaultRole}) {
    // TODO: Implement add user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng thêm user sẽ được implement sau'),
      ),
    );
  }

  void _showEditUserDialog(User user) {
    // TODO: Implement edit user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chỉnh sửa ${user.hoTen} - Tính năng sẽ được implement sau',
        ),
      ),
    );
  }

  void _showChangeRoleDialog(User user) {
    // TODO: Implement change role dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đổi vai trò ${user.hoTen} - Tính năng sẽ được implement sau',
        ),
      ),
    );
  }

  void _toggleUserStatus(User user) async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.toggleUserStatus(user.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.isActive ? "Vô hiệu hóa" : "Kích hoạt"} ${user.hoTen} thành công',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${userProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ${user.hoTen}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userProvider = context.read<UserProvider>();
              final success = await userProvider.deleteUser(user.id);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xóa ${user.hoTen} thành công')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${userProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'driver':
        return Icons.drive_eta;
      case 'user':
      default:
        return Icons.person;
    }
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade700;
      case 'driver':
        return Colors.blue.shade700;
      case 'user':
      default:
        return Colors.green.shade700;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'driver':
        return 'Tài xế';
      case 'user':
      default:
        return 'Khách hàng';
    }
  }
}
