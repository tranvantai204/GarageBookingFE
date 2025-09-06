import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_profile_update_screen.dart';
import 'admin_user_management_screen.dart';
import '../utils/event_bus.dart';
import 'wallet_screen.dart';
import 'driver_apply_screen.dart';

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
  int _walletBalance = 0;
  bool _autoOpenChatOnForeground = true;
  bool _showAdminTicker = true;
  bool _callSystemPopupOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Lắng nghe sự kiện ví thay đổi để cập nhật realtime ở màn tài khoản
    EventBus().stream.listen((event) {
      if (event == Events.walletUpdated) {
        _loadUserInfo();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('hoTen') ?? '';
      _userRole = prefs.getString('vaiTro') ?? 'user';
      _userPhone = prefs.getString('soDienThoai') ?? '';
      _walletBalance = prefs.getInt('viSoDu') ?? 0;
      _autoOpenChatOnForeground =
          prefs.getBool('autoOpenChatOnForeground') ?? true;
      _showAdminTicker = prefs.getBool('showAdminTicker') ?? true;
      _callSystemPopupOnly = prefs.getBool('callSystemPopupOnly') ?? false;
    });
  }

  String _getRoleDisplayName() {
    switch (_userRole) {
      case 'admin':
        return 'QUẢN TRỊ VIÊN';
      case 'driver':
      case 'tai_xe':
        return 'TÀI XẾ';
      case 'user':
      default:
        return 'KHÁCH HÀNG';
    }
  }

  Color _getRoleColor() {
    switch (_userRole) {
      case 'admin':
        return Colors.red.shade700;
      case 'driver':
      case 'tai_xe':
        return Colors.blue.shade700;
      case 'user':
      default:
        return Colors.green.shade700;
    }
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
                    child: Icon(Icons.person, size: 60, color: Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _userName.isNotEmpty ? _userName : 'Người dùng',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleDisplayName(),
                      style: TextStyle(
                        color: _getRoleColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_userPhone.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      _userPhone,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                  leading: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                  title: Text('Ví của tôi'),
                  subtitle: Text(
                    'Số dư: ' + _formatCurrency(_walletBalance) + 'đ',
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ).then((_) => _loadUserInfo());
                  },
                ),
                Divider(height: 1),
                if (_userRole == 'user') ...[
                  ListTile(
                    leading: Icon(Icons.drive_eta, color: Colors.teal),
                    title: Text('Đăng ký làm tài xế'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverApplyScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1),
                ],
                SwitchListTile(
                  secondary: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.purple,
                  ),
                  title: Text('Tự mở phòng chat khi đang mở app'),
                  subtitle: Text(
                    'Khi nhận tin nhắn mới trong lúc app đang hoạt động',
                  ),
                  value: _autoOpenChatOnForeground,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('autoOpenChatOnForeground', v);
                    setState(() => _autoOpenChatOnForeground = v);
                    EventBus().emit(Events.settingsChanged);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    Icons.campaign_outlined,
                    color: Colors.orange,
                  ),
                  title: Text('Hiển thị ticker thông báo Admin'),
                  subtitle: Text('Thanh chạy thông báo dưới ứng dụng'),
                  value: _showAdminTicker,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showAdminTicker', v);
                    setState(() => _showAdminTicker = v);
                    EventBus().emit(Events.settingsChanged);
                  },
                ),
                Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    Icons.notification_important_outlined,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Chỉ dùng popup hệ thống cho cuộc gọi (tránh đơ máy)',
                  ),
                  subtitle: Text(
                    'Bật nếu máy bị treo khi hiển thị overlay trong-app',
                  ),
                  value: _callSystemPopupOnly,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('callSystemPopupOnly', v);
                    setState(() => _callSystemPopupOnly = v);
                  },
                ),
                Divider(height: 1),

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
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.blue),
                    title: Text('Quản lý người dùng'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminUserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1),
                ],
                if (_userRole == 'driver' || _userRole == 'tai_xe') ...[
                  ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Cập nhật thông tin tài xế'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DriverProfileUpdateScreen(),
                        ),
                      );
                      if (result == true) {
                        // Reload user info if update was successful
                        _loadUserInfo();
                      }
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.qr_code_scanner, color: Colors.blue),
                    title: Text('Quét mã QR'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/qr_scanner');
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
                            Text('Phát triển bởi: Tran Van Tai Development'),
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => m[1]! + ',',
    );
  }
}
