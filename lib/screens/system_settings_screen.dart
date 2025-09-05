import 'package:flutter/material.dart';
import '../api/system_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _loading = true;
  final Map<String, dynamic> _values = {};
  final TextEditingController _cancelHoursCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await SystemService.getAll();
      final items = (resp['items'] as List).cast<Map<String, dynamic>>();
      for (final s in items) {
        _values[s['key']] = s['value'];
      }
      _cancelHoursCtrl.text = (_values['cancel_hours_before_departure'] ?? 2)
          .toString();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải cài đặt: $e')));
    }
  }

  Future<void> _save() async {
    try {
      final hours = int.tryParse(_cancelHoursCtrl.text.trim()) ?? 2;
      await SystemService.upsert('cancel_hours_before_departure', hours);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Cấu hình chung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SettingCard(
                        title: 'Chính sách hủy vé',
                        description: 'Số giờ trước khởi hành cho phép hủy',
                        child: TextField(
                          controller: _cancelHoursCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'VD: 2 giờ',
                          ),
                        ),
                      ),
                      _SettingCard(
                        title: 'Webhook & Realtime',
                        description: 'Theo dõi webhook Casso, Socket.IO',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(Icons.link),
                              title: Text('Webhook Casso'),
                              subtitle: Text('Đã cấu hình qua backend'),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(Icons.wifi_tethering),
                              title: Text('Socket.IO Realtime'),
                              subtitle: Text(
                                'Theo dõi vị trí tài xế, trạng thái chuyến',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingCard(
                        title: 'Thông báo',
                        description: 'FCM & Admin broadcast',
                        child: Column(
                          children: const [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(Icons.notifications),
                              title: Text('FCM Push'),
                              subtitle: Text(
                                'driver_rate_request, incoming_call, ...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  const _SettingCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
