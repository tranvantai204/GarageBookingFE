import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/logo_widget.dart';
import '../providers/chat_provider.dart';
import '../providers/socket_provider.dart';
import 'voice_call_screen.dart';
import 'trip_list_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'modern_chat_list_screen.dart'; // Use modern chat list screen
import 'notifications_center_screen.dart';
import 'driver_trips_screen.dart';
import 'booking_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';
import '../models/message_status.dart';
import '../api/admin_service.dart';
import '../utils/event_bus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _userRole = 'user';
  String _userId = '';
  int _adminNotifCount = 0; // unread only
  int _systemNotifCount = 0; // unread only
  int get _totalNotifCount => _adminNotifCount + _systemNotifCount;

  @override
  void initState() {
    super.initState();
    print('🏠 MainNavigationScreen initState called');
    // Enforce session validity on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionManager.enforceOrLogout(context);
    });
    _loadUserRole();
    _bootstrapSocket();
    _listenIncomingCall();
    _loadNotificationCounts();
    // Nhắc người dùng thêm email để khôi phục mật khẩu (có thể bỏ qua)
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptAddEmail());
    EventBus().stream.listen((event) {
      if (event == Events.notificationsUpdated ||
          event == Events.adminBroadcastReceived) {
        _loadNotificationCounts();
      }
    });
  }

  Future<void> _maybePromptAddEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final dismissed = prefs.getBool('dismissAddEmailPrompt') ?? false;
      final role = prefs.getString('vaiTro') ?? 'user';
      if (role == 'admin' || dismissed || email.isNotEmpty) return;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Thêm email để khôi phục mật khẩu'),
            content: const Text(
              'Bạn chưa thêm email. Việc thêm email giúp bạn lấy lại mật khẩu khi quên. Bạn có thể thêm ngay bây giờ hoặc để sau.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.setBool('dismissAddEmailPrompt', true);
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Để sau'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (mounted) Navigator.pop(ctx);
                  await _promptAndSaveEmail();
                },
                child: const Text('Thêm email ngay'),
              ),
            ],
          );
        },
      );
    } catch (_) {}
  }

  Future<void> _promptAndSaveEmail() async {
    final controller = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập email của bạn'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'vd: tenban@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final email = controller.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      if (token.isEmpty || userId.isEmpty) return;
      final resp = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/auth/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      if (resp.statusCode == 200) {
        await prefs.setString('email', email);
        await prefs.setBool('dismissAddEmailPrompt', true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu email vào tài khoản')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu email thất bại: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi lưu email: $e')));
    }
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
      _userId = userId;
    });

    print('✅ User role set to: $_userRole');

    // Start chat list polling để auto-load tin nhắn mới
    if (userId.isNotEmpty && mounted) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.startChatListPolling(userId);
      print('🔄 Started chat list polling for user: $userId');
    }
  }

  Future<void> _bootstrapSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) return; // Cho phép connect ngay cả khi token rỗng

      final socketProvider = Provider.of<SocketProvider>(
        context,
        listen: false,
      );
      if (!socketProvider.isConnected) {
        socketProvider.connect(
          'https://garagebooking.onrender.com',
          token,
          userId,
        );
      } else {
        socketProvider.emit('join', userId);
      }
      // Listen for new messages to update chat list/unread badge in realtime
      socketProvider.off('new_message');
      socketProvider.on('new_message', (data) async {
        try {
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          final id = _userId.isNotEmpty
              ? _userId
              : (await SharedPreferences.getInstance()).getString('userId') ??
                    '';
          if (id.isNotEmpty) {
            await chatProvider.loadChatRooms(id, forceReload: true);
          }
        } catch (_) {}
      });

      // Online/offline status updates
      socketProvider.off('user_status_update');
      socketProvider.on('user_status_update', (data) {
        try {
          if (!mounted) return;
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          final uid = (data['userId'] ?? '').toString();
          final isOnline = data['isOnline'] == true;
          final lastActiveStr = data['lastActiveAt']?.toString();
          if (uid.isNotEmpty) {
            chatProvider.updateOnlineStatus(uid, isOnline);
            if (lastActiveStr != null) {
              final parsed = DateTime.tryParse(lastActiveStr);
              if (parsed != null) {
                chatProvider.updateLastActiveTime(uid, parsed);
              }
            }
          }
        } catch (_) {}
      });

      // Message delivery/read receipts
      socketProvider.off('message_delivered');
      socketProvider.on('message_delivered', (data) {
        try {
          final chatId = (data['chatId'] ?? '').toString();
          final messageId = (data['messageId'] ?? '').toString();
          if (chatId.isEmpty || messageId.isEmpty) return;
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          chatProvider.setMessageStatusLocal(
            chatId,
            messageId,
            MessageStatus.delivered,
          );
        } catch (_) {}
      });

      socketProvider.off('message_seen');
      socketProvider.on('message_seen', (data) {
        try {
          final chatId = (data['chatId'] ?? '').toString();
          final messageId = (data['messageId'] ?? '').toString();
          if (chatId.isEmpty || messageId.isEmpty) return;
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          chatProvider.setMessageStatusLocal(
            chatId,
            messageId,
            MessageStatus.seen,
          );
        } catch (_) {}
      });
    } catch (e) {
      print('❌ Socket bootstrap error: $e');
    }
  }

  Future<void> _loadNotificationCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inbox = prefs.getStringList('inbox') ?? [];
      // compute unread by comparing stored last-open time
      final lastOpened = prefs.getString('inboxLastOpenedAt');
      DateTime? last;
      if (lastOpened != null) {
        last = DateTime.tryParse(lastOpened);
      }
      int systemCount = 0;
      if (last == null) {
        systemCount = inbox.length;
      } else {
        // items are stored newest-first with their iso timestamp at position 2
        for (final raw in inbox) {
          final parts = raw.split('|');
          if (parts.length >= 3) {
            final ts = DateTime.tryParse(parts[2]);
            if (ts != null && ts.isAfter(last)) systemCount++;
          }
        }
      }
      int adminCount = 0;
      try {
        final items = await AdminService.fetchAdminNotifications();
        final adminLast = prefs.getString('adminNotifLastOpenedAt');
        DateTime? adminTs;
        if (adminLast != null) adminTs = DateTime.tryParse(adminLast);
        if (adminTs == null) {
          adminCount = items.length;
        } else {
          final cutoff = adminTs; // non-null
          adminCount = items.where((e) {
            final c = e['createdAt']?.toString();
            if (c == null) return true;
            final t = DateTime.tryParse(c);
            return t == null || t.isAfter(cutoff);
          }).length;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _systemNotifCount = systemCount;
        _adminNotifCount = adminCount;
      });
    } catch (_) {}
  }

  void _listenIncomingCall() {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    socketProvider.off('incoming_call');
    socketProvider.off('call_cancelled');
    socketProvider.off('call_ended');

    socketProvider.on('incoming_call', (data) async {
      if (!mounted) return;
      final channelName = data['channelName'] as String?;
      final caller = data['caller'] as Map?;
      if (channelName == null || caller == null) return;

      final callerName = caller['userName'] as String? ?? 'Người gọi';
      final callerRole = caller['userRole'] as String? ?? 'user';

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cuộc gọi đến',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'decline'),
                      icon: const Icon(Icons.call_end),
                      label: const Text('Từ chối'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'accept'),
                      icon: const Icon(Icons.call),
                      label: const Text('Nghe máy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (action == 'accept') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              channelName: channelName,
              targetUserName: callerName,
              targetUserRole: callerRole,
              isIncoming: true,
            ),
          ),
        );

        socketProvider.emit('accept_call', {
          'callerUserId': caller['userId'],
          'channelName': channelName,
        });
      } else if (action == 'decline') {
        socketProvider.emit('decline_call', {
          'callerUserId': caller['userId'],
          'channelName': channelName,
        });
      }
    });

    socketProvider.on('call_cancelled', (data) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    socketProvider.on('call_ended', (data) async {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  List<Widget> get _screens {
    if (_userRole == 'admin') {
      return [
        const AdminDashboardScreen(),
        TripListScreen(showAppBar: false),
        BookingHistoryScreen(showAppBar: false),
        ModernChatListScreen(showAppBar: false), // Use ModernChatListScreen
        ProfileScreen(showAppBar: false),
      ];
    } else if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return [
        const DriverTripsScreen(),
        BookingHistoryScreen(showAppBar: false),
        ModernChatListScreen(showAppBar: false),
        ProfileScreen(showAppBar: false),
      ];
    } else {
      return [
        TripListScreen(showAppBar: false),
        BookingHistoryScreen(showAppBar: false),
        ModernChatListScreen(showAppBar: false), // Use ModernChatListScreen
        ProfileScreen(showAppBar: false),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(int unreadCount) {
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
          icon: Icon(Icons.confirmation_number),
          label: 'Vé của tôi',
        ),
        BottomNavigationBarItem(
          icon: _buildChatIcon(unreadCount),
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
          icon: Icon(Icons.confirmation_number),
          label: 'Vé của tôi',
        ),
        BottomNavigationBarItem(
          icon: _buildChatIcon(unreadCount),
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
          icon: Icon(Icons.confirmation_number),
          label: 'Vé của tôi',
        ),
        BottomNavigationBarItem(
          icon: _buildChatIcon(unreadCount),
          label: 'Tin nhắn',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ];
    }
  }

  // Build chat icon với badge count
  Widget _buildChatIcon(int unreadCount) {
    if (unreadCount > 0) {
      return Stack(
        children: [
          const Icon(Icons.chat),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    } else {
      return const Icon(Icons.chat);
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
        actions: [_buildInboxIcon()],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Admin broadcast marquee at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 56, // above bottom nav
            child: _MaybeAdminMarquee(),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return BottomNavigationBar(
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
            items: _getNavItems(chatProvider.totalUnreadCount),
          );
        },
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
          return 'Vé của tôi';
        case 3:
          return 'Tin nhắn';
        case 4:
          return 'Tài khoản';
        default:
          return 'Admin Panel';
      }
    } else {
      if (_userRole == 'driver' || _userRole == 'tai_xe') {
        switch (_currentIndex) {
          case 0:
            return 'Dashboard tài xế';
          case 1:
            return 'Vé của tôi';
          case 2:
            return 'Tin nhắn';
          case 3:
            return 'Tài khoản';
          default:
            return 'Dashboard tài xế';
        }
      } else {
        switch (_currentIndex) {
          case 0:
            return 'GarageBooking';
          case 1:
            return 'Vé của tôi';
          case 2:
            return 'Tin nhắn';
          case 3:
            return 'Tài khoản';
          default:
            return 'GarageBooking';
        }
      }
    }
  }

  Widget _buildInboxIcon() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.inbox),
            tooltip: 'Thông báo',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsCenterScreen(),
                ),
              );
              if (mounted) {
                _loadNotificationCounts();
              }
            },
          ),
          if (_totalNotifCount > 0)
            Positioned(
              right: 6,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _totalNotifCount > 99 ? '99+' : _totalNotifCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaybeAdminMarquee extends StatefulWidget {
  @override
  State<_MaybeAdminMarquee> createState() => _MaybeAdminMarqueeState();
}

class _MaybeAdminMarqueeState extends State<_MaybeAdminMarquee> {
  bool _show = true;

  @override
  void initState() {
    super.initState();
    _load();
    EventBus().stream.listen((event) {
      if (event == Events.settingsChanged) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _show = prefs.getBool('showAdminTicker') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return _AdminMarquee();
  }
}

class _AdminMarquee extends StatefulWidget {
  @override
  State<_AdminMarquee> createState() => _AdminMarqueeState();
}

class _AdminMarqueeState extends State<_AdminMarquee> {
  List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _running = false;
  static const double _speedPxPerSecond = 60;

  @override
  void initState() {
    super.initState();
    _load();
    EventBus().stream.listen((event) {
      if (event == Events.notificationsUpdated ||
          event == Events.adminBroadcastReceived) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    try {
      final items = await AdminService.fetchAdminNotifications();
      setState(() {
        _messages = items
            .map((e) => '${e['title'] ?? ''}: ${e['body'] ?? ''}')
            .toList();
      });
      final prefs = await SharedPreferences.getInstance();
      final ticker = prefs.getString('upcomingTripTicker');
      if (ticker != null && ticker.isNotEmpty) {
        _messages.add(ticker);
      }
      _restartMarquee();
    } catch (_) {}
  }

  @override
  void dispose() {
    _running = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) return const SizedBox.shrink();
    final joined = _messages.join('     •     ');
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      height: 36,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Text(
              joined,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 64),
            Text(
              joined,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restartMarquee() async {
    if (!mounted) return;
    _running = false;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    if (_messages.isEmpty) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartMarquee());
      return;
    }
    _scrollController.jumpTo(0);
    _running = true;
    while (mounted && _running && _messages.isNotEmpty) {
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }
      final remaining = max - _scrollController.offset;
      final durationMs = (remaining / _speedPxPerSecond * 1000)
          .clamp(500, 60000)
          .toInt();
      try {
        await _scrollController.animateTo(
          max,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      } catch (_) {}
      if (!mounted || !_running) break;
      _scrollController.jumpTo(0);
    }
  }
}
