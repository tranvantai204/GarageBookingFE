import 'package:flutter/material.dart';
import '../api/admin_service.dart';

class OverdueBookingsScreen extends StatefulWidget {
  const OverdueBookingsScreen({super.key});

  @override
  State<OverdueBookingsScreen> createState() => _OverdueBookingsScreenState();
}

class _OverdueBookingsScreenState extends State<OverdueBookingsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AdminService.fetchOverdueBookings();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải vé quá hạn: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vé quá hạn'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('Không có vé quá hạn'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final b = _items[index];
                  final trip = b['tripId'] ?? {};
                  final user = b['userId'] ?? {};
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(
                        'Vé ${b['maVe'] ?? ''} • ${user['hoTen'] ?? ''}',
                      ),
                      subtitle: Text(
                        '${trip['diemDi'] ?? ''} → ${trip['diemDen'] ?? ''}\nKhởi hành: ${trip['thoiGianKhoiHanh'] ?? ''}',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
