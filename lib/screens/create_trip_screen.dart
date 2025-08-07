import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTripScreen extends StatefulWidget {
  final bool showAppBar;

  const CreateTripScreen({super.key, this.showAppBar = true});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diemDiController = TextEditingController();
  final _diemDenController = TextEditingController();
  final _taiXeController = TextEditingController();
  final _bienSoXeController = TextEditingController();
  final _giaVeController = TextEditingController();

  DateTime? _selectedDateTime;
  int _soGhe = 16;
  bool _isLoading = false;

  String? _selectedDriverId;
  String? _selectedDriverName;
  String _selectedVehicleType = 'ghe_ngoi';

  final List<String> _tinhThanhVietNam = [
    'An Giang',
    'Bà Rịa - Vũng Tàu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bạc Liêu',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Định',
    'Bình Dương',
    'Bình Phước',
    'Bình Thuận',
    'Cà Mau',
    'Cao Bằng',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Nội',
    'Hà Tĩnh',
    'Hải Dương',
    'Hải Phòng',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Khánh Hòa',
    'Kiên Giang',
    'Kon Tum',
    'Lai Châu',
    'Lâm Đồng',
    'Lạng Sơn',
    'Lào Cai',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Bình',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Bình',
    'Quảng Nam',
    'Quảng Ngãi',
    'Quảng Ninh',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Thừa Thiên Huế',
    'Tiền Giang',
    'TP. Hồ Chí Minh',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
    'Cần Thơ',
    'Đà Nẵng',
  ];

  @override
  void initState() {
    super.initState();
    // Load drivers from database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  void dispose() {
    _diemDiController.dispose();
    _diemDenController.dispose();
    _taiXeController.dispose();
    _bienSoXeController.dispose();
    _giaVeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createTrip() async {
    print('🚌 Starting create trip...');

    // Debug: Check current user role from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('vaiTro') ?? 'user';
    final userId = prefs.getString('userId') ?? '';
    print('🔍 Current user role from SharedPreferences: $currentRole');
    print('🔍 Current user ID: $userId');

    // CRITICAL: Verify role from server to avoid SharedPreferences issues
    try {
      print('🌐 Calling API to verify user role...');
      final token = prefs.getString('token') ?? '';
      print(
        '🔑 Using token: ${token.isNotEmpty ? "***${token.substring(token.length - 10)}" : "EMPTY"}',
      );

      final response = await http
          .get(
            Uri.parse('https://garagebooking.onrender.com/api/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📡 API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'];

        if (userData != null) {
          final serverRole = userData['vaiTro'] ?? 'user';
          print('🔍 Server role for user: $serverRole');

          if (serverRole != 'admin') {
            print('❌ Access denied: Server role is "$serverRole", not "admin"');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Chỉ admin mới có thể tạo chuyến đi!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          print('❌ User data not found in response');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Không tìm thấy thông tin người dùng!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('❌ Error verifying user role: $e');
      // Fallback to SharedPreferences if API fails
      if (currentRole != 'admin') {
        print('❌ Fallback: Access denied based on SharedPreferences');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Chỉ admin mới có thể tạo chuyến đi!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (!_formKey.currentState!.validate() || _selectedDateTime == null) {
      print('❌ Validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền đầy đủ thông tin và chọn thời gian khởi hành',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📝 Form data:');
      print('- Điểm đi: ${_diemDiController.text}');
      print('- Điểm đến: ${_diemDenController.text}');
      print('- Thời gian: $_selectedDateTime');
      print('- Số ghế: $_soGhe');
      print('- Loại xe: $_selectedVehicleType');
      print('- Giá vé: ${_giaVeController.text}');
      print('- Tài xế: $_selectedDriverName');
      print('- Driver ID: $_selectedDriverId');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Không tìm thấy token đăng nhập');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/trips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'diemDi': _diemDiController.text.trim(),
          'diemDen': _diemDenController.text.trim(),
          'thoiGianKhoiHanh': _selectedDateTime!.toIso8601String(),
          'soGhe': _soGhe,
          'loaiXe': _selectedVehicleType,
          'giaVe': int.parse(_giaVeController.text),
          'taiXe': _selectedDriverName ?? 'Chưa phân công',
          'taiXeId': _selectedDriverId,
          'bienSoXe': _bienSoXeController.text.trim().isEmpty
              ? 'Chưa cập nhật'
              : _bienSoXeController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo chuyến đi thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Delay để user thấy snackbar
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            // Kiểm tra Navigator history trước khi pop
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            } else {
              // Nếu không thể pop, navigate về trips screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/trips',
                (route) => false,
              );
            }
          }
        }
      } else {
        throw Exception(
          'Lỗi tạo chuyến đi: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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

  Widget _buildDriverSelector() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final drivers = userProvider.drivers;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Dropdown chọn tài xế
              DropdownButtonFormField<String>(
                value: _selectedDriverId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: 'Chọn tài xế từ danh sách',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Không chọn tài xế'),
                  ),
                  ...drivers.map((driver) {
                    return DropdownMenuItem<String>(
                      value: driver.id,
                      child: Text(
                        '${driver.hoTen} (${driver.soDienThoai})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (String? newValue) {
                  try {
                    setState(() {
                      _selectedDriverId = newValue;
                      if (newValue != null && drivers.isNotEmpty) {
                        final driver = drivers.firstWhere(
                          (d) => d.id == newValue,
                          orElse: () => drivers.first,
                        );
                        _selectedDriverName = driver.hoTen;
                        _taiXeController.text = driver.hoTen;
                        _bienSoXeController.text =
                            driver.bienSoXe ?? 'Chưa cập nhật';
                      } else {
                        _selectedDriverName = null;
                        _taiXeController.clear();
                        _bienSoXeController.clear();
                      }
                    });
                  } catch (e) {
                    print('❌ Error selecting driver: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi chọn tài xế: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),

              // Hiển thị thông tin tài xế đã chọn
              if (_selectedDriverId != null) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDriverName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _bienSoXeController.text,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  drivers
                                      .firstWhere(
                                        (d) => d.id == _selectedDriverId,
                                      )
                                      .soDienThoai,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDriverId = null;
                            _selectedDriverName = null;
                            _taiXeController.clear();
                            _bienSoXeController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Bỏ chọn tài xế',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Điểm đi
            _buildSearchableDropdown(
              label: 'Điểm đi',
              hint: 'Chọn điểm đi',
              value: _diemDiController.text.isEmpty
                  ? null
                  : _diemDiController.text,
              items: _tinhThanhVietNam,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _diemDiController.text = newValue;
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn điểm đi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Điểm đến
            _buildSearchableDropdown(
              label: 'Điểm đến',
              hint: 'Chọn điểm đến',
              value: _diemDenController.text.isEmpty
                  ? null
                  : _diemDenController.text,
              items: _tinhThanhVietNam,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _diemDenController.text = newValue;
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn điểm đến';
                }
                if (value == _diemDiController.text) {
                  return 'Điểm đến phải khác điểm đi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Thời gian khởi hành
            Text(
              'Thời gian khởi hành',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDateTime == null
                      ? 'Chọn ngày và giờ khởi hành'
                      : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} - ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDateTime == null
                        ? Colors.grey[600]
                        : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Số ghế
            Text(
              'Số ghế',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _soGhe,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [16, 20, 24, 28, 32].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value ghế'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _soGhe = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Giá vé
            Text(
              'Giá vé (VNĐ)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _giaVeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập giá vé',
                suffixText: 'VNĐ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá vé';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Giá vé phải là số dương';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Loại xe
            Text(
              'Loại xe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ghe_ngoi', child: Text('Ghế ngồi')),
                DropdownMenuItem(
                  value: 'giuong_nam',
                  child: Text('Giường nằm'),
                ),
                DropdownMenuItem(value: 'limousine', child: Text('Limousine')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedVehicleType = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Chọn tài xế
            Text(
              'Chọn tài xế',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDriverSelector(),
            const SizedBox(height: 16),
            const SizedBox(height: 32),

            // Nút tạo chuyến đi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang tạo chuyến đi...'),
                        ],
                      )
                    : const Text(
                        'Tạo chuyến đi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return WillPopScope(
        onWillPop: () async {
          // Đảm bảo navigation an toàn khi back
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Tạo chuyến đi mới'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: content,
        ),
      );
    }

    return content;
  }

  // Widget tìm kiếm tỉnh thành cải tiến
  Widget _buildSearchableDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
            prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ],
    );
  }
}
