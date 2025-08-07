import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool showAppBar;

  const ChatListScreen({super.key, this.showAppBar = true});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _userId = '';
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildQuickActions(),
        Expanded(child: _buildChatList()),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<ChatProvider>(
                  context,
                  listen: false,
                ).loadChatRooms(_userId);
              },
            ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liên hệ nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsForRole(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsForRole() {
    switch (_userRole) {
      case 'admin':
        return Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Tài xế',
                'Chat với tài xế',
                Icons.drive_eta,
                Colors.blue,
                () => _showDriverSelection(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Khách hàng',
                'Chat với khách hàng',
                Icons.people,
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
              child: _buildQuickActionCard(
                'Hỗ trợ Admin',
                'Liên hệ với quản trị viên',
                Icons.support_agent,
                Colors.red,
                () => _chatWithAdmin(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Khách hàng',
                'Chat với khách hàng đã đặt vé',
                Icons.people,
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
              child: _buildQuickActionCard(
                'Hỗ trợ Admin',
                'Liên hệ với quản trị viên',
                Icons.support_agent,
                Colors.red,
                () => _chatWithAdmin(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Tài xế',
                'Chat với tài xế trong vé đã mua',
                Icons.local_shipping,
                Colors.blue,
                () => _showMyDrivers(),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.chatRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có cuộc trò chuyện nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn "Hỗ trợ Admin" để bắt đầu chat',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => chatProvider.loadChatRooms(_userId),
          child: ListView.builder(
            itemCount: chatProvider.chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatProvider.chatRooms[index];
              return _buildChatRoomCard(chatRoom);
            },
          ),
        );
      },
    );
  }

  Widget _buildChatRoomCard(ChatRoom chatRoom) {
    final otherParticipantIndex = chatRoom.participants.indexOf(_userId) == 0
        ? 1
        : 0;
    final otherParticipantName =
        chatRoom.participantNames.length > otherParticipantIndex
        ? chatRoom.participantNames[otherParticipantIndex]
        : 'Người dùng';
    final otherParticipantRole =
        chatRoom.participantRoles.length > otherParticipantIndex
        ? chatRoom.participantRoles[otherParticipantIndex]
        : 'user';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(otherParticipantRole),
          child: Icon(_getRoleIcon(otherParticipantRole), color: Colors.white),
        ),
        title: Text(
          otherParticipantName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatRoom.tripRoute != null)
              Text(
                chatRoom.tripRoute!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (chatRoom.lastMessage != null)
              Text(
                'Tin nhắn mới...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (chatRoom.lastMessage != null)
              Text(
                _formatTime(chatRoom.updatedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (chatRoom.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chatRoom.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _openChat(chatRoom),
      ),
    );
  }

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
        return Icons.admin_panel_settings;
      case 'driver':
      case 'tai_xe':
        return Icons.local_shipping;
      default:
        return Icons.person;
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
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final chatRoomId = await chatProvider.createOrGetChatRoom(
      currentUserId: _userId,
      currentUserName: _userName,
      currentUserRole: _userRole,
      targetUserId: 'admin',
      targetUserName: 'Admin Hà Phương',
      targetUserRole: 'admin',
    );

    if (chatRoomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            chatRoomName: 'Hỗ trợ Admin',
            targetUserName: 'Admin Hà Phương',
            targetUserRole: 'admin',
          ),
        ),
      );
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
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'roomId': roomId,
            'roomName': targetUser.hoTen,
            'targetUserId': targetUser.id,
            'targetUserName': targetUser.hoTen,
            'targetUserRole': targetUser.vaiTro,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openChat(ChatRoom chatRoom) {
    final otherParticipantIndex = chatRoom.participants.indexOf(_userId) == 0
        ? 1
        : 0;
    final otherParticipantName =
        chatRoom.participantNames.length > otherParticipantIndex
        ? chatRoom.participantNames[otherParticipantIndex]
        : 'Người dùng';
    final otherParticipantRole =
        chatRoom.participantRoles.length > otherParticipantIndex
        ? chatRoom.participantRoles[otherParticipantIndex]
        : 'user';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoom.id,
          chatRoomName: chatRoom.name.isNotEmpty
              ? chatRoom.name
              : otherParticipantName,
          targetUserName: otherParticipantName,
          targetUserRole: otherParticipantRole,
          tripRoute: chatRoom.tripRoute,
        ),
      ),
    );
  }
}
