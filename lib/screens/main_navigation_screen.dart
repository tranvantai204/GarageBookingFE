import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_list_screen.dart';
import 'booking_history_screen.dart';
import 'create_trip_screen.dart';
import 'profile_screen.dart';

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
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('vaiTro') ?? 'user';
    });
  }

  List<Widget> get _screens {
    final screens = [
      TripListScreen(showAppBar: false), // Tắt AppBar vì đã có trong MainNavigationScreen
      BookingHistoryScreen(showAppBar: false),
    ];
    
    // Chỉ admin mới có tab tạo chuyến đi
    if (_userRole == 'admin') {
      screens.insert(1, CreateTripScreen(showAppBar: false));
    }
    
    screens.add(ProfileScreen(showAppBar: false));
    return screens;
  }

  List<BottomNavigationBarItem> get _navItems {
    final items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.directions_bus),
        label: 'Chuyến đi',
      ),
    ];
    
    // Chỉ admin mới có tab tạo chuyến đi
    if (_userRole == 'admin') {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Tạo chuyến',
        ),
      );
    }
    
    items.addAll([
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Lịch sử',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ]);
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }

  String _getAppBarTitle() {
    if (_userRole == 'admin') {
      switch (_currentIndex) {
        case 0:
          return 'Quản lý chuyến đi';
        case 1:
          return 'Tạo chuyến đi';
        case 2:
          return 'Lịch sử đặt vé';
        case 3:
          return 'Tài khoản';
        default:
          return 'Hà Phương';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'Đặt xe Hà Phương';
        case 1:
          return 'Lịch sử đặt vé';
        case 2:
          return 'Tài khoản';
        default:
          return 'Hà Phương';
      }
    }
  }
}
