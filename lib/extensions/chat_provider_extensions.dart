import '../providers/chat_provider.dart';

extension ChatProviderExtensions on ChatProvider {
  // Get typing status for a specific chat room
  bool isTypingInChat(String chatRoomId) {
    return typingStatus[chatRoomId] ?? false;
  }

  // Get online status for a specific user
  bool isUserOnline(String userId) {
    return onlineStatus[userId] ?? false;
  }

  // Get last active time for a specific user
  DateTime? getUserLastActiveTime(String userId) {
    return lastActiveTime[userId];
  }

  // Format last active time for display
  String getLastActiveText(String userId) {
    final lastActive = lastActiveTime[userId];
    final isOnline = onlineStatus[userId] ?? false;
    
    if (isOnline) {
      return 'Hoạt động';
    } else if (lastActive != null) {
      final difference = DateTime.now().difference(lastActive);
      if (difference.inMinutes < 1) {
        return 'Vừa hoạt động';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } else {
      return 'Không hoạt động';
    }
  }
}