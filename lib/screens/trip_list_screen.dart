import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/trip_provider.dart';
import '../widgets/trip_card.dart';
import '../utils/constants.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
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

    setState(() {
      _userRole = loadedRole;
      _userName = loadedName;
    });

    // Kiểm tra lại vai trò từ server để đảm bảo chính xác
    await _refreshUserRole();
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

          if (tripProvider.trips.isEmpty) {
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
                    _userRole == 'admin'
                        ? 'Hãy tạo chuyến đi đầu tiên'
                        : 'Chưa có chuyến đi nào. Vui lòng quay lại sau.',
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
            itemCount: tripProvider.trips.length,
            itemBuilder: (context, index) {
              final trip = tripProvider.trips[index];
              return TripCard(
                trip: trip,
                onTap: () {
                  Navigator.pushNamed(context, '/trip_detail', arguments: trip);
                },
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
            // Hiển thị role badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _userRole == 'admin' ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userRole == 'admin' ? 'ADMIN' : 'USER',
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
}
