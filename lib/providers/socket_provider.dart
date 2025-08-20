import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_status.dart';

class SocketProvider with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  bool get isConnected => _isConnected;

  void connect(String url, String token, String userId) {
    _currentUserId = userId;
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          // Allow both websocket and polling for better compatibility
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setPath('/socket.io')
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket?.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      // Auto join on connect to ensure server maps this socket to user
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        _socket?.emit('join', _currentUserId);
      }
      // Broadcast online status when connected
      emit('user_status', {
        'userId': _currentUserId,
        'isOnline': true,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    });

    _socket?.onConnectError((err) {
      // Debug connection issues
      debugPrint('❌ Socket connect error: $err');
    });

    _socket?.onError((err) {
      debugPrint('❌ Socket error: $err');
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      // Broadcast offline with last active time
      emit('user_status', {
        'userId': _currentUserId,
        'isOnline': false,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    });

    // Re-emit join after reconnection to rebuild mapping on server
    _socket?.onReconnect((_) {
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        _socket?.emit('join', _currentUserId);
      }
    });

    // Restore mapping after app resumes from background by pinging join
    _socket?.on('connect_timeout', (_) async {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('userId') ?? _currentUserId;
      if (cachedUserId != null && cachedUserId.isNotEmpty) {
        _socket?.emit('join', cachedUserId);
      }
    });

    // Các sự kiện mới cho trạng thái tin nhắn
    _socket?.on('message_delivered', (data) {
      // data: { chatId, messageId, userId }
      // Forward to providers via listeners in UI if needed
    });

    _socket?.on('message_seen', (data) {
      // data: { chatId, messageId, userId }
    });

    _socket?.on('typing_start', (data) {
      // Xử lý khi người dùng bắt đầu soạn tin
    });

    _socket?.on('typing_stop', (data) {
      // Xử lý khi người dùng dừng soạn tin
    });

    _socket?.on('user_status_update', (data) {
      // Xử lý khi trạng thái người dùng thay đổi
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // Các phương thức mới cho trạng thái tin nhắn
  void sendMessageStatus(
    String chatRoomId,
    String messageId,
    MessageStatus status,
  ) {
    emit('message_status_update', {
      'chatRoomId': chatRoomId,
      'messageId': messageId,
      'status': status.value,
    });
  }

  void sendTypingStatus(String chatRoomId, bool isTyping) {
    emit('typing_status', {'chatRoomId': chatRoomId, 'isTyping': isTyping});
  }

  void sendUserStatus(String userId, bool isOnline, DateTime? lastActiveAt) {
    emit('user_status', {
      'userId': userId,
      'isOnline': isOnline,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    });
  }
}
