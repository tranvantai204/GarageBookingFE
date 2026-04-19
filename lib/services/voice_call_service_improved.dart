import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceCallServiceImproved {
  static const String appId =
      "aec4d4a14d994fb1904ce07a17cd4c2c"; // Agora App ID

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

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

  static final VoiceCallServiceImproved _instance =
      VoiceCallServiceImproved._internal();
  factory VoiceCallServiceImproved() => _instance;
  VoiceCallServiceImproved._internal();

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
          audioScenario: AudioScenarioType.audioScenarioMeeting,
        ),
      );

      // Set up event handlers with detailed logging
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print(
              '✅ Voice call joined successfully: ${connection.channelId} (elapsed: ${elapsed}ms)',
            );
            _isJoined = true;
            _joinedController.add(true);
            _callStatusController.add('Đã kết nối');
          },

          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('👤 Remote user joined: $remoteUid (elapsed: ${elapsed}ms)');
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

          onRemoteAudioStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteAudioState state,
                RemoteAudioStateReason reason,
                int elapsed,
              ) {
                print(
                  '🎧 Remote audio state: $state reason: $reason for $remoteUid',
                );
              },

          onNetworkQuality:
              (
                RtcConnection connection,
                int remoteUid,
                QualityType txQuality,
                QualityType rxQuality,
              ) {
                if (remoteUid == 0) {
                  // Local user
                  print(
                    '📶 Network quality - TX: \$txQuality, RX: \$rxQuality',
                  );
                }
              },
        ),
      );

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
      await _engine!.disableVideo();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Set audio profile for voice call
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioMeeting,
      );

      // Set default audio route
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);

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
    }

    _callStatusController.add(statusMessage);
  }

  Future<String?> fetchAgoraToken(String channelName, int uid) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://ha-phuong-mongodb-api.onrender.com/api/voice/rtcToken?channelName=$channelName&uid=$uid',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'] as String?;
      } else {
        print('❌ Lỗi lấy token từ backend: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi khi gọi API lấy token: $e');
      return null;
    }
  }

  Future<bool> joinCall(String channelName, {int? uid}) async {
    try {
      print('🚀 Attempting to join call: $channelName');
      final initialized = await initialize();
      if (!initialized) {
        print('❌ Failed to initialize Agora SDK');
        return false;
      }
      _callStatusController.add('Đang tham gia cuộc gọi...');
      if (channelName.isEmpty) {
        print('❌ Empty channel name');
        _callStatusController.add('Tên kênh không hợp lệ');
        return false;
      }
      final callUid = uid ?? await _computeStableUid();
      print('👤 Joining with UID: $callUid');
      final token = await fetchAgoraToken(channelName, callUid);
      if (token == null || token.isEmpty) {
        print('❌ Token không hợp lệ hoặc không lấy được');
        _callStatusController.add('Không lấy được token');
        return false;
      }
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: callUid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
          publishMicrophoneTrack: true,
          publishCameraTrack: false,
          // Ensure audio stream is published and subscribed
          enableAudioRecordingOrPlayout: true,
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

  Future<int> _computeStableUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getInt('agoraUid');
      if (existing != null && existing > 0) return existing;

      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        final rnd = DateTime.now().millisecondsSinceEpoch % 1000000000;
        await prefs.setInt('agoraUid', rnd);
        return rnd;
      }
      // Simple hash to 32-bit int range
      int hash = 0;
      for (int i = 0; i < userId.length; i++) {
        hash = (hash * 31 + userId.codeUnitAt(i)) & 0x7fffffff;
      }
      if (hash == 0) hash = 1;
      await prefs.setInt('agoraUid', hash);
      return hash;
    } catch (_) {
      final fallback = DateTime.now().millisecondsSinceEpoch % 1000000000;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('agoraUid', fallback);
      return fallback;
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

enum NetworkQualityType { unknown, excellent, good, poor, bad, veryBad, down }
// Đoạn mã NodeJS backend để sinh token động với thông tin bạn cung cấp:
// const appId = "aec4d4a14d994fb1904ce07a17cd4c2c";
// const appCertificate = "3d183599eb3a42938b2395362dcd2f7b";
// Sử dụng các giá trị này trong hàm tạo token của backend NodeJS.
// Ví dụ:
// const token = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, uid, role, privilegeExpireTime);

// Trong Flutter, gọi API backend để lấy token động:
// final response = await http.get(Uri.parse('http://your-server-ip:3000/rtcToken?channelName=yourChannel&uid=yourUid'));
// final token = response.body;
// Truyền token này vào hàm joinChannel:
// await _engine!.joinChannel(token, channelName, null, uid);
// Thay thế các giá trị channelName và uid phù hợp với logic ứng dụng của bạn.
// ... existing code ...
