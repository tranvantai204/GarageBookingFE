import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/socket_provider.dart';
import '../services/voice_call_service_improved.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String targetUserName;
  final String targetUserRole;
  final bool isIncoming;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.targetUserName,
    required this.targetUserRole,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  final VoiceCallServiceImproved _voiceService = VoiceCallServiceImproved();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _avatarController;
  late Animation<double> _avatarAnimation;

  Timer? _callTimer;
  int _callDuration = 0;
  String _callStatus = 'Đang kết nối...';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _remoteUid = 0;
  bool _callStarted = false;
  Timer? _ringTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupVoiceCall();
    _listenToCallEvents();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
    );
    _avatarController.forward();
  }

  void _setupVoiceCall() async {
    try {
      await _voiceService.initialize();
      // Join the channel for both caller and callee
      await _voiceService.joinCall(widget.channelName);
      _startRingTimeout();
    } catch (e) {
      print('❌ Error setting up voice call: $e');
      _showErrorAndExit('Không thể kết nối cuộc gọi');
    }
  }

  void _listenToCallEvents() {
    _voiceService.joinedStream.listen((joined) {
      // No timer here; timer starts only when remote user joins
      setState(() {});
    });

    _voiceService.mutedStream.listen((muted) {
      setState(() => _isMuted = muted);
    });

    _voiceService.speakerStream.listen((speaker) {
      setState(() => _isSpeakerOn = speaker);
    });

    _voiceService.remoteUserStream.listen((uid) {
      setState(() {
        _remoteUid = uid;
        if (uid > 0) {
          _callStatus = 'Đang trò chuyện';
          if (!_callStarted) {
            _callStarted = true;
            _startCallTimer();
            _ringTimeoutTimer?.cancel();
          }
        } else {
          if (_callStarted) {
            _stopCallTimer();
          }
        }
      });
    });

    _voiceService.callStatusStream.listen((status) {
      setState(() => _callStatus = status);
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startRingTimeout() {
    if (widget.isIncoming) return;
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_callStarted && mounted) {
        _voiceService.leaveCall();
        Navigator.pop(context, {'status': 'missed'});
      }
    });
  }

  void _showErrorAndExit(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi cuộc gọi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _avatarController.dispose();
    _stopCallTimer();
    _ringTimeoutTimer?.cancel();
    _voiceService.leaveCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCallContent()),
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: _endCall,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Spacer(),
          Text(
            _formatCallDuration(_callDuration),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar with pulse animation
        ScaleTransition(
          scale: _avatarAnimation,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _remoteUid > 0 ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getRoleColor(widget.targetUserRole).withOpacity(0.8),
                        _getRoleColor(widget.targetUserRole),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getRoleColor(
                          widget.targetUserRole,
                        ).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getRoleIcon(widget.targetUserRole),
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),

        // User name
        Text(
          widget.targetUserName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(widget.targetUserRole).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleText(widget.targetUserRole),
            style: TextStyle(
              color: _getRoleColor(widget.targetUserRole),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Call status
        Text(
          _callStatus,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),

        // Connection indicator
        if (_remoteUid > 0)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Đã kết nối',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white24,
            onPressed: _voiceService.toggleMute,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            size: 70,
            iconSize: 35,
            onPressed: _endCall,
          ),

          // Speaker button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            color: _isSpeakerOn ? Colors.blue : Colors.white24,
            onPressed: _voiceService.toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
    double iconSize = 25,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  void _endCall() async {
    await _voiceService.leaveCall();
    // Notify peer to auto-exit
    try {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString('userId') ?? '';
      final parts = widget.channelName.split('_');
      String peerId = '';
      if (parts.length >= 3) {
        final a = parts[1];
        final b = parts[2];
        peerId = (a == myId) ? b : a;
      }
      if (peerId.isNotEmpty) {
        final socketProvider = Provider.of<SocketProvider>(
          context,
          listen: false,
        );
        socketProvider.emit('end_call', {
          'peerUserId': peerId,
          'channelName': widget.channelName,
        });
      }
    } catch (_) {}
    // Show in-app banner about call ended
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cuộc gọi đã kết thúc')));
    }
    if (mounted) {
      if (_callStarted) {
        Navigator.pop(context, {'status': 'ended', 'duration': _callDuration});
      } else {
        Navigator.pop(context, {'status': 'cancelled'});
      }
    }
  }

  String _formatCallDuration(int seconds) {
    if (seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
        return 'QUẢN TRỊ VIÊN';
      case 'driver':
      case 'tai_xe':
        return 'TÀI XẾ';
      default:
        return 'KHÁCH HÀNG';
    }
  }
}
