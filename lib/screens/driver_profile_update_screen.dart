import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/api_constants.dart';

class DriverProfileUpdateScreen extends StatefulWidget {
  const DriverProfileUpdateScreen({super.key});

  @override
  State<DriverProfileUpdateScreen> createState() => _DriverProfileUpdateScreenState();
}

class _DriverProfileUpdateScreenState extends State<DriverProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _emailController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _cccdController = TextEditingController();
  final _gplxController = TextEditingController();
  final _bienSoXeController = TextEditingController();
  final _loaiXeController = TextEditingController();
  final _namSinhController = TextEditingController();

  bool _isLoading = false;
  File? _avatarImage;
  File? _cccdImage;
  File? _gplxImage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hoTenController.text = prefs.getString('hoTen') ?? '';
      _soDienThoaiController.text = prefs.getString('soDienThoai') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _diaChiController.text = prefs.getString('diaChi') ?? '';
      _cccdController.text = prefs.getString('cccd') ?? '';
      _gplxController.text = prefs.getString('gplx') ?? '';
      _bienSoXeController.text = prefs.getString('bienSoXe') ?? '';
      _loaiXeController.text = prefs.getString('loaiXe') ?? '';
      _namSinhController.text = prefs.getString('namSinh') ?? '';
      _currentAvatarUrl = prefs.getString('avatarUrl');
    });
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        switch (type) {
          case 'avatar':
            _avatarImage = File(image.path);
            break;
          case 'cccd':
            _cccdImage = File(image.path);
            break;
          case 'gplx':
            _gplxImage = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      // Prepare form data
      final Map<String, dynamic> updateData = {
        'hoTen': _hoTenController.text.trim(),
        'email': _emailController.text.trim(),
        'diaChi': _diaChiController.text.trim(),
        'cccd': _cccdController.text.trim(),
        'gplx': _gplxController.text.trim(),
        'bienSoXe': _bienSoXeController.text.trim(),
        'loaiXe': _loaiXeController.text.trim(),
        'namSinh': _namSinhController.text.trim(),
      };

      print('🔄 Updating driver profile...');
      print('📝 Update data: $updateData');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      print('📡 Update response status: ${response.statusCode}');
      print('📄 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local storage
          await prefs.setString('hoTen', _hoTenController.text.trim());
          await prefs.setString('email', _emailController.text.trim());
          await prefs.setString('diaChi', _diaChiController.text.trim());
          await prefs.setString('cccd', _cccdController.text.trim());
          await prefs.setString('gplx', _gplxController.text.trim());
          await prefs.setString('bienSoXe', _bienSoXeController.text.trim());
          await prefs.setString('loaiXe', _loaiXeController.text.trim());
          await prefs.setString('namSinh', _namSinhController.text.trim());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Cập nhật thông tin thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          throw Exception(data['message'] ?? 'Cập nhật thất bại');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _emailController.dispose();
    _diaChiController.dispose();
    _cccdController.dispose();
    _gplxController.dispose();
    _bienSoXeController.dispose();
    _loaiXeController.dispose();
    _namSinhController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật thông tin tài xế'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar section
              _buildAvatarSection(),
              const SizedBox(height: 24),

              // Personal Information
              _buildSectionTitle('Thông tin cá nhân'),
              _buildTextField(
                controller: _hoTenController,
                label: 'Họ và tên',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _namSinhController,
                label: 'Năm sinh',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _soDienThoaiController,
                label: 'Số điện thoại',
                icon: Icons.phone,
                enabled: false, // Phone number shouldn't be changed
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                controller: _diaChiController,
                label: 'Địa chỉ',
                icon: Icons.location_on,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Identity Documents
              _buildSectionTitle('Giấy tờ tùy thân'),
              _buildTextField(
                controller: _cccdController,
                label: 'Số CCCD/CMND',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
              ),
              _buildImagePicker(
                title: 'Ảnh CCCD/CMND',
                image: _cccdImage,
                onTap: () => _pickImage('cccd'),
              ),

              const SizedBox(height: 24),

              // Driver License
              _buildSectionTitle('Bằng lái xe'),
              _buildTextField(
                controller: _gplxController,
                label: 'Số bằng lái xe',
                icon: Icons.drive_eta,
              ),
              _buildImagePicker(
                title: 'Ảnh bằng lái xe',
                image: _gplxImage,
                onTap: () => _pickImage('gplx'),
              ),

              const SizedBox(height: 24),

              // Vehicle Information
              _buildSectionTitle('Thông tin xe'),
              _buildTextField(
                controller: _bienSoXeController,
                label: 'Biển số xe',
                icon: Icons.directions_car,
              ),
              _buildTextField(
                controller: _loaiXeController,
                label: 'Loại xe',
                icon: Icons.local_shipping,
                hintText: 'VD: Xe khách 16 chỗ, Xe giường nằm...',
              ),

              const SizedBox(height: 32),

              // Update button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Cập nhật thông tin',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabled: enabled,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage('avatar'),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 3),
                color: Colors.grey.shade200,
              ),
              child: _avatarImage != null
                  ? ClipOval(
                      child: Image.file(
                        _avatarImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _currentAvatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _currentAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 60, color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _pickImage('avatar'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Thay đổi ảnh đại diện'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Nhấn để chọn ảnh',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
