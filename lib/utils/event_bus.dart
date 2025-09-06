import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void emit(String event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

// Event constants
class Events {
  static const String messageDeleted = 'message_deleted';
  static const String chatListNeedsRefresh = 'chat_list_needs_refresh';
  static const String notificationsUpdated = 'notifications_updated';
  static const String adminBroadcastReceived = 'admin_broadcast_received';
  static const String settingsChanged = 'settings_changed';
  static const String walletUpdated = 'wallet_updated';
}
