import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';
import '../models/trip.dart';
import '../constants/api_constants.dart';
import 'create_trip_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripListScreen extends StatefulWidget {
  final bool showAppBar;

  const TripListScreen({super.key, this.showAppBar = true});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  String _userRole = 'user';
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Sử dụng WidgetsBinding để đảm bảo load trips sau khi build hoàn thành
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TripProvider>(context, listen: false).loadTrips();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedRole = prefs.getString('vaiTro') ?? 'user';
    final loadedName = prefs.getString('hoTen') ?? '';
    final loadedUserId = prefs.getString('userId') ?? '';

    setState(() {
      _userRole = loadedRole;
      _userName = loadedName;
      _userId = loadedUserId;
    });

    // Kiểm tra lại vai trò từ server để đảm bảo chính xác
    // await _refreshUserRole(); // Tạm tắt vì API /auth/me không tồn tại
  }

  Future<void> _refreshUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final url = Uri.parse('${ApiConstants.baseUrl}/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final serverRole = jsonResponse['vaiTro'] ?? 'user';

        // Cập nhật lại SharedPreferences nếu khác
        if (serverRole != _userRole) {
          await prefs.setString('vaiTro', serverRole);
          setState(() {
            _userRole = serverRole;
          });
        }
      } else if (response.statusCode == 401) {
        // Token hết hạn, đăng xuất
        _logout();
      }
    } catch (e) {
      // Lỗi khi refresh user role, tiếp tục sử dụng role đã lưu
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Xóa tất cả dữ liệu user
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('hoTen');
      await prefs.remove('vaiTro');

      // Xóa toàn bộ SharedPreferences để đảm bảo
      await prefs.clear();

      if (mounted) {
        // Hiển thị thông báo đăng xuất
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng xuất thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Chuyển về màn hình đăng nhập
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Lỗi khi logout, vẫn chuyển về login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  List<dynamic> _getFilteredTrips(List<dynamic> allTrips) {
    // Nếu là driver/tài xế, chỉ hiển thị chuyến được giao
    if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return allTrips.where((trip) {
        // Filter theo tên tài xế hoặc ID tài xế
        return trip.taiXe == _userName ||
            trip.taiXeId == _userId ||
            trip.taiXe?.toLowerCase().contains(_userName.toLowerCase()) == true;
      }).toList();
    }

    // Admin và user thấy tất cả chuyến
    return allTrips;
  }

  String _getEmptyMessage() {
    if (_userRole == 'admin') {
      return 'Hãy tạo chuyến đi đầu tiên';
    } else if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return 'Chưa có chuyến đi nào được giao cho bạn';
    } else {
      return 'Chưa có chuyến đi nào. Vui lòng quay lại sau.';
    }
  }

  Color _getRoleBadgeColor() {
    if (_userRole == 'admin') return Colors.red;
    if (_userRole == 'driver' || _userRole == 'tai_xe') return Colors.blue;
    return Colors.green;
  }

  String _getRoleBadgeText() {
    if (_userRole == 'admin') return 'ADMIN';
    if (_userRole == 'driver' || _userRole == 'tai_xe') return 'TÀI XẾ';
    return 'USER';
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: () async {
        await Provider.of<TripProvider>(context, listen: false).loadTrips();
      },
      child: Consumer<TripProvider>(
        builder: (context, tripProvider, child) {
          if (tripProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách chuyến đi...'),
                ],
              ),
            );
          }

          final filteredTrips = _getFilteredTrips(tripProvider.trips);

          if (filteredTrips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có chuyến đi nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getEmptyMessage(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  // Chỉ admin mới thấy nút tạo chuyến đi
                  if (_userRole == 'admin')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTripScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          Provider.of<TripProvider>(
                            context,
                            listen: false,
                          ).loadTrips();
                        }
                      },
                      icon: Icon(Icons.add_box),
                      label: Text('Tạo chuyến đi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              return TripCard(
                trip: trip,
                isAdmin: _userRole == 'admin',
                onTap: () {
                  Navigator.pushNamed(context, '/trip_detail', arguments: trip);
                },
                onDelete: _userRole == 'admin' ? () => _deleteTrip(trip) : null,
              );
            },
          );
        },
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Đặt xe Hà Phương${_userName.isNotEmpty ? ' - $_userName ($_userRole)' : ''}',
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            // QR Scanner button for drivers
            if (_userRole == 'driver' || _userRole == 'tai_xe')
              IconButton(
                onPressed: () {
                  // Navigate to QR Scanner
                  Navigator.pushNamed(context, '/qr_scanner');
                },
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Quét mã QR',
              ),
            // Hiển thị role badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleBadgeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleBadgeText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'create_trip':
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTripScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      Provider.of<TripProvider>(
                        context,
                        listen: false,
                      ).loadTrips();
                    }
                    break;
                  case 'refresh':
                    Provider.of<TripProvider>(
                      context,
                      listen: false,
                    ).loadTrips();
                    break;
                  case 'booking_history':
                    Navigator.pushNamed(context, '/booking_history');
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                // Chỉ admin mới thấy tạo chuyến đi
                if (_userRole == 'admin') ...[
                  PopupMenuItem<String>(
                    value: 'create_trip',
                    child: Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Tạo chuyến đi'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                ],
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Làm mới'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'booking_history',
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Lịch sử đặt vé'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  Future<void> _deleteTrip(Trip trip) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      final success = await tripProvider.deleteTrip(trip.id);

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa chuyến đi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa chuyến đi. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
