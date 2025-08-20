import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/chat_message.dart';
import '../models/message_status.dart';
import '../services/voice_call_service_improved.dart';
import '../providers/socket_provider.dart';
import 'voice_call_screen.dart';

class ChatScreenWithOnlineCall extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;
  final String targetUserName;
  final String targetUserRole;
  final String? targetUserId;
  final String? tripRoute;

  const ChatScreenWithOnlineCall({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
    required this.targetUserName,
    required this.targetUserRole,
    this.targetUserId,
    this.tripRoute,
  });

  @override
  State<ChatScreenWithOnlineCall> createState() =>
      _ChatScreenWithOnlineCallState();
}

class _ChatScreenWithOnlineCallState extends State<ChatScreenWithOnlineCall>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String _userId = '';
  String _userName = '';
  String _userRole = '';
  String _targetPhoneNumber = '';
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _showScrollToBottom = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _setupAnimations();
    _setupScrollListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();
      _loadInitialMessages();
      _startPolling();
      _joinChatRoom();
      _loadTargetUserPhone();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final showButton = (maxScroll - currentScroll) > 100;

      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
      _userName = prefs.getString('hoTen') ?? '';
      _userRole = prefs.getString('vaiTro') ?? 'user';
    });
  }

  Future<void> _loadTargetUserPhone() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUsers();

      final targetUser = userProvider.users.firstWhere(
        (user) => user.hoTen == widget.targetUserName,
        orElse: () => userProvider.users.first,
      );

      setState(() {
        _targetPhoneNumber = targetUser.soDienThoai;
      });

      print('📞 Target user phone: $_targetPhoneNumber');
    } catch (e) {
      print('❌ Error loading target user phone: $e');
    }
  }

  Future<void> _loadInitialMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadMessages(widget.chatRoomId, limit: 30, offset: 0);
    _scrollToBottom();
  }

  void _joinChatRoom() {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    socketProvider.emit('join_chat', {
      'chatRoomId': widget.chatRoomId,
      'userId': _userId,
    });
  }

  void _startPolling() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.startPolling(widget.chatRoomId);

    final otherUserId = _getOtherUserId();
    if (otherUserId.isNotEmpty) {
      chatProvider.fetchUserActivityStatus(otherUserId);
    }
  }

  String _getOtherUserId() {
    if (widget.targetUserId != null && widget.targetUserId!.isNotEmpty) {
      return widget.targetUserId!;
    }
    // Try resolve from current chat room in ChatProvider
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final room = chatProvider.chatRooms.firstWhere(
        (r) => r.id == widget.chatRoomId,
      );
      if (room.participant.id.isNotEmpty) {
        return room.participant.id;
      }
    } catch (_) {}
    // Fallback: resolve by name from UserProvider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final match = userProvider.users.firstWhere(
        (u) => u.hoTen == widget.targetUserName,
      );
      return match.id;
    } catch (_) {
      // Legacy fallback (may not work with Mongo ObjectId chatRoomId)
      return widget.chatRoomId.replaceAll(_userId, '').replaceAll('_', '');
    }
  }

  void _setupSocketListeners() {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    socketProvider.on('new_message', (data) {
      if (data is Map && data['chatId'] == widget.chatRoomId) {
        chatProvider.loadMessages(widget.chatRoomId);
        _scrollToBottom();
      }
    });

    socketProvider.on('typing_start', (data) {
      if (data is Map &&
          data['chatId'] == widget.chatRoomId &&
          data['userId'] != _userId) {
        setState(() => _isTyping = true);
      }
    });

    socketProvider.on('typing_stop', (data) {
      if (data is Map &&
          data['chatId'] == widget.chatRoomId &&
          data['userId'] != _userId) {
        setState(() => _isTyping = false);
      }
    });
  }

  // Listener exists in MainNavigationScreen to avoid duplicates
  // Keeping this method removed prevents duplicate dialogs
  /* void _listenIncomingCall() {
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
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
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
        // Open voice call screen as incoming
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

        // Notify caller accepted
        socketProvider.emit('accept_call', {
          'callerUserId': caller['userId'],
          'channelName': channelName,
        });
      } else if (action == 'decline') {
        // Notify caller declined
        socketProvider.emit('decline_call', {
          'callerUserId': caller['userId'],
          'channelName': channelName,
        });
      }
    });

    // Optional: hide dialog if caller cancels
    socketProvider.on('call_cancelled', (data) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    socketProvider.on('call_ended', (data) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  } */

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.chatRoomId}',
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(widget.targetUserRole),
              child: Icon(
                _getRoleIcon(widget.targetUserRole),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final otherUserId = _getOtherUserId();
                    final isOnline = chatProvider.isUserOnline(otherUserId);
                    final lastActiveText = chatProvider.getLastActiveText(
                      otherUserId,
                    );

                    return Text(
                      isOnline ? 'Đang hoạt động' : lastActiveText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Gộp 2 nút gọi vào 1 nút
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Gọi',
            icon: const Icon(Icons.call, color: Colors.blue, size: 20),
            onSelected: (value) {
              if (value == 'online') {
                _startOnlineVoiceCall();
              } else if (value == 'phone') {
                _makePhoneCall();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'online',
                child: ListTile(
                  leading: Icon(Icons.headset_mic, color: Colors.purple),
                  title: Text('Gọi online'),
                ),
              ),
              const PopupMenuItem(
                value: 'phone',
                child: ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text('Gọi điện thoại'),
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(widget.targetUserRole).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleText(widget.targetUserRole),
            style: TextStyle(
              color: _getRoleColor(widget.targetUserRole),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  // 🎙️ ONLINE VOICE CALL FUNCTIONALITY
  Future<void> _startOnlineVoiceCall() async {
    // Show call options dialog
    final callType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Gọi online'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn loại cuộc gọi với ${widget.targetUserName}:'),
            const SizedBox(height: 16),

            // Voice call option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.purple, size: 20),
              ),
              title: const Text('Gọi thoại'),
              subtitle: const Text('Cuộc gọi thoại chất lượng cao'),
              onTap: () => Navigator.pop(context, 'voice'),
            ),

            // Video call option (future feature)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam, color: Colors.blue, size: 20),
              ),
              title: const Text('Gọi video'),
              subtitle: const Text('Sắp có (Coming soon)'),
              enabled: false,
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (callType == 'voice') {
      await _initiateVoiceCall();
    }
  }

  Future<void> _initiateVoiceCall() async {
    try {
      // Ensure IDs
      if (_userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('userId') ?? '';
      }
      final otherId = _getOtherUserId();
      if (_userId.isEmpty || otherId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không xác định được người gọi/nhận'),
            backgroundColor: Colors.red[400],
          ),
        );
        return;
      }
      // Create unique channel name for this call
      final channelName = VoiceCallServiceImproved.createChannelName(
        _userId,
        otherId,
      );

      print('🎙️ Starting voice call: $channelName');

      // Signal incoming call to target via socket
      final socketProvider = Provider.of<SocketProvider>(
        context,
        listen: false,
      );
      // Ensure mapping of this socket to current user before starting call
      socketProvider.emit('join', _userId);
      print('🔔 Emitting start_call from $_userId to $otherId on $channelName');
      socketProvider.emit('start_call', {
        'targetUserId': otherId,
        'channelName': channelName,
        'caller': {
          'userId': _userId,
          'userName': _userName,
          'userRole': _userRole,
          'role': _userRole,
        },
      });

      // Navigate to voice call screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            channelName: channelName,
            targetUserName: widget.targetUserName,
            targetUserRole: widget.targetUserRole,
            isIncoming: false,
          ),
        ),
      );

      print('🎙️ Voice call ended with result: $result');

      // Send call history message based on result
      if (result is Map) {
        final status = result['status'] as String?;
        final duration = result['duration'] as int?;
        if (status == 'ended' && duration != null) {
          final mm = (duration ~/ 60).toString().padLeft(2, '0');
          final ss = (duration % 60).toString().padLeft(2, '0');
          await _sendCallNotificationMessage(
            'Cuộc gọi đã kết thúc (${mm}:${ss})',
          );
        } else if (status == 'missed') {
          await _sendCallNotificationMessage('Cuộc gọi nhỡ');
        } else if (status == 'cancelled') {
          await _sendCallNotificationMessage('Đã hủy cuộc gọi');
          // Inform callee UI to hide incoming prompt
          socketProvider.emit('cancel_call', {
            'targetUserId': otherId,
            'channelName': channelName,
          });
        }
      }
    } catch (e) {
      print('❌ Error starting voice call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể bắt đầu cuộc gọi'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _sendCallNotificationMessage(String message) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: _userId,
        senderName: _userName,
        senderRole: _userRole,
        message: '📞 $message',
      );
      await chatProvider.loadMessages(widget.chatRoomId);
      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending call notification: $e');
    }
  }

  // 📞 PHONE CALL FUNCTIONALITY (existing)
  Future<void> _makePhoneCall() async {
    if (_targetPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tìm thấy số điện thoại'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Gọi điện thoại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có muốn gọi cho ${widget.targetUserName}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatPhoneNumber(_targetPhoneNumber),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Gọi ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      await _launchPhoneCall(_targetPhoneNumber);
    }
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final normalized = cleanNumber.replaceFirst(RegExp(r'^\+{2,}'), '+');
      // Use tel:// for better compatibility with some OEMs
      final Uri phoneUri = Uri.parse('tel://$normalized');

      print('📞 Attempting to call: $normalized');

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        print('✅ Phone call launched successfully');
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      print('❌ Error launching phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể thực hiện cuộc gọi'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length >= 10) {
      final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length == 10) {
        return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
      } else if (cleaned.length == 11 && cleaned.startsWith('84')) {
        return '+84 ${cleaned.substring(2, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
      }
    }
    return phoneNumber;
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (chatProvider.currentMessages.isEmpty) {
          return _buildEmptyState();
        }

        final messages = List<ChatMessage>.from(chatProvider.currentMessages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == _userId;
              final showAvatar = _shouldShowAvatar(messages, index);
              final showTimestamp = _shouldShowTimestamp(messages, index);

              return _buildModernMessageBubble(
                message,
                isMe,
                showAvatar,
                showTimestamp,
              );
            },
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi tin nhắn đầu tiên để bắt đầu',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Call buttons in empty state
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Online call button
              ElevatedButton.icon(
                onPressed: _startOnlineVoiceCall,
                icon: const Icon(Icons.call, size: 16),
                label: const Text('Gọi online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Phone call button
              if (_targetPhoneNumber.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Gọi điện'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernMessageBubble(
    ChatMessage message,
    bool isMe,
    bool showAvatar,
    bool showTimestamp,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: showTimestamp ? 16 : 2, top: 2),
      child: Column(
        children: [
          if (showTimestamp) _buildTimestampDivider(message.timestamp),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getRoleColor(message.senderRole),
                  child: Icon(
                    _getRoleIcon(message.senderRole),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (!isMe) ...[
                const SizedBox(width: 40),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: isMe ? () => _showMessageOptions(message) : null,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && showAvatar)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getRoleColor(message.senderRole),
                              ),
                            ),
                          ),
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildMessageStatusIcon(message.status),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isMe && showAvatar) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getRoleColor(_userRole),
                  child: Icon(
                    _getRoleIcon(_userRole),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ] else if (isMe) ...[
                const SizedBox(width: 40),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white70;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = Colors.white;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red[300]!;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getRoleColor(widget.targetUserRole),
            child: Icon(
              _getRoleIcon(widget.targetUserRole),
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onChanged: _handleTypingChanged,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTypingChanged(String text) {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);

    if (text.isNotEmpty) {
      socketProvider.emit('typing_start', {
        'chatId': widget.chatRoomId,
        'userId': _userId,
      });

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 1500), () {
        socketProvider.emit('typing_stop', {
          'chatId': widget.chatRoomId,
          'userId': _userId,
        });
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final success = await chatProvider.sendMessage(
        chatRoomId: widget.chatRoomId,
        senderId: _userId,
        senderName: _userName,
        senderRole: _userRole,
        message: message,
      );

      if (success) {
        await chatProvider.loadMessages(widget.chatRoomId);
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể gửi tin nhắn'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Có lỗi xảy ra khi gửi tin nhắn'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text('Thu hồi tin nhắn'),
              subtitle: const Text('Xóa tin nhắn này khỏi cuộc trò chuyện'),
              onTap: () {
                Navigator.pop(context);
                _recallMessage(message);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.copy, color: Colors.blue, size: 20),
              ),
              title: const Text('Sao chép'),
              subtitle: const Text('Sao chép nội dung tin nhắn'),
              onTap: () {
                Navigator.pop(context);
                // Implement copy functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.purple, size: 20),
              ),
              title: const Text('Gọi online'),
              subtitle: Text('Gọi thoại với ${widget.targetUserName}'),
              onTap: () {
                Navigator.pop(context);
                _startOnlineVoiceCall();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: Colors.green, size: 20),
              ),
              title: const Text('Gọi điện thoại'),
              subtitle: Text('Gọi cho ${widget.targetUserName}'),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, color: Colors.blue, size: 20),
              ),
              title: const Text('Làm mới'),
              subtitle: const Text('Tải lại tin nhắn'),
              onTap: () {
                Navigator.pop(context);
                _loadInitialMessages();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _recallMessage(ChatMessage message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.recallMessage(
      widget.chatRoomId,
      message.id,
    );

    if (success) {
      await chatProvider.loadMessages(widget.chatRoomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tin nhắn đã được thu hồi'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể thu hồi tin nhắn'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  bool _shouldShowAvatar(List<ChatMessage> messages, int index) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.senderId != previousMessage.senderId ||
        currentMessage.timestamp
                .difference(previousMessage.timestamp)
                .inMinutes >
            5;
  }

  bool _shouldShowTimestamp(List<ChatMessage> messages, int index) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.timestamp
            .difference(previousMessage.timestamp)
            .inHours >=
        1;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'ADMIN';
      case 'driver':
      case 'tai_xe':
        return 'TÀI XẾ';
      default:
        return 'USER';
    }
  }
}
