import 'package:flutter/material.dart';
import '../services/voice_call_service_improved.dart';

class VoiceCallTestScreen extends StatefulWidget {
  const VoiceCallTestScreen({super.key});

  @override
  State<VoiceCallTestScreen> createState() => _VoiceCallTestScreenState();
}

class _VoiceCallTestScreenState extends State<VoiceCallTestScreen> {
  final VoiceCallServiceImproved _voiceService = VoiceCallServiceImproved();
  final TextEditingController _channelController = TextEditingController();

  String _status = 'Chưa kết nối';
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _remoteUid = 0;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _channelController.text = 'test_channel_123';
  }

  void _setupListeners() {
    _voiceService.callStatusStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });

    _voiceService.joinedStream.listen((joined) {
      if (mounted) {
        setState(() => _isJoined = joined);
      }
    });

    _voiceService.mutedStream.listen((muted) {
      if (mounted) {
        setState(() => _isMuted = muted);
      }
    });

    _voiceService.speakerStream.listen((speaker) {
      if (mounted) {
        setState(() => _isSpeakerOn = speaker);
      }
    });

    _voiceService.remoteUserStream.listen((uid) {
      if (mounted) {
        setState(() => _remoteUid = uid);
      }
    });
  }

  @override
  void dispose() {
    _channelController.dispose();
    // Properly dispose of all listeners to prevent memory leaks
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Voice Call'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(_getStatusIcon(), size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_remoteUid > 0)
                      Text(
                        'Remote User: $_remoteUid',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Channel Input
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'Enter channel name to join',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tv),
              ),
            ),

            const SizedBox(height: 20),

            // Test Connection Button
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: Text(_isTesting ? 'Đang test...' : 'Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Join/Leave Button
            ElevatedButton.icon(
              onPressed: _isJoined ? _leaveCall : _joinCall,
              icon: Icon(_isJoined ? Icons.call_end : Icons.call),
              label: Text(_isJoined ? 'Leave Call' : 'Join Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isJoined ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Call Controls
            if (_isJoined) ...[
              const Text(
                'Call Controls:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _voiceService.toggleMute,
                      icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                      label: Text(_isMuted ? 'Unmute' : 'Mute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMuted ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _voiceService.toggleSpeaker,
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      ),
                      label: Text(_isSpeakerOn ? 'Earpiece' : 'Speaker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSpeakerOn
                            ? Colors.blue
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Debug Info
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('App ID: ${VoiceCallServiceImproved.appId}'),
                      Text('Is Joined: $_isJoined'),
                      Text('Is Muted: $_isMuted'),
                      Text('Speaker On: $_isSpeakerOn'),
                      Text('Remote UID: $_remoteUid'),
                      Text('Channel: ${_channelController.text}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '1. Test connection first\n'
                        '2. Enter same channel name on 2 devices\n'
                        '3. Join call on both devices\n'
                        '4. Test mute/speaker controls',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('Đã kết nối') || _status.contains('tham gia')) {
      return Colors.green;
    } else if (_status.contains('Đang') || _status.contains('kết nối')) {
      return Colors.orange;
    } else if (_status.contains('Lỗi') || _status.contains('thất bại')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (_status.contains('Đã kết nối') || _status.contains('tham gia')) {
      return Icons.check_circle;
    } else if (_status.contains('Đang') || _status.contains('kết nối')) {
      return Icons.sync;
    } else if (_status.contains('Lỗi') || _status.contains('thất bại')) {
      return Icons.error;
    } else {
      return Icons.info;
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    try {
      final success = await _voiceService.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Connection test successful!'
                  : 'Connection test failed!',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _joinCall() async {
    final channelName = _channelController.text.trim();
    if (channelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a channel name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _voiceService.joinCall(channelName);
  }

  Future<void> _leaveCall() async {
    await _voiceService.leaveCall();
  }
}
