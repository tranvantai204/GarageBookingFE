import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
// import 'dart:io'; // Removed unused import
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/message_status.dart';
import '../constants/api_constants.dart';

class ChatProvider with ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String _currentChatRoomId = '';
  String? _currentUserId;
  Timer? _pollTimer;
  Timer? _chatListPollTimer;
  int _lastMessageCount = 0;

  // Cache management
  DateTime? _lastChatRoomsLoad;
  String? _lastUserId;
  static const Duration _chatRoomsCacheExpiry = Duration(minutes: 2);

  // Trạng thái đang soạn tin
  Map<String, bool> _typingStatus = {};
  Map<String, bool> get typingStatus => _typingStatus;

  // Trạng thái hoạt động (online/offline)
  Map<String, bool> _onlineStatus = {};
  Map<String, bool> get onlineStatus => _onlineStatus;

  // Thời gian ho���t động gần nhất
  Map<String, DateTime> _lastActiveTime = {};
  Map<String, DateTime> get lastActiveTime => _lastActiveTime;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String get currentChatRoomId => _currentChatRoomId;
  String? get currentUserId => _currentUserId;

  // Tính tổng số tin nhắn chưa đọc cho badge
  int get totalUnreadCount {
    return _chatRooms.fold(0, (total, room) => total + room.unreadCount);
  }

  // Cập nhật trạng thái đang soạn tin
  void updateTypingStatus(String chatRoomId, bool isTyping) {
    _typingStatus[chatRoomId] = isTyping;
    notifyListeners();
  }

  // Cập nhật trạng thái online
  void updateOnlineStatus(String userId, bool isOnline) {
    _onlineStatus[userId] = isOnline;
    notifyListeners();
  }

  // Cập nhật thời gian hoạt động gần nhất
  void updateLastActiveTime(String userId, DateTime time) {
    _lastActiveTime[userId] = time;
    notifyListeners();
  }

  // Get typing status for a specific chat room
  bool isTypingInChat(String chatRoomId) {
    return _typingStatus[chatRoomId] ?? false;
  }

  // Get online status for a specific user
  bool isUserOnline(String userId) {
    return _onlineStatus[userId] ?? false;
  }

  // Get last active time for a specific user
  DateTime? getUserLastActiveTime(String userId) {
    return _lastActiveTime[userId];
  }

  // Format last active time for display
  String getLastActiveText(String userId) {
    final lastActive = _lastActiveTime[userId];
    final isOnline = _onlineStatus[userId] ?? false;

    if (isOnline) {
      return 'Đang hoạt động';
    } else if (lastActive != null) {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } else {
      return 'Ngoại tuyến';
    }
  }

  // Update message status locally based on socket events
  void setMessageStatusLocal(
    String chatRoomId,
    String messageId,
    MessageStatus status,
  ) {
    if (_currentChatRoomId != chatRoomId) return;
    final index = _currentMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    _currentMessages[index] = _currentMessages[index].copyWith(status: status);
    notifyListeners();
  }

  // Cập nhật trạng thái tin nhắn
  Future<void> updateMessageStatus(
    String chatRoomId,
    String messageId,
    MessageStatus status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}/chats/$chatRoomId/messages/$messageId/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status.value}),
      );

      if (response.statusCode == 200) {
        final index = _currentMessages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          _currentMessages[index] = _currentMessages[index].copyWith(
            status: status,
            deliveredAt: status == MessageStatus.delivered
                ? DateTime.now()
                : null,
            seenAt: status == MessageStatus.seen ? DateTime.now() : null,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error updating message status: $e');
    }
  }

  // Đánh dấu tin nhắn đã xem
  Future<void> markMessageAsSeen(String chatRoomId, String messageId) async {
    await updateMessageStatus(chatRoomId, messageId, MessageStatus.seen);
  }

  // Đánh dấu tin nhắn đã nhận
  Future<void> markMessageAsDelivered(
    String chatRoomId,
    String messageId,
  ) async {
    await updateMessageStatus(chatRoomId, messageId, MessageStatus.delivered);
  }

  // Gửi trạng thái đang soạn tin
  Future<void> sendTypingStatus(String chatRoomId, bool isTyping) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chats/$chatRoomId/typing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isTyping': isTyping}),
      );
    } catch (e) {
      print('❌ Error sending typing status: $e');
    }
  }

  // Cập nhật trạng thái hoạt động của người dùng
  UserActivityStatus getUserStatus(String userId) {
    final isOnline = _onlineStatus[userId] ?? false;
    final lastActive = _lastActiveTime[userId];
    int minutesOffline = 0;
    if (!isOnline && lastActive != null) {
      minutesOffline = DateTime.now().difference(lastActive).inMinutes;
    }
    return UserActivityStatus(
      isOnline: isOnline,
      minutesOffline: minutesOffline,
    );
  }

  Future<void> updateUserActivity(
    String userId,
    bool isOnline,
    DateTime? lastActiveAt,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isOnline': isOnline,
          'lastActiveAt': lastActiveAt?.toIso8601String(),
        }),
      );
    } catch (e) {
      print('❌ Error updating user activity: $e');
    }
  }

  // Lấy tin nhắn chưa đọc
  List<ChatMessage> getUnreadMessages(String chatRoomId) {
    return _currentMessages
        .where((msg) => !msg.isRead && msg.senderId != _currentUserId)
        .toList();
  }

  // Lấy tin nhắn đã gửi nhưng chưa được giao
  List<ChatMessage> getUndeliveredMessages(String chatRoomId) {
    return _currentMessages
        .where((msg) => msg.status == MessageStatus.sent)
        .toList();
  }

  // Lấy tin nhắn đã giao nhưng chưa được xem
  List<ChatMessage> getDeliveredButNotSeenMessages(String chatRoomId) {
    return _currentMessages
        .where((msg) => msg.status == MessageStatus.delivered)
        .toList();
  }

  // Load chat rooms for current user
  Future<void> loadChatRooms(String userId, {bool forceReload = false}) async {
    _currentUserId = userId;
    final now = DateTime.now();
    final cacheValid =
        _lastChatRoomsLoad != null &&
        _lastUserId == userId &&
        now.difference(_lastChatRoomsLoad!) < _chatRoomsCacheExpiry;

    if (!forceReload && cacheValid && _chatRooms.isNotEmpty) {
      print('📋 Using cached chat rooms data');
      return;
    }

    print('🔄 Loading chat rooms from server (forceReload: $forceReload)');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final chatList = data['data'] as List;
          _chatRooms = chatList.map((room) => ChatRoom.fromJson(room)).toList();
          _lastChatRoomsLoad = DateTime.now();
          _lastUserId = userId;
          print('✅ Chat rooms loaded successfully: ${_chatRooms.length} rooms');
        }
      }
    } catch (e) {
      print('❌ Error loading chat rooms: $e');
      _loadDemoChatRooms(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load messages for a specific chat room with pagination
  Future<void> loadMessages(
    String chatRoomId, {
    int limit = 30,
    int offset = 0,
  }) async {
    _currentChatRoomId = chatRoomId;
    _isLoading = true;
    notifyListeners();

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chats/$chatRoomId/messages?limit=$limit&offset=$offset',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final messageList = data['data'] as List;
          if (offset == 0) {
            _currentMessages = messageList
                .map((message) => ChatMessage.fromJson(message))
                .toList();
          } else {
            _currentMessages.addAll(
              messageList
                  .map((message) => ChatMessage.fromJson(message))
                  .toList(),
            );
          }
          _lastMessageCount = _currentMessages.length;

          // Only reload chat list occasionally, not every time
          if (_currentMessages.length > 1 && offset == 0) {
            _reloadChatListAfterRead();
          }
        } else {
          print('❌ API returned success=false: ${data['message']}');
        }
      } else {
        if (response.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      _loadDemoMessages(chatRoomId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Send a message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
    String? tripId,
  }) async {
    try {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        timestamp: DateTime.now(),
        tripId: tripId,
      );

      print('📝 Sending message to server: ${newMessage.message}');

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chats/$chatRoomId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': message, 'messageType': 'text'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return true;
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    }
    return true;
  }

  // Create or get chat room
  Future<String?> createOrGetChatRoom({
    required String currentUserId,
    required String currentUserName,
    required String currentUserRole,
    required String targetUserId,
    required String targetUserName,
    required String targetUserRole,
    String? tripId,
    String? tripRoute,
  }) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chats/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'participantId': targetUserId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final chatId = data['data']['id'] ?? data['data']['_id'];

          // Reload chat list to show new chat
          await loadChatRooms(currentUserId);

          return chatId;
        }
      }
    } catch (e) {
      print('❌ Error creating chat room: $e');
    }
    return null;
  }

  // Start polling for new messages - optimized with longer intervals
  void startPolling(String chatRoomId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentChatRoomId == chatRoomId) {
        _loadMessagesQuietly(chatRoomId);
      }
    });
  }

  // Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
  }

  // Start polling chat list - much longer intervals
  void startChatListPolling(String userId) {
    _chatListPollTimer?.cancel();
    _chatListPollTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _loadChatRoomsQuietly(userId);
    });
  }

  // Stop chat list polling
  void stopChatListPolling() {
    _chatListPollTimer?.cancel();
    _chatListPollTimer = null;
  }

  // Load messages without loading indicator and excessive logging
  Future<void> _loadMessagesQuietly(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chats/$chatRoomId/messages?limit=30&offset=0',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final messageList = data['data'] as List;
          final newMessages = messageList
              .map((message) => ChatMessage.fromJson(message))
              .toList();

          // Only update and notify if there are actually new messages
          if (newMessages.length != _currentMessages.length ||
              (newMessages.isNotEmpty &&
                  _currentMessages.isNotEmpty &&
                  newMessages.first.id != _currentMessages.first.id)) {
            _currentMessages = newMessages;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Silent fail for polling to avoid spam
    }
  }

  // Load chat rooms quietly for polling
  Future<void> _loadChatRoomsQuietly(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final chatList = data['data'] as List;
          final newChatRooms = chatList
              .map((room) => ChatRoom.fromJson(room))
              .toList();

          // Only update if there are changes
          if (newChatRooms.length != _chatRooms.length) {
            _chatRooms = newChatRooms;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  // Demo data for offline mode
  void _loadDemoChatRooms(String userId) {
    _chatRooms = [];
  }

  void _loadDemoMessages(String chatRoomId) {
    if (chatRoomId == 'admin_support') {
      _currentMessages = [
        ChatMessage(
          id: '1',
          chatRoomId: chatRoomId,
          senderId: 'admin',
          senderName: 'Admin Hà Phương',
          senderRole: 'admin',
          message: 'Chào bạn! Tôi có thể giúp gì cho bạn?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    }
  }

  // Reload chat list để update unreadCount sau khi đọc tin nhắn
  void _reloadChatListAfterRead() async {
    try {
      // Get current user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isNotEmpty) {
        print('🔄 Reloading chat list to update unread counts...');
        await loadChatRooms(userId);
      }
    } catch (e) {
      print('❌ Error reloading chat list: $e');
    }
  }

  // FIXED: Recall (delete) a message by its ID
  Future<bool> recallMessage(String chatRoomId, String messageId) async {
    try {
      print(
        '🔎 [DEBUG] Thu hồi messageId: $messageId trong chatRoomId: $chatRoomId',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/chats/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Message deleted successfully from server');

        // Step 1: Remove message from current messages
        _currentMessages.removeWhere((msg) => msg.id == messageId);
        print('✅ Message removed from local list');

        // Step 2: Clear cache to force fresh data
        _lastChatRoomsLoad = null;
        _lastUserId = null;
        print('✅ Cache cleared');

        // Step 3: Reload messages for current chat
        print('🔄 Reloading messages...');
        await loadMessages(chatRoomId, limit: 30, offset: 0);

        // Step 4: Force reload chat rooms to get updated lastMessage
        if (userId.isNotEmpty) {
          print('🔄 Force reloading chat rooms...');
          await loadChatRooms(userId, forceReload: true);
        }

        // Step 5: Notify listeners
        notifyListeners();

        print(
          '✅ Message recall completed successfully - chat list should now show correct last message',
        );
        return true;
      } else {
        print(
          '❌ Error recalling message: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error recalling message: $e');
    }
    return false;
  }

  // Fetch user activity status from API backend
  Future<void> fetchUserActivityStatus(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/$userId/activity-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          updateOnlineStatus(userId, data['isOnline'] ?? false);
          if (data['lastActiveAt'] != null) {
            updateLastActiveTime(userId, DateTime.parse(data['lastActiveAt']));
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching user activity status: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatListPollTimer?.cancel();
    super.dispose();
  }
}

// Định nghĩa class UserActivityStatus
class UserActivityStatus {
  final bool isOnline;
  final int minutesOffline;
  UserActivityStatus({required this.isOnline, required this.minutesOffline});
}
