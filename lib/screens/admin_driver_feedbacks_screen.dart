import 'package:flutter/material.dart';
import '../api/feedback_service.dart';
import '../api/admin_service.dart';

class AdminDriverFeedbacksScreen extends StatefulWidget {
  const AdminDriverFeedbacksScreen({super.key});
  @override
  State<AdminDriverFeedbacksScreen> createState() =>
      _AdminDriverFeedbacksScreenState();
}

class _AdminDriverFeedbacksScreenState
    extends State<AdminDriverFeedbacksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String _selectedDriverId = 'all';
  int? _filterStars; // null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FeedbackService.adminList();
      setState(() => _items = list);
    } catch (_) {
      setState(() => _items = []);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> byDriver = _items;
    if (_selectedDriverId != 'all') {
      byDriver = byDriver
          .where((e) => (e['driverId'] ?? '') == _selectedDriverId)
          .toList();
    }
    final filtered = _filterStars == null
        ? byDriver
        : byDriver
              .where((e) => (e['ratingDriver'] ?? 0) == _filterStars)
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá tài xế'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc theo tài xế
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchDrivers(),
                builder: (context, snap) {
                  final drivers = snap.data ?? [];
                  return DropdownButton<String>(
                    value: _selectedDriverId,
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả tài xế'),
                      ),
                      ...drivers.map(
                        (d) => DropdownMenuItem(
                          value: d['id'],
                          child: Text(d['name'] ?? d['id']),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDriverId = v ?? 'all'),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _filterStars == null,
                  onSelected: (_) => setState(() => _filterStars = null),
                ),
                const SizedBox(width: 6),
                for (int s = 5; s >= 1; s--) ...[
                  ChoiceChip(
                    label: Text('$s sao'),
                    selected: _filterStars == s,
                    onSelected: (_) => setState(() => _filterStars = s),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final it = filtered[i];
                        final stars = (it['ratingDriver'] ?? 0).toInt();
                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (k) => Icon(
                                k < stars ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          title: Text(it['comment'] ?? ''),
                          subtitle: Text(
                            'Driver: ${it['driverId'] ?? ''} • Booking: ${it['bookingId'] ?? ''}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'approve' || v == 'rejected') {
                                final resp =
                                    await FeedbackService.adminUpdateStatus(
                                      it['_id'],
                                      v == 'approve' ? 'approved' : 'rejected',
                                    );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      resp['success'] == true
                                          ? 'Đã cập nhật'
                                          : (resp['message'] ?? 'Thất bại'),
                                    ),
                                  ),
                                );
                                await _load();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'approve',
                                child: Text('Duyệt'),
                              ),
                              PopupMenuItem(
                                value: 'rejected',
                                child: Text('Từ chối'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchDrivers() async {
    try {
      return await AdminService.fetchDrivers();
    } catch (_) {
      return [];
    }
  }
}
