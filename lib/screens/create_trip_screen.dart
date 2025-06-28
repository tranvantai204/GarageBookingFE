import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
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
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) {
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
          'giaVe': int.parse(_giaVeController.text),
          'taiXe': _taiXeController.text.trim().isEmpty
              ? 'Chưa cập nhật'
              : _taiXeController.text.trim(),
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
            ),
          );
          Navigator.pop(context, true); // Trả về true để báo hiệu cần refresh
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

            // Tài xế (tùy chọn)
            Text(
              'Tài xế (tùy chọn)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _taiXeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập tên tài xế',
              ),
            ),
            const SizedBox(height: 16),

            // Biển số xe (tùy chọn)
            Text(
              'Biển số xe (tùy chọn)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bienSoXeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập biển số xe',
              ),
            ),
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tạo chuyến đi mới'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: content,
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
