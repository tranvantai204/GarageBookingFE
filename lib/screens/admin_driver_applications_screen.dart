import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/driver_application_service.dart';
import '../constants/api_constants.dart';
import '../providers/chat_provider.dart';

class AdminDriverApplicationsScreen extends StatefulWidget {
  const AdminDriverApplicationsScreen({super.key});

  @override
  State<AdminDriverApplicationsScreen> createState() =>
      _AdminDriverApplicationsScreenState();
}

class _AdminDriverApplicationsScreenState
    extends State<AdminDriverApplicationsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await DriverApplicationService.listAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn ứng tuyển tài xế')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final it = _items[index];
                  final status = (it['status'] ?? 'pending').toString();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'approved'
                            ? Colors.green.shade100
                            : status == 'rejected'
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          status == 'approved'
                              ? Icons.check
                              : status == 'rejected'
                              ? Icons.close
                              : Icons.hourglass_top,
                          color: status == 'approved'
                              ? Colors.green
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      title: Text(it['hoTen'] ?? ''),
                      subtitle: Text(
                        '${it['soDienThoai'] ?? ''}\n${it['email'] ?? ''}',
                      ),
                      isThreeLine: true,
                      onTap: () => _openDetail(it),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _openDetail(Map<String, dynamic> it) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: const Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it['hoTen'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(it['soDienThoai'] ?? ''),
                          Text(
                            it['email'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ảnh giấy phép lái xe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _preview(it['gplxUrl']),
                const SizedBox(height: 16),
                const Text(
                  'Ảnh CCCD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _preview(it['cccdUrl']),
                const SizedBox(height: 16),
                const Text(
                  'Mô tả',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text((it['note'] ?? '').toString()),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if ((it['status'] ?? 'pending') != 'approved')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await DriverApplicationService.approve(it['_id']);
                          if (!mounted) return;
                          Navigator.pop(context);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã duyệt làm tài xế'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if ((it['status'] ?? 'pending') != 'approved')
                      ElevatedButton.icon(
                        onPressed: () async {
                          await DriverApplicationService.reject(it['_id']);
                          if (!mounted) return;
                          Navigator.pop(context);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã từ chối đơn')),
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Từ chối'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final chatProvider = Provider.of<ChatProvider>(
                            context,
                            listen: false,
                          );
                          final prefs = await SharedPreferences.getInstance();
                          final myId = prefs.getString('userId') ?? '';
                          final myName = prefs.getString('hoTen') ?? '';
                          final myRole = prefs.getString('vaiTro') ?? 'admin';
                          final targetUserId = (it['userId'] ?? '').toString();
                          if (targetUserId.isEmpty) return;
                          final roomId = await chatProvider.createOrGetChatRoom(
                            currentUserId: myId,
                            currentUserName: myName,
                            currentUserRole: myRole,
                            targetUserId: targetUserId,
                            targetUserName: it['hoTen'] ?? 'Ứng viên',
                            targetUserRole: 'user',
                          );
                          if (roomId != null && mounted) {
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'chatRoomId': roomId,
                                'chatRoomName': it['hoTen'] ?? 'Ứng viên',
                                'targetUserName': it['hoTen'] ?? 'Ứng viên',
                                'targetUserRole': 'user',
                                'targetUserId': targetUserId,
                              },
                            );
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Trò chuyện'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _preview(String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final baseRoot = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 4)
        : ApiConstants.baseUrl;
    final fullUrl = url.startsWith('http') ? url : baseRoot + url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.image_not_supported)),
          ),
        ),
      ),
    );
  }
}
