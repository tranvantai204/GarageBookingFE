import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/api_constants.dart';
import 'navigation_service.dart';
import 'dart:convert';
import '../utils/event_bus.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/socket_provider.dart';

// MUST be top-level for Android background isolate
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  try {
    // Avoid SharedPreferences and heavy work in background isolate to prevent ANR
    final type = (message.data['type'] ?? '') as String;
    if (type == 'incoming_call' ||
        type == 'call_cancelled' ||
        type == 'call_ended') {
      await PushNotificationService._showIncomingCallIfNeeded(
        message,
        minimalMode: true,
      );
    }
  } catch (_) {}
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  static bool _incomingOverlayVisible = false;
  static Timer? _ringHapticTimer;
  static Timer? _incomingOverlayAutoHideTimer;
  static String? _lastIncomingCallKey;
  static DateTime? _lastIncomingShownAt;

  static Future<void> initialize() async {
    // Detect problematic ROMs/SDKs which may ANR on overlay + full-screen
    final prefs = await SharedPreferences.getInstance();
    bool forceSystemPopupOnly = prefs.getBool('callSystemPopupOnly') ?? true;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final brand = (android.brand).toLowerCase();
      final manufacturer = (android.manufacturer).toLowerCase();
      final sdkInt = android.version.sdkInt;
      // Heuristics: MIUI/Xiaomi or SDK < 30 may be sensitive
      if (!forceSystemPopupOnly &&
          (brand.contains('xiaomi') ||
              manufacturer.contains('xiaomi') ||
              sdkInt < 30)) {
        await prefs.setBool('callSystemPopupOnly', true);
        forceSystemPopupOnly = true;
      }
    } catch (_) {}
    await Firebase.initializeApp();

    // Local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _fln.initialize(
      init,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Init timezone for scheduled notifications
    try {
      tz.initializeTimeZones();
      final String localTz = tz.local.name; // Ensure initialized
      debugPrint('🕒 Timezone initialized: ' + localTz);
    } catch (_) {}

    // Ensure Android notification channels
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          'general_notifications',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.high,
        );
    const AndroidNotificationChannel incomingCallChannel =
        AndroidNotificationChannel(
          'incoming_call',
          'Incoming Calls',
          description: 'Full-screen incoming call alerts',
          importance: Importance.max,
        );
    const AndroidNotificationChannel incomingCallSafeChannel =
        AndroidNotificationChannel(
          'incoming_call_safe',
          'Incoming Calls (Safe)',
          description:
              'Heads-up only, no full-screen, safer for MIUI/older SDKs',
          importance: Importance.high,
        );
    final androidPlatform = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.createNotificationChannel(generalChannel);
    await androidPlatform?.createNotificationChannel(incomingCallChannel);
    await androidPlatform?.createNotificationChannel(incomingCallSafeChannel);

    // Permissions (Android 13+)
    await FirebaseMessaging.instance.requestPermission();
    // Request exact alarms permission on Android 13+ for schedule
    try {
      final androidImpl = _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestExactAlarmsPermission();
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}

    // Foreground presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Background handler must be a top-level function
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // On message (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final type = (message.data['type'] ?? '') as String;
      if (type == 'incoming_call') {
        // Defer to next frame to avoid UI jank
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIncomingCallIfNeeded(message);
        });
      } else if (type == 'call_cancelled' || type == 'call_ended') {
        // Dismiss incoming call UI if any (overlay + system notif)
        await dismissIncomingCallNotification();
        _stopHapticRinging();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _dismissIncomingOverlay();
        });
      } else if (type == 'chat_message') {
        final chatId = (message.data['chatId'] ?? '') as String;
        bool navigated = false;
        try {
          final ctx = NavigationService.navigatorKey.currentContext;
          if (ctx != null && chatId.isNotEmpty) {
            final chatProvider = Provider.of<ChatProvider>(ctx, listen: false);
            final prefs = await SharedPreferences.getInstance();
            final allow = prefs.getBool('autoOpenChatOnForeground') ?? true;
            if (allow && chatProvider.currentChatRoomId != chatId) {
              await _navigateToChat(chatId);
              navigated = true;
            }
            // Always refresh chat list to show latest snippet/unread
            final userId = prefs.getString('userId') ?? '';
            if (userId.isNotEmpty) {
              await chatProvider.loadChatRooms(userId, forceReload: true);
            }
          }
        } catch (_) {}
        if (!navigated) {
          await _showLocalNotification(message);
        }
      } else {
        await _showLocalNotification(message);
      }
      // Do not block UI thread on foreground; store inbox asynchronously
      _storeToInbox(message);
      // Notify UI update
      EventBus().emit(Events.notificationsUpdated);
    });

    // When app opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      _storeToInbox(message);
      _handleMessageNavigation(message);
    });

    // When app launched from terminated state via notification tap
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      _storeToInbox(initialMsg);
      _handleMessageNavigation(initialMsg);
      EventBus().emit(Events.notificationsUpdated);
    }

    // Clean up stale incoming-call notification on cold start
    await dismissIncomingCallNotification();

    // Save FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      debugPrint('🔔 FCM token saved: ${token.substring(0, 10)}...');
      // Send token to backend for user/driver notifications
      try {
        final authToken = prefs.getString('token');
        if (authToken != null) {
          await _sendFcmTokenToServer(token, authToken);
        }
        // Subscribe to user topic to receive pushes without requiring re-login
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          final topic = 'user_' + userId;
          await FirebaseMessaging.instance.subscribeToTopic(topic);
          debugPrint('📌 Subscribed to topic: ' + topic);
        }
      } catch (_) {}
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', newToken);
      final authToken = prefs.getString('token');
      if (authToken != null) {
        await _sendFcmTokenToServer(newToken, authToken);
      }
      // Ensure topic subscription remains
      final userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        final topic = 'user_' + userId;
        try {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        } catch (_) {}
      }
    });
  }

  // Call this after user logs in to ensure server has the latest token
  static Future<void> syncFcmTokenWithServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcmToken');
      final authToken = prefs.getString('token');
      if (token != null && authToken != null) {
        await _sendFcmTokenToServer(token, authToken);
      }
    } catch (_) {}
  }

  // Removed: background handler is now top-level (see above)

  static Future<void> _showIncomingCallIfNeeded(
    RemoteMessage message, {
    bool minimalMode = false,
  }) async {
    final data = message.data;
    if (data['type'] == 'incoming_call') {
      // Debounce duplicate notifications within a short window
      final callKey = (data['callId'] ?? data['channelName'] ?? '') as String;
      final now = DateTime.now();
      // Throttle even when key is missing
      if (_lastIncomingShownAt != null &&
          now.difference(_lastIncomingShownAt!).inSeconds < 2) {
        return;
      }
      if (callKey.isNotEmpty &&
          _lastIncomingCallKey == callKey &&
          _lastIncomingShownAt != null &&
          now.difference(_lastIncomingShownAt!).inSeconds < 5) {
        return;
      }
      _lastIncomingCallKey = callKey;
      _lastIncomingShownAt = now;
      // Only show overlay if we have a foreground context and app is resumed
      BuildContext? ctx;
      bool canShowOverlay = false;
      bool systemPopupOnly = true;
      if (!minimalMode) {
        ctx = NavigationService.navigatorKey.currentContext;
        final state = WidgetsBinding.instance.lifecycleState;
        canShowOverlay = ctx != null && state == AppLifecycleState.resumed;
        final prefs = await SharedPreferences.getInstance();
        systemPopupOnly = prefs.getBool('callSystemPopupOnly') ?? true;
      }
      const fullScreenAndroidDetails = AndroidNotificationDetails(
        'incoming_call',
        'Incoming Calls',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        ticker: 'incoming_call',
        category: AndroidNotificationCategory.call,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );
      const headsUpAndroidDetails = AndroidNotificationDetails(
        'incoming_call_safe',
        'Incoming Calls (Safe)',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: false,
        ticker: 'incoming_call',
        // Avoid category call to reduce OEM escalations
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );
      final payload = jsonEncode({
        'type': 'incoming_call',
        'channelName': data['channelName'],
        'callerName': data['callerName'] ?? 'Người gọi',
        'callerRole': data['callerRole'] ?? 'user',
      });
      // Choose notification style
      // - Normal devices: overlay when foreground; full-screen notif when background
      // - Problematic devices (systemPopupOnly): heads-up when foreground; full-screen when background
      if (!canShowOverlay) {
        // If device is problematic, avoid full-screen even in background
        final notifDetails = systemPopupOnly
            ? const NotificationDetails(android: headsUpAndroidDetails)
            : const NotificationDetails(android: fullScreenAndroidDetails);
        await dismissIncomingCallNotification();
        await _fln.show(
          1001,
          'Cuộc gọi đến',
          data['callerName'] ?? 'Ai đó đang gọi',
          notifDetails,
          payload: payload,
        );
      } else if (systemPopupOnly) {
        await dismissIncomingCallNotification();
        await _fln.show(
          1001,
          'Cuộc gọi đến',
          data['callerName'] ?? 'Ai đó đang gọi',
          const NotificationDetails(android: headsUpAndroidDetails),
          payload: payload,
        );
      }
      if (canShowOverlay && !systemPopupOnly) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIncomingOverlay(
            callerName: data['callerName'] ?? 'Người gọi',
            callerRole: data['callerRole'] ?? 'user',
            channelName: data['channelName'] ?? '',
            callerUserId: data['callerUserId'] ?? '',
            callerAvatarUrl: data['callerAvatarUrl'] ?? '',
          );
          _startHapticRinging();
        });
      }
    }
  }

  static void _showIncomingOverlay({
    required String callerName,
    required String callerRole,
    required String channelName,
    required String callerUserId,
    required String callerAvatarUrl,
  }) {
    try {
      if (_incomingOverlayVisible) return;
      final ctx = NavigationService.navigatorKey.currentContext;
      if (ctx == null) return;
      _incomingOverlayVisible = true;
      // Auto-hide after a safe timeout to avoid stuck overlays (e.g., ANR)
      _incomingOverlayAutoHideTimer?.cancel();
      _incomingOverlayAutoHideTimer = Timer(const Duration(seconds: 25), () {
        _dismissIncomingOverlay();
      });
      showGeneralDialog(
        context: ctx,
        barrierDismissible: false,
        barrierLabel: 'incoming_call',
        transitionBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        pageBuilder: (context, anim1, anim2) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Material(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IncomingCallerAvatar(
                        avatarUrl: callerAvatarUrl,
                        role: callerRole,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cuộc gọi đến',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment:
                            defaultTargetPlatform == TargetPlatform.iOS
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final sp = Provider.of<SocketProvider>(
                                  context,
                                  listen: false,
                                );
                                sp.emit('decline_call', {
                                  'callerUserId': callerUserId,
                                  'channelName': channelName,
                                });
                              } catch (_) {}
                              _stopHapticRinging();
                              _dismissIncomingOverlay();
                            },
                            icon: const Icon(Icons.call_end),
                            label: const Text('Từ chối'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              _stopHapticRinging();
                              _dismissIncomingOverlay();
                              _navigateToIncomingCall(
                                channelName: channelName,
                                callerName: callerName,
                                callerRole: callerRole,
                              );
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Nghe máy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        _incomingOverlayVisible = false;
        _incomingOverlayAutoHideTimer?.cancel();
        _incomingOverlayAutoHideTimer = null;
      });
    } catch (_) {
      _incomingOverlayVisible = false;
    }
  }

  static void _dismissIncomingOverlay() {
    try {
      if (!_incomingOverlayVisible) return;
      final nav = NavigationService.navigatorKey.currentState;
      if (nav != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (nav.canPop()) nav.pop();
          } catch (_) {}
        });
      }
    } catch (_) {
    } finally {
      _incomingOverlayVisible = false;
      _stopHapticRinging();
      _incomingOverlayAutoHideTimer?.cancel();
      _incomingOverlayAutoHideTimer = null;
    }
  }

  static void _startHapticRinging() {
    try {
      _ringHapticTimer?.cancel();
      int ticks = 0;
      _ringHapticTimer = Timer.periodic(const Duration(milliseconds: 1200), (
        Timer _,
      ) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
        ticks++;
        if (ticks >= 8) {
          _stopHapticRinging();
        }
      });
    } catch (_) {}
  }

  static void _stopHapticRinging() {
    try {
      _ringHapticTimer?.cancel();
      _ringHapticTimer = null;
    } catch (_) {}
  }

  static Future<void> _storeToInbox(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = prefs.getStringList('inbox') ?? [];
      final title =
          message.notification?.title ?? message.data['title'] ?? 'Thông báo';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final time = DateTime.now().toIso8601String();
      items.insert(0, '$title|$body|$time');
      // Giới hạn 200 thông báo gần nhất
      if (items.length > 200) items.removeRange(200, items.length);
      await prefs.setStringList('inbox', items);
    } catch (_) {}
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'Thông báo';
    String body = message.notification?.body ?? message.data['body'] ?? '';
    // When body is too short/empty, derive from data for better visibility
    if (body.isEmpty) {
      final type = (message.data['type'] ?? '') as String;
      if (type == 'chat_message') {
        body = 'Bạn có tin nhắn mới';
      } else if (type == 'admin_broadcast') {
        body = 'Thông báo từ Admin';
      }
    }
    const androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    String payload = 'general';
    final type = (message.data['type'] ?? '') as String;
    if (type == 'admin_broadcast') {
      payload = jsonEncode({
        'type': 'admin_broadcast',
        'adminNotifId': message.data['adminNotifId'] ?? '',
      });
    } else if (type == 'chat_message') {
      payload = jsonEncode({
        'type': 'chat_message',
        'chatId': message.data['chatId'] ?? '',
        'senderId': message.data['senderId'] ?? '',
      });
    }
    await _fln.show(0, title, body, details, payload: payload);
  }

  // Schedule a local notification 30 minutes before departure
  static Future<void> scheduleUpcomingTripReminder({
    required String bookingId,
    required String diemDi,
    required String diemDen,
    required DateTime departureTime,
  }) async {
    try {
      final now = DateTime.now();
      final scheduled = departureTime.subtract(const Duration(minutes: 30));
      if (scheduled.isBefore(now.add(const Duration(seconds: 5)))) {
        // Too soon/past; skip scheduling
        return;
      }
      const androidDetails = AndroidNotificationDetails(
        'general_notifications',
        'General Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      final id = 200000 + (bookingId.hashCode & 0x7fffffff) % 100000;
      final body =
          'Sắp khởi hành: ' + diemDi + ' → ' + diemDen + ' trong 30 phút';
      final payload =
          '{"type":"upcoming_trip","bookingId":"' + bookingId + '"}';
      final tzTime = tz.TZDateTime.from(scheduled, tz.local);
      await _fln.zonedSchedule(
        id,
        'Nhắc nhở chuyến đi',
        body,
        tzTime,
        details,
        payload: payload,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Update ticker message if within 30 minutes window
      if (departureTime.isBefore(now.add(const Duration(minutes: 30)))) {
        final prefs = await SharedPreferences.getInstance();
        final hh = departureTime.hour.toString().padLeft(2, '0');
        final mm = departureTime.minute.toString().padLeft(2, '0');
        final ticker =
            'Sắp khởi hành: ' +
            diemDi +
            ' → ' +
            diemDen +
            ' lúc ' +
            hh +
            ':' +
            mm;
        await prefs.setString('upcomingTripTicker', ticker);
        EventBus().emit(Events.notificationsUpdated);
      }
    } catch (_) {}
  }

  static void _onNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final data = jsonDecode(payload);
        if (data is Map && data['type'] == 'incoming_call') {
          _navigateToIncomingCall(
            channelName: data['channelName'] ?? '',
            callerName: data['callerName'] ?? 'Người gọi',
            callerRole: data['callerRole'] ?? 'user',
          );
          return;
        }
        if (data is Map && data['type'] == 'admin_broadcast') {
          // Stay in app and notify UI
          EventBus().emit(Events.adminBroadcastReceived);
          final navigator = NavigationService.navigatorKey.currentState;
          navigator?.pushNamed('/trips');
          return;
        }
        if (data is Map && data['type'] == 'chat_message') {
          final chatId = (data['chatId'] ?? '') as String;
          if (chatId.isNotEmpty) {
            _navigateToChat(chatId);
            return;
          }
        }
      }
      final navigator = NavigationService.navigatorKey.currentState;
      navigator?.pushNamed('/trips');
    } catch (_) {
      final navigator = NavigationService.navigatorKey.currentState;
      navigator?.pushNamed('/trips');
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    try {
      final data = message.data;
      if (data['type'] == 'incoming_call') {
        _navigateToIncomingCall(
          channelName: data['channelName'] ?? '',
          callerName: data['callerName'] ?? 'Người gọi',
          callerRole: data['callerRole'] ?? 'user',
        );
      } else if (data['type'] == 'chat_message') {
        final chatId = (data['chatId'] ?? '') as String;
        if (chatId.isNotEmpty) {
          _navigateToChat(chatId);
        }
      }
    } catch (_) {}
  }

  static Future<void> _navigateToChat(String chatId) async {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;
    // Bring user to main screen first to ensure providers are ready
    navigator.pushNamedAndRemoveUntil('/trips', (route) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final ctx = NavigationService.navigatorKey.currentContext;
        if (ctx == null) return;
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? '';
        final chatProvider = Provider.of<ChatProvider>(ctx, listen: false);
        if (chatProvider.chatRooms.isEmpty && userId.isNotEmpty) {
          await chatProvider.loadChatRooms(userId, forceReload: true);
        }
        final room = chatProvider.chatRooms.firstWhere(
          (r) => r.id == chatId,
          orElse: () => chatProvider.chatRooms.isNotEmpty
              ? chatProvider.chatRooms.first
              : throw Exception('No chat rooms'),
        );
        await navigator.pushNamed(
          '/chat',
          arguments: {
            'chatRoomId': room.id,
            'chatRoomName': room.participant.name,
            'targetUserName': room.participant.name,
            'targetUserRole': room.participant.role,
            'targetUserId': room.participant.id,
          },
        );
      } catch (_) {}
    });
  }

  static void _navigateToIncomingCall({
    required String channelName,
    required String callerName,
    required String callerRole,
  }) async {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;
    await dismissIncomingCallNotification();
    // Bring user to main screen first to ensure providers are ready
    navigator.pushNamedAndRemoveUntil('/trips', (route) => false);
    // Delay a frame to ensure route is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await navigator.pushNamed(
          '/voice_call_entry',
          arguments: {
            'channelName': channelName,
            'callerName': callerName,
            'callerRole': callerRole,
          },
        );
      } catch (_) {}
    });
  }

  static Future<void> dismissIncomingCallNotification() async {
    try {
      await _fln.cancel(1001);
    } catch (_) {}
  }

  static Future<void> _sendFcmTokenToServer(
    String token,
    String authToken,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/fcm-token');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: '{"token":"$token"}',
      );
    } catch (_) {}
  }
}

class _IncomingCallerAvatar extends StatelessWidget {
  final String avatarUrl;
  final String role;
  const _IncomingCallerAvatar({required this.avatarUrl, required this.role});

  Color get _accentColor {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.orange;
      case 'driver':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.isNotEmpty;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.call, color: Colors.white, size: 40),
              )
            : const Icon(Icons.call, color: Colors.white, size: 40),
      ),
    );
  }
}
