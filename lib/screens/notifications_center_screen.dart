import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/admin_service.dart';
import '../utils/event_bus.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  List<Map<String, String>> _items = [];
  List<Map<String, dynamic>> _adminItems = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    EventBus().stream.listen((event) {
      if (event == Events.notificationsUpdated) {
        _load();
      }
    });
    _markAllAsReadSoon();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh whenever screen is re-built after navigating back
    _load();
  }

  Future<void> _markAllAsReadSoon() async {
    // Mark as read after first frame to allow screen transition
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString('inboxLastOpenedAt', now);
      await prefs.setString('adminNotifLastOpenedAt', now);
      EventBus().emit(Events.notificationsUpdated);
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('inbox') ?? [];
    List<Map<String, dynamic>> admin = [];
    try {
      admin = await AdminService.fetchAdminNotifications();
    } catch (_) {}
    setState(() {
      _items = raw.map((s) => _parse(s)).toList();
      _adminItems = admin;
      _loading = false;
    });
  }

  Map<String, String> _parse(String s) {
    try {
      final parts = s.split('|');
      return {
        'title': parts.elementAt(0),
        'body': parts.elementAt(1),
        'time': parts.elementAt(2),
      };
    } catch (_) {
      return {'title': 'Thông báo', 'body': s, 'time': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Xóa tất cả',
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty && _adminItems.isEmpty)
          ? const Center(child: Text('Chưa có thông báo'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_adminItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Thông báo từ Admin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._adminItems.map(
                    (it) => Card(
                      color: Colors.amber.shade50,
                      child: ListTile(
                        leading: const Icon(
                          Icons.campaign,
                          color: Colors.orange,
                        ),
                        title: Text(it['title'] ?? ''),
                        subtitle: Text(it['body'] ?? ''),
                        trailing: Text(
                          (it['createdAt'] ?? '')
                              .toString()
                              .substring(0, 16)
                              .replaceAll('T', ' '),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        onLongPress: () => _adminActions(it),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_items.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Thông báo hệ thống',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._items.map(
                    (it) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(it['title'] ?? ''),
                        subtitle: Text(it['body'] ?? ''),
                        trailing: Text(
                          it['time'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('inbox');
    setState(() => _items = []);
  }

  void _adminActions(Map<String, dynamic> item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      try {
        await AdminService.deleteAdminNotification(item['_id'] as String);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa thông báo')));
        }
      } catch (_) {}
    } else if (action == 'edit') {
      final titleController = TextEditingController(
        text: item['title']?.toString() ?? '',
      );
      final bodyController = TextEditingController(
        text: item['body']?.toString() ?? '',
      );
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chỉnh sửa thông báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Nội dung'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
      if (ok == true) {
        try {
          await AdminService.updateAdminNotification(
            id: item['_id'] as String,
            title: titleController.text.trim(),
            body: bodyController.text.trim(),
          );
          await _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật thông báo')),
            );
          }
        } catch (_) {}
      }
    }
  }
}
