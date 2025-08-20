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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Chính sách hủy vé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cancelHoursCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Số giờ trước khởi hành cho phép hủy (VD: 2)',
                  ),
                ),
              ],
            ),
    );
  }
}
