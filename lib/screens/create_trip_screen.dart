import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../api/vehicle_service.dart';
import '../utils/date_utils.dart';

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
  String? _selectedVehicleId;
  String? _selectedVehicleLabel;
  List<String> _selectedVehicleImages = [];

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

  // Hàm helper để format thời gian gửi lên server
  String _formatDateTimeForServer(DateTime dateTime) {
    // Gửi thời gian local với timezone offset
    // Ví dụ: 2025-01-07T12:00:00+07:00
    final localDateTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
    return dateTime.toUtc().toIso8601String();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          // Tạo DateTime với thời gian local được chọn
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Debug log
          print('🕐 Selected time: $_selectedDateTime');
          print('🕐 Selected time local: ${_selectedDateTime!.toLocal()}');
          print('🕐 Selected time UTC: ${_selectedDateTime!.toUtc()}');
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
      print('- Thời gian local: $_selectedDateTime');
      print(
        '- Thời gian gửi server: ${_formatDateTimeForServer(_selectedDateTime!)}',
      );
      print('- Số ghế: $_soGhe');
      print('- Loại xe: $_selectedVehicleType');
      print('- Giá vé: ${_giaVeController.text}');
      print('- Tài xế: $_selectedDriverName');
      print('- Driver ID: $_selectedDriverId');

      // Debug thêm về timezone
      print('🌍 Timezone debug:');
      print('- Local timezone offset: ${DateTime.now().timeZoneOffset}');
      print('- Selected time in UTC: ${_selectedDateTime!.toUtc()}');
      print('- Selected time in local: ${_selectedDateTime!.toLocal()}');
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
          'thoiGianKhoiHanh': _formatDateTimeForServer(_selectedDateTime!),
          'soGhe': _soGhe,
          'loaiXe': _selectedVehicleType,
          'giaVe': int.parse(_giaVeController.text),
          'taiXe': _selectedDriverName ?? 'Chưa phân công',
          'taiXeId': _selectedDriverId,
          'bienSoXe': _bienSoXeController.text.trim().isEmpty
              ? 'Chưa cập nhật'
              : _bienSoXeController.text.trim(),
          'vehicleId': _selectedVehicleId,
        }),
      );

      if (response.statusCode == 201) {
        // Debug response data
        final responseData = jsonDecode(response.body);
        print('✅ Tạo chuyến thành công!');
        print('📋 Response data: $responseData');

        if (responseData['trip'] != null) {
          print('📋 Trip data from server:');
          print(
            '- Server thoiGianKhoiHanh: ${responseData['trip']['thoiGianKhoiHanh']}',
          );
          if (responseData['trip']['thoiGianKhoiHanh'] != null) {
            final serverTime = DateTime.parse(
              responseData['trip']['thoiGianKhoiHanh'],
            );
            print('- Server time parsed: $serverTime');
            print('- Server time local: ${serverTime.toLocal()}');
            print('- Server time UTC: ${serverTime.toUtc()}');
          }
        }

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
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tạo chuyến đi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Nhập thông tin chi tiết chuyến đi',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chọn xe (tùy chọn)
            Text(
              'Chọn xe (tùy chọn)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildVehicleSelector(),
            const SizedBox(height: 16),
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
            _buildTimePicker(),
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
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createTrip,
                icon: const Icon(Icons.add_road_rounded),
                label: _isLoading
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildTimePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thời gian đã chọn:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDateTime == null
                ? 'Chưa chọn thời gian'
                : AppDateUtils.formatVietnameseDateTime(_selectedDateTime!),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _selectedDateTime == null
                  ? Colors.grey.shade500
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectDateTime,
              icon: const Icon(Icons.access_time, size: 20),
              label: const Text(
                'Chọn thời gian khởi hành',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchVehicles(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final items = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedVehicleId,
                  hint: Text(
                    isLoading ? 'Đang tải danh sách xe...' : 'Không chọn xe',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Không chọn xe'),
                    ),
                    ...items.map((v) {
                      final label =
                          '${v['hangXe'] ?? ''} ${v['tenXe'] ?? ''} - ${v['bienSoXe'] ?? ''}'
                              .trim();
                      return DropdownMenuItem<String?>(
                        value: v['_id'] as String?,
                        child: Text(
                          label.isEmpty ? (v['bienSoXe'] ?? '') : label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedVehicleId = val;
                      if (val == null) {
                        _selectedVehicleLabel = null;
                        _selectedVehicleImages = [];
                      } else {
                        final v = items.firstWhere(
                          (e) => e['_id'] == val,
                          orElse: () => {},
                        );
                        _selectedVehicleLabel =
                            '${v['hangXe'] ?? ''} ${v['tenXe'] ?? ''} - ${v['bienSoXe'] ?? ''}'
                                .trim();
                        _bienSoXeController.text = (v['bienSoXe'] ?? '')
                            .toString();
                        _selectedVehicleType = (v['loaiXe'] ?? 'ghe_ngoi')
                            .toString();
                        _soGhe = (v['soGhe'] ?? _soGhe) as int;
                        final imgs =
                            (v['hinhAnh'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                        _selectedVehicleImages = imgs;
                      }
                    });
                  },
                ),
              ),
            ),
            if (_selectedVehicleLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Đã chọn: $_selectedVehicleLabel',
                style: const TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectedVehicleId == null
                        ? null
                        : _addVehicleImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Thêm ảnh xe'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedVehicleId == null
                        ? null
                        : _addVehicleImageByUrl,
                    icon: const Icon(Icons.link),
                    label: const Text('Thêm từ URL'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedVehicleImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedVehicleImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final url = _selectedVehicleImages[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _displayImageUrl(url),
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final resp = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/vehicles'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _addVehicleImages() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked.isEmpty) return;
      final paths = picked.map((x) => x.path).toList();
      final urls = await VehicleService.uploadImages(paths);

      // Merge ảnh mới vào preview cục bộ
      setState(() {
        _selectedVehicleImages.addAll(urls);
      });

      // Lưu vào vehicle bên server
      if (_selectedVehicleId != null) {
        await VehicleService.updateVehicle(_selectedVehicleId!, {
          'hinhAnh': _selectedVehicleImages,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload ảnh lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _displayImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return ApiConstants.baseUrl + url;
  }

  Future<void> _addVehicleImageByUrl() async {
    String url = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ảnh từ URL'),
        content: TextFormField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Dán đường dẫn ảnh (http/https)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => url = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!url.startsWith('http')) return; // đơn giản
              Navigator.pop(ctx);
              setState(() => _selectedVehicleImages.add(url));
              if (_selectedVehicleId != null) {
                await VehicleService.updateVehicle(_selectedVehicleId!, {
                  'hinhAnh': _selectedVehicleImages,
                });
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
