import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/logo_widget.dart';
import 'trip_list_screen.dart';
import 'create_trip_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'chat_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    print('🏠 MainNavigationScreen initState called');
    _loadUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 MainNavigationScreen didChangeDependencies called');
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    // Debug: Check all stored values
    final allKeys = prefs.getKeys();
    print('🔍 All SharedPreferences keys: $allKeys');
    for (String key in allKeys) {
      final value = prefs.get(key);
      print('   - $key: $value');
    }

    final role = prefs.getString('vaiTro') ?? 'user';
    final userId = prefs.getString('userId') ?? '';
    final userName = prefs.getString('hoTen') ?? '';

    print('🔍 Loading user role from SharedPreferences: $role');
    print('🔍 User ID: $userId');
    print('🔍 User Name: $userName');

    print('🔄 Setting user role from "$_userRole" to "$role"');
    setState(() {
      _userRole = role;
    });

    print('✅ User role set to: $_userRole');
  }

  List<Widget> get _screens {
    if (_userRole == 'admin') {
      return [
        const AdminDashboardScreen(),
        TripListScreen(showAppBar: false),
        CreateTripScreen(showAppBar: false),
        ChatListScreen(showAppBar: false),
        ProfileScreen(showAppBar: false),
      ];
    } else if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return [
        TripListScreen(
          showAppBar: false,
        ), // Temporary: use trip list instead of driver dashboard
        ChatListScreen(showAppBar: false),
        ProfileScreen(showAppBar: false),
      ];
    } else {
      return [
        TripListScreen(showAppBar: false),
        ChatListScreen(showAppBar: false),
        ProfileScreen(showAppBar: false),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_userRole == 'admin') {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Chuyến đi',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Tạo chuyến',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    } else if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    } else {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Chuyến đi',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Tin nhắn',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            LogoWidget(size: 32, animated: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        items: _navItems,
      ),
    );
  }

  String _getAppBarTitle() {
    if (_userRole == 'admin') {
      switch (_currentIndex) {
        case 0:
          return 'Admin Dashboard';
        case 1:
          return 'Quản lý chuyến đi';
        case 2:
          return 'Tạo chuyến đi';
        case 3:
          return 'Quản lý vé đặt';
        case 4:
          return 'Tài khoản';
        default:
          return 'Admin Panel';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'GarageBooking';
        case 1:
          return 'Tin nhắn';
        case 2:
          return 'Tài khoản';
        default:
          return 'GarageBooking';
      }
    }
  }
}
