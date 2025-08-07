import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class EditUserScreen extends StatefulWidget {
  final User user;
  
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hoTenController;
  late TextEditingController _soDienThoaiController;
  late TextEditingController _emailController;
  late TextEditingController _diaChiController;
  late TextEditingController _bienSoXeController;
  late TextEditingController _gplxController;

  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hoTenController = TextEditingController(text: widget.user.hoTen);
    _soDienThoaiController = TextEditingController(text: widget.user.soDienThoai);
    _emailController = TextEditingController(text: widget.user.email);
    _diaChiController = TextEditingController(text: widget.user.diaChi ?? '');
    _bienSoXeController = TextEditingController(text: widget.user.bienSoXe ?? '');
    _gplxController = TextEditingController(text: widget.user.gplx ?? '');
    _selectedRole = widget.user.vaiTro;
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _emailController.dispose();
    _diaChiController.dispose();
    _bienSoXeController.dispose();
    _gplxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sửa: ${widget.user.hoTen}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              _buildUserInfoCard(),
              
              const SizedBox(height: 24),
              
              // Role Selection
              _buildRoleSelection(),
              
              const SizedBox(height: 24),
              
              // Basic Info
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // Driver specific fields
              if (_selectedRole == 'driver') ...[
                _buildDriverSection(),
                const SizedBox(height: 24),
              ],
              
              // Address
              _buildAddressSection(),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(widget.user.vaiTro),
              radius: 30,
              child: Icon(
                _getRoleIcon(widget.user.vaiTro),
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.hoTen,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.roleDisplayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.user.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.user.isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.user.isActive ? 'Hoạt động' : 'Tạm khóa',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vai trò',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Khách hàng')),
                DropdownMenuItem(value: 'driver', child: Text('Tài xế')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoTenController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _soDienThoaiController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (value.length < 10) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!value.contains('@')) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin tài xế',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bienSoXeController,
              decoration: const InputDecoration(
                labelText: 'Biển số xe *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
                hintText: 'VD: 51A-12345',
              ),
              validator: _selectedRole == 'driver'
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập biển số xe';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gplxController,
              decoration: const InputDecoration(
                labelText: 'Giấy phép lái xe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'VD: B2-123456789',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diaChiController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Cập nhật'),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'driver':
        return Colors.green;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'driver':
        return Icons.drive_eta;
      case 'user':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = widget.user.copyWith(
        hoTen: _hoTenController.text.trim(),
        soDienThoai: _soDienThoaiController.text.trim(),
        email: _emailController.text.trim(),
        vaiTro: _selectedRole,
        diaChi: _diaChiController.text.trim().isEmpty ? null : _diaChiController.text.trim(),
        bienSoXe: _selectedRole == 'driver' && _bienSoXeController.text.trim().isNotEmpty
            ? _bienSoXeController.text.trim()
            : null,
        gplx: _selectedRole == 'driver' && _gplxController.text.trim().isNotEmpty
            ? _gplxController.text.trim()
            : null,
        updatedAt: DateTime.now(),
      );

      final success = await Provider.of<UserProvider>(context, listen: false)
          .updateUser(updatedUser);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật người dùng thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi cập nhật người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${widget.user.hoTen}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<UserProvider>(context, listen: false)
                  .deleteUser(widget.user.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Xóa người dùng thành công' : 'Lỗi khi xóa người dùng'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
