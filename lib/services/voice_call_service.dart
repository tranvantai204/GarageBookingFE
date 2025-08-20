import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VoiceCallService {
  static const String appId = "aec4d4a14d994fb1904ce07a17cd4c2c"; // Agora App ID
  
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  
  // Stream controllers for UI updates
  final StreamController<bool> _joinedController = StreamController<bool>.broadcast();
  final StreamController<bool> _mutedController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakerController = StreamController<bool>.broadcast();
  final StreamController<int> _remoteUserController = StreamController<int>.broadcast();
  final StreamController<String> _callStatusController = StreamController<String>.broadcast();
  
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

  static final VoiceCallService _instance = VoiceCallService._internal();
  factory VoiceCallService() => _instance;
  VoiceCallService._internal();

  Future<void> initialize() async {
    if (_engine != null) return;
    
    try {
      // Request permissions
      await _requestPermissions();
      
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Set up event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('📞 Voice call joined successfully: ${connection.channelId}');
          _isJoined = true;
          _joinedController.add(true);
          _callStatusController.add('Đã kết nối');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('📞 Remote user joined: $remoteUid');
          _remoteUserController.add(remoteUid);
          _callStatusController.add('Đang gọi...');
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('📞 Remote user left: $remoteUid');
          _remoteUserController.add(0);
          _callStatusController.add('Cuộc gọi đã kết thúc');
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('📞 Left voice call channel');
          _isJoined = false;
          _joinedController.add(false);
          _callStatusController.add('Đã ngắt kết nối');
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Voice call error: $err - $msg');
          _callStatusController.add('Lỗi kết nối');
        },
      ));
      
      // Enable audio
      await _engine!.enableAudio();
      await _engine!.setDefaultAudioRouteToSpeakerphone(false);
      
      print('✅ Voice call service initialized');
    } catch (e) {
      print('❌ Error initializing voice call service: $e');
      throw e;
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  Future<void> joinCall(String channelName, {int? uid}) async {
    if (_engine == null) {
      await initialize();
    }
    
    try {
      _callStatusController.add('Đang kết nối...');
      
      // Generate token (in production, get from your server)
      String? token = await _generateToken(channelName, uid ?? 0);
      
      await _engine!.joinChannel(
        token: token ?? "", // Fix: Handle null token by providing empty string
        channelId: channelName,
        uid: uid ?? 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      
      print('📞 Joining voice call: $channelName');
    } catch (e) {
      print('❌ Error joining voice call: $e');
      _callStatusController.add('Không thể kết nối');
      throw e;
    }
  }

  Future<void> leaveCall() async {
    if (_engine == null || !_isJoined) return;
    
    try {
      await _engine!.leaveChannel();
      _callStatusController.add('Đã kết thúc cuộc gọi');
      print('📞 Left voice call');
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
      print('📞 Mute toggled: $_isMuted');
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
      print('📞 Speaker toggled: $_isSpeakerOn');
    } catch (e) {
      print('❌ Error toggling speaker: $e');
    }
  }

  Future<String?> _generateToken(String channelName, int uid) async {
    // In production, you should get token from your server
    // For development, you can use null (less secure)
    // Or use Agora's token generator: https://console.agora.io/
    
    // For now, return null for testing (works in development)
    return null;
    
    // In production, call your server:
    // try {
    //   final response = await http.post(
    //     Uri.parse('YOUR_SERVER/generate-token'),
    //     body: {
    //       'channelName': channelName,
    //       'uid': uid.toString(),
    //     },
    //   );
    //   if (response.statusCode == 200) {
    //     final data = json.decode(response.body);
    //     return data['token'];
    //   }
    // } catch (e) {
    //   print('Error generating token: $e');
    // }
    // return null;
  }

  void dispose() {
    _joinedController.close();
    _mutedController.close();
    _speakerController.close();
    _remoteUserController.close();
    _callStatusController.close();
    
    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;
  }

  // Helper method to create unique channel name for 1-1 call
  static String createChannelName(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return 'call_${users[0]}_${users[1]}';
  }
}