import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../constants/api_constants.dart';

class ChatProvider with ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;
  String _currentChatRoomId = '';
  Timer? _pollTimer;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String get currentChatRoomId => _currentChatRoomId;

  // Load chat rooms for current user
  Future<void> loadChatRooms(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/rooms/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _chatRooms = (data['data'] as List)
              .map((room) => ChatRoom.fromJson(room))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error loading chat rooms: $e');
      // Demo data for offline mode
      _loadDemoChatRooms(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load messages for a specific chat room
  Future<void> loadMessages(String chatRoomId) async {
    _currentChatRoomId = chatRoomId;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/messages/$chatRoomId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _currentMessages = (data['data'] as List)
              .map((message) => ChatMessage.fromJson(message))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      // Demo data for offline mode
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

      // Add message locally first for immediate UI update
      _currentMessages.add(newMessage);
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newMessage.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Update with server response if needed
          return true;
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    }

    return true; // Return true for demo mode
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/room'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'participants': [currentUserId, targetUserId],
          'participantNames': [currentUserName, targetUserName],
          'participantRoles': [currentUserRole, targetUserRole],
          'tripId': tripId,
          'tripRoute': tripRoute,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data']['_id'];
        }
      }
    } catch (e) {
      print('❌ Error creating chat room: $e');
    }

    // Return demo room ID for offline mode
    return 'demo_${currentUserId}_${targetUserId}';
  }

  // Start polling for new messages
  void startPolling(String chatRoomId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentChatRoomId == chatRoomId) {
        loadMessages(chatRoomId);
      }
    });
  }

  // Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
  }

  // Demo data for offline mode
  void _loadDemoChatRooms(String userId) {
    _chatRooms = [
      ChatRoom(
        id: 'admin_support',
        name: 'Hỗ trợ Admin',
        participants: [userId, 'admin'],
        participantNames: ['Bạn', 'Admin Hà Phương'],
        participantRoles: ['user', 'admin'],
        lastMessage: 'msg_1', // Just store message ID as string
        unreadCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
