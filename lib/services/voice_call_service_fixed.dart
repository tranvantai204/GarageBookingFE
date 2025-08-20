import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceCallServiceFixed {
  static const String appId =
      "aec4d4a14d994fb1904ce07a17cd4c2c"; // Agora App ID
  static const String baseUrl = "https://garagebooking.onrender.com/api/voice";

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _remoteUid = 0;

  // Stream controllers for UI updates
  final StreamController<bool> _joinedController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _mutedController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _speakerController =
      StreamController<bool>.broadcast();
  final StreamController<int> _remoteUserController =
      StreamController<int>.broadcast();
  final StreamController<String> _callStatusController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get joinedStream => _joinedController.stream;
  Stream<bool> get mutedStream => _mutedController.stream;
  Stream<bool> get speakerStream => _speakerController.stream;
  Stream<int> get remoteUserStream => _remoteUserController.stream;
  Stream<String> get callStatusStream => _callStatusController.stream;

  // Getters for current state
  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  static final VoiceCallServiceFixed _instance =
      VoiceCallServiceFixed._internal();
  factory VoiceCallServiceFixed() => _instance;
  VoiceCallServiceFixed._internal();

  Future<bool> initialize() async {
    if (_engine != null) return true;

    try {
      print('🔧 Initializing Agora SDK...');

      // Check permissions first
      final permissionStatus = await _requestPermissions();
      if (!permissionStatus) {
        print('❌ Microphone permission denied');
        _callStatusController.add('Cần cấp quyền microphone');
        return false;
      }

      // Validate App ID
      if (appId.isEmpty || appId == "YOUR_AGORA_APP_ID") {
        print('❌ Invalid Agora App ID');
        _callStatusController.add('Cấu hình App ID không hợp lệ');
        return false;
      }

      // Create RTC engine
      _engine = createAgoraRtcEngine();

      // Initialize with proper configuration
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          audioScenario: AudioScenarioType.audioScenarioGameStreaming,
        ),
      );

      // Set up event handlers
      _setupEventHandlers();

      // Configure audio settings
      await _configureAudio();

      print('✅ Voice call service initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing voice call service: $e');
      _callStatusController.add('Lỗi khởi tạo: ${e.toString()}');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final status = await Permission.microphone.request();
      print('🎤 Microphone permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> _configureAudio() async {
    try {
      // Enable audio
      await _engine!.enableAudio();

      // Set audio profile for voice call
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // Set default audio route
      await _engine!.setDefaultAudioRouteToSpeakerphone(false);

      // Enable audio volume indication
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      print('🔊 Audio configuration completed');
    } catch (e) {
      print('❌ Error configuring audio: $e');
    }
  }

  void _setupEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ Voice call joined successfully: ${connection.channelId}');
          _isJoined = true;
          _joinedController.add(true);
          _callStatusController.add('Đã kết nối');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👤 Remote user joined: $remoteUid');
          _remoteUid = remoteUid;
          _remoteUserController.add(remoteUid);
          _callStatusController.add('Người khác đã tham gia');
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print('👋 Remote user left: $remoteUid (reason: $reason)');
              _remoteUid = 0;
              _remoteUserController.add(0);
              _callStatusController.add('Người khác đã rời khỏi cuộc gọi');
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('🚪 Left voice call channel (duration: ${stats.duration}s)');
          _isJoined = false;
          _joinedController.add(false);
          _callStatusController.add('Đã rời khỏi cuộc gọi');
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora error: $err - $msg');
          _handleAgoraError(err, msg);
        },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              print('🔗 Connection state changed: $state (reason: $reason)');
              _handleConnectionStateChange(state, reason);
            },
      ),
    );
  }

  Future<String?> _getToken(String channelName, int uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'channelName': channelName, 'uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  Future<bool> joinCall(String channelName, {int? uid}) async {
    try {
      print('🚀 Attempting to join call: $channelName');

      // Initialize if not already done
      final initialized = await initialize();
      if (!initialized) {
        print('❌ Failed to initialize Agora SDK');
        return false;
      }

      _callStatusController.add('Đang lấy token xác thực...');

      // Get token from server
      final token = await _getToken(channelName, uid ?? 0);
      if (token == null || token.isEmpty) {
        print('❌ Failed to get valid token');
        _callStatusController.add('Không thể lấy token xác thực');
        return false;
      }

      print('✅ Got valid token for channel: $channelName');

      // Validate channel name
      if (channelName.isEmpty) {
        print('❌ Empty channel name');
        _callStatusController.add('Tên kênh không hợp lệ');
        return false;
      }

      _callStatusController.add('Đang kết nối...');

      // Join channel with valid token
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid ?? 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
        ),
      );

      print('📞 Join call request sent for channel: $channelName');
      return true;
    } catch (e) {
      print('❌ Error joining voice call: $e');
      _callStatusController.add('Không thể tham gia: ${e.toString()}');
      return false;
    }
  }

  Future<void> leaveCall() async {
    if (_engine == null) return;

    try {
      print('🚪 Leaving voice call...');
      await _engine!.leaveChannel();
      _callStatusController.add('Đang rời khỏi cuộc gọi...');
    } catch (e) {
      print('❌ Error leaving voice call: $e');
    }
  }

  Future<void> toggleMute() async {
    if (_engine == null) return;

    try {
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
      _mutedController.add(_isMuted);
      print('🎤 Mute toggled: $_isMuted');
    } catch (e) {
      print('❌ Error toggling mute: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    if (_engine == null) return;

    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine!.setDefaultAudioRouteToSpeakerphone(_isSpeakerOn);
      _speakerController.add(_isSpeakerOn);
      print('🔊 Speaker toggled: $_isSpeakerOn');
    } catch (e) {
      print('❌ Error toggling speaker: $e');
    }
  }

  void _handleAgoraError(ErrorCodeType err, String msg) {
    String errorMessage;

    switch (err) {
      case ErrorCodeType.errInvalidAppId:
        errorMessage = 'App ID không hợp lệ';
        break;
      case ErrorCodeType.errInvalidChannelName:
        errorMessage = 'Tên kênh không hợp lệ';
        break;
      case ErrorCodeType.errNoServerResources:
        errorMessage = 'Máy chủ quá tải';
        break;
      case ErrorCodeType.errTokenExpired:
        errorMessage = 'Token đã hết hạn';
        break;
      case ErrorCodeType.errInvalidToken:
        errorMessage = 'Token không hợp lệ';
        break;
      case ErrorCodeType.errConnectionInterrupted:
        errorMessage = 'Kết nối bị gián đoạn';
        break;
      case ErrorCodeType.errConnectionLost:
        errorMessage = 'Mất kết nối';
        break;
      default:
        errorMessage = 'Lỗi kết nối: $msg';
    }

    _callStatusController.add(errorMessage);
  }

  void _handleConnectionStateChange(
    ConnectionStateType state,
    ConnectionChangedReasonType reason,
  ) {
    String statusMessage;

    switch (state) {
      case ConnectionStateType.connectionStateDisconnected:
        statusMessage = 'Đã ngắt kết nối';
        break;
      case ConnectionStateType.connectionStateConnecting:
        statusMessage = 'Đang kết nối...';
        break;
      case ConnectionStateType.connectionStateConnected:
        statusMessage = 'Đã kết nối';
        break;
      case ConnectionStateType.connectionStateReconnecting:
        statusMessage = 'Đang kết nối lại...';
        break;
      case ConnectionStateType.connectionStateFailed:
        statusMessage = 'Kết nối thất bại';
        break;
      default:
        statusMessage = 'Trạng thái không xác định';
    }

    _callStatusController.add(statusMessage);
  }

  void dispose() {
    print('🧹 Disposing voice call service...');

    _joinedController.close();
    _mutedController.close();
    _speakerController.close();
    _remoteUserController.close();
    _callStatusController.close();

    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;

    _isJoined = false;
    _isMuted = false;
    _isSpeakerOn = false;
  }

  // Helper method to create unique channel name for 1-1 call
  static String createChannelName(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    final channelName = 'call_${users[0]}_${users[1]}';
    print('📺 Created channel name: $channelName');
    return channelName;
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      print('🧪 Testing Agora connection...');

      final initialized = await initialize();
      if (!initialized) {
        return false;
      }

      // Try to join a test channel
      final testChannel = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final joined = await joinCall(testChannel);

      if (joined) {
        // Leave immediately
        await Future.delayed(const Duration(seconds: 2));
        await leaveCall();
        print('✅ Connection test successful');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
