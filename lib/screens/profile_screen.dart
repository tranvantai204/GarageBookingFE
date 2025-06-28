import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userRole = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('hoTen') ?? '';
      _userRole = prefs.getString('vaiTro') ?? 'user';
      _userPhone = prefs.getString('soDienThoai') ?? '';
    });
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Xóa tất cả dữ liệu user
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
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar và thông tin cơ bản
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _userName.isNotEmpty ? _userName : 'Người dùng',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _userRole == 'admin' ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _userRole == 'admin' ? 'QUẢN TRỊ VIÊN' : 'KHÁCH HÀNG',
                      style: TextStyle(
                        color: _userRole == 'admin' ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_userPhone.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      _userPhone,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Menu options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.history, color: Colors.blue),
                  title: Text('Lịch sử đặt vé'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/booking_history');
                  },
                ),
                Divider(height: 1),
                if (_userRole == 'admin') ...[
                  ListTile(
                    leading: Icon(Icons.add_box, color: Colors.green),
                    title: Text('Tạo chuyến đi'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/create_trip');
                    },
                  ),
                  Divider(height: 1),
                ],
                ListTile(
                  leading: Icon(Icons.info, color: Colors.orange),
                  title: Text('Thông tin ứng dụng'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Thông tin ứng dụng'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ứng dụng đặt xe Hà Phương'),
                            Text('Phiên bản: 1.0.0'),
                            Text('Phát triển bởi: Hà Phương Team'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Đăng xuất'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Xác nhận đăng xuất'),
                        content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            child: Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tài khoản'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }

    return content;
  }
}
