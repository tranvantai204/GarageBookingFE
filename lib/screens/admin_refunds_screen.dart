import 'package:flutter/material.dart';
import '../api/admin_service.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});
  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  String _filter = 'pending';
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
      _items = await RefundApi.list(status: _filter);
    } catch (_) {
      _items = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu hoàn tiền'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('pending', 'Chờ duyệt'),
                const SizedBox(width: 8),
                _chip('approved', 'Đã duyệt'),
                const SizedBox(width: 8),
                _chip('rejected', 'Từ chối'),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('Không có yêu cầu'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = _items[i];
          final booking = it['bookingId'] ?? {};
          final user = it['userId'] ?? {};
          return ListTile(
            title: Text(
              'Vé ${booking['maVe'] ?? ''} • ${booking['tongTien'] ?? 0}đ',
            ),
            subtitle: Text('${user['hoTen'] ?? ''} • ${it['status']}'),
            trailing: _filter == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _action(it['_id'], true),
                        child: const Text('Duyệt'),
                      ),
                      TextButton(
                        onPressed: () => _action(it['_id'], false),
                        child: const Text('Từ chối'),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _action(String id, bool approve) async {
    final resp = await RefundApi.approve(id, approve: approve);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resp['success'] == true
              ? 'Cập nhật thành công'
              : (resp['message'] ?? 'Thất bại'),
        ),
      ),
    );
    await _load();
  }
}
