import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import 'chat_screen_with_online_call.dart';

class ModernChatListScreen extends StatefulWidget {
  final bool showAppBar;

  const ModernChatListScreen({super.key, this.showAppBar = true});

  @override
  State<ModernChatListScreen> createState() => _ModernChatListScreenState();
}

class _ModernChatListScreenState extends State<ModernChatListScreen>
    with TickerProviderStateMixin {
  String _userId = '';
  String _userName = '';
  String _userRole = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserInfo();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
      _userName = prefs.getString('hoTen') ?? '';
      _userRole = prefs.getString('vaiTro') ?? 'user';
    });

    if (_userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ChatProvider>(
            context,
            listen: false,
          ).loadChatRooms(_userId);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildModernQuickActions(),
        Expanded(child: _buildModernChatList()),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildModernAppBar(),
        body: content,
      );
    }

    return content;
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Tin nhắn',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blue),
            onPressed: () {
              Provider.of<ChatProvider>(
                context,
                listen: false,
              ).loadChatRooms(_userId, forceReload: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Liên hệ nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernQuickActionsForRole(),
        ],
      ),
    );
  }

  Widget _buildModernQuickActionsForRole() {
    switch (_userRole) {
      case 'admin':
        return Row(
          children: [
            Expanded(
              child: _buildModernQuickActionCard(
                'Tài xế',
                'Chat với tài xế',
                Icons.drive_eta_rounded,
                Colors.blue,
                () => _showDriverSelection(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernQuickActionCard(
                'Khách hàng',
                'Chat với khách hàng',
                Icons.people_rounded,
                Colors.green,
                () => _showCustomerSelection(),
              ),
            ),
          ],
        );

      case 'tai_xe':
      case 'driver':
        return Row(
          children: [
            Expanded(
              child: _buildModernQuickActionCard(
                'Hỗ trợ Admin',
                'Liên hệ quản trị viên',
                Icons.support_agent_rounded,
                Colors.red,
                () => _chatWithAdmin(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernQuickActionCard(
                'Khách hàng',
                'Chat với khách đã đặt vé',
                Icons.people_rounded,
                Colors.green,
                () => _showMyPassengers(),
              ),
            ),
          ],
        );

      case 'user':
      default:
        return Row(
          children: [
            Expanded(
              child: _buildModernQuickActionCard(
                'Hỗ trợ Admin',
                'Liên hệ quản trị viên',
                Icons.support_agent_rounded,
                Colors.red,
                () => _chatWithAdmin(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernQuickActionCard(
                'Tài xế',
                'Chat với tài xế',
                Icons.local_shipping_rounded,
                Colors.blue,
                () => _showMyDrivers(),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildModernQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernChatList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (chatProvider.chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () =>
                chatProvider.loadChatRooms(_userId, forceReload: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chatProvider.chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatProvider.chatRooms[index];
                return _buildModernChatRoomCard(chatRoom, index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn "Hỗ trợ Admin" để bắt đầu chat',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChatRoomCard(ChatRoom chatRoom, int index) {
    final participant = chatRoom.participant;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isTyping = chatProvider.typingStatus[chatRoom.id] ?? false;
    final isOnline = chatProvider.onlineStatus[participant.id] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openChat(chatRoom),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'avatar_${chatRoom.id}',
                          child: Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _getRoleColor(participant.role),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRoleColor(
                                        participant.role,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getRoleIcon(participant.role),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      participant.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (chatRoom.lastMessage != null)
                                    Text(
                                      _formatTime(
                                        chatRoom.lastMessage!.timestamp,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (isTyping)
                                Row(
                                  children: [
                                    _buildTypingIndicator(),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đang nhập...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              else if (chatRoom.lastMessage != null)
                                Text(
                                  chatRoom.lastMessage!.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              if (chatRoom.tripRoute != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    chatRoom.tripRoute!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (chatRoom.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chatRoom.unreadCount > 99
                                  ? '99+'
                                  : chatRoom.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTypingDot(0),
        const SizedBox(width: 2),
        _buildTypingDot(1),
        const SizedBox(width: 2),
        _buildTypingDot(2),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // Rest of the methods remain the same...
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'driver':
      case 'tai_xe':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'driver':
      case 'tai_xe':
        return Icons.local_shipping_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Vừa xong';
    }
  }

  void _chatWithAdmin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUsers();

    final adminUsers = userProvider.users
        .where((user) => user.vaiTro == 'admin' && user.id.length == 24)
        .toList();

    if (adminUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy admin để chat'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final adminUser = adminUsers.first;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final chatRoomId = await chatProvider.createOrGetChatRoom(
      currentUserId: _userId,
      currentUserName: _userName,
      currentUserRole: _userRole,
      targetUserId: adminUser.id,
      targetUserName: adminUser.hoTen,
      targetUserRole: adminUser.vaiTro,
    );

    if (chatRoomId != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreenWithOnlineCall(
            chatRoomId: chatRoomId,
            chatRoomName: 'Hỗ trợ Admin',
            targetUserName: 'Admin Hà Phương',
            targetUserRole: 'admin',
            targetUserId: adminUser.id,
          ),
        ),
      );

      if (result == true && mounted) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.loadChatRooms(_userId, forceReload: true);
      }
    }
  }

  void _showDriverSelection() {
    _showUserSelectionDialog('tai_xe', 'Chọn tài xế để chat');
  }

  void _showCustomerSelection() {
    _showUserSelectionDialog('user', 'Chọn khách hàng để chat');
  }

  void _showMyPassengers() {
    _showUserSelectionDialog('user', 'Khách hàng đã đặt vé');
  }

  void _showMyDrivers() {
    _showUserSelectionDialog('tai_xe', 'Tài xế trong vé đã mua');
  }

  void _showUserSelectionDialog(String targetRole, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = userProvider.getUsersByRole(targetRole);

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Không có ${targetRole == 'tai_xe' ? 'tài xế' : 'khách hàng'} nào',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: targetRole == 'tai_xe'
                          ? Colors.blue
                          : Colors.green,
                      child: Icon(
                        targetRole == 'tai_xe' ? Icons.drive_eta : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user.hoTen),
                    subtitle: Text(user.soDienThoai),
                    onTap: () {
                      Navigator.pop(context);
                      _startChatWithUser(user);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _startChatWithUser(User targetUser) async {
    final chatProvider = context.read<ChatProvider>();

    try {
      final roomId = await chatProvider.createOrGetChatRoom(
        currentUserId: _userId,
        currentUserName: _userName,
        currentUserRole: _userRole,
        targetUserId: targetUser.id,
        targetUserName: targetUser.hoTen,
        targetUserRole: targetUser.vaiTro,
      );

      if (roomId != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreenWithOnlineCall(
              chatRoomId: roomId,
              chatRoomName: targetUser.hoTen,
              targetUserName: targetUser.hoTen,
              targetUserRole: targetUser.vaiTro,
              targetUserId: targetUser.id,
            ),
          ),
        );

        if (result == true && mounted) {
          final chatProvider = Provider.of<ChatProvider>(
            context,
            listen: false,
          );
          await chatProvider.loadChatRooms(_userId, forceReload: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo chat: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _openChat(ChatRoom chatRoom) async {
    final participant = chatRoom.participant;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenWithOnlineCall(
          chatRoomId: chatRoom.id,
          chatRoomName: participant.name,
          targetUserName: participant.name,
          targetUserRole: participant.role,
          targetUserId: participant.id,
          tripRoute: chatRoom.tripRoute,
        ),
      ),
    );

    if (result == true && mounted) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadChatRooms(_userId, forceReload: true);
    }
  }
}
