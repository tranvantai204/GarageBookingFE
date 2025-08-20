import 'package:flutter/material.dart';
import '../api/voucher_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() =>
      _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await VoucherService.fetchVouchers();
      if (!mounted) return;
      setState(() {
        _vouchers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải voucher: $e')));
    }
  }

  void _createVoucher() async {
    final payload = await _showVoucherDialog();
    if (payload == null) return;
    try {
      await VoucherService.createVoucher(payload);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tạo voucher lỗi: $e')));
    }
  }

  Future<Map<String, dynamic>?> _showVoucherDialog({
    Map<String, dynamic>? init,
  }) async {
    final codeCtrl = TextEditingController(text: init?['code']);
    final valueCtrl = TextEditingController(text: init?['value']?.toString());
    final minCtrl = TextEditingController(text: init?['minAmount']?.toString());
    final maxCtrl = TextEditingController(
      text: init?['maxDiscount']?.toString(),
    );
    final perUserCtrl = TextEditingController(
      text: (init?['perUserLimit'] ?? 1).toString(),
    );
    String type = init?['type'] ?? 'percent';
    // Keep UI simple, compute dates when saving
    bool onlyVip = init?['onlyVip'] ?? false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voucher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Mã voucher'),
              ),
              DropdownButtonFormField(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'percent', child: Text('%')),
                  DropdownMenuItem(value: 'amount', child: Text('VND')),
                ],
                onChanged: (v) {
                  type = v as String;
                },
                decoration: const InputDecoration(labelText: 'Loại'),
              ),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá trị'),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mức tối thiểu'),
              ),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giảm tối đa'),
              ),
              TextField(
                controller: perUserCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lần dùng tối đa / tài khoản (VD: 1)',
                ),
              ),
              SwitchListTile(
                value: onlyVip,
                onChanged: (v) {
                  setState(() {
                    onlyVip = v;
                  });
                },
                title: const Text('Chỉ VIP'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'code': codeCtrl.text.trim(),
                'type': type,
                'value': int.tryParse(valueCtrl.text.trim()) ?? 0,
                'minAmount': int.tryParse(minCtrl.text.trim()) ?? 0,
                'maxDiscount': int.tryParse(maxCtrl.text.trim()),
                'perUserLimit': int.tryParse(perUserCtrl.text.trim()) ?? 1,
                'startAt': DateTime.now().toIso8601String(),
                'endAt': DateTime.now()
                    .add(const Duration(days: 30))
                    .toIso8601String(),
                'onlyVip': onlyVip,
                'active': true,
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý voucher'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _createVoucher, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = _vouchers[index];
                return Card(
                  child: ListTile(
                    title: Text('${v['code']} • ${v['type']} ${v['value']}'),
                    subtitle: Text('Từ ${v['startAt']} đến ${v['endAt']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await VoucherService.deleteVoucher(v['_id']);
                        await _load();
                      },
                    ),
                    onTap: () async {
                      final payload = await _showVoucherDialog(init: v);
                      if (payload != null) {
                        await VoucherService.updateVoucher(v['_id'], payload);
                        await _load();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
