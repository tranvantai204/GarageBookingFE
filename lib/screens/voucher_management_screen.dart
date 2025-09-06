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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Danh sách voucher (${_vouchers.length})',
                        style: const TextStyle(
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
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final crossAxisCount = screenWidth < 380 ? 1 : 2;
                        final mainAxisExtent = crossAxisCount == 1
                            ? 170.0
                            : 190.0;
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: mainAxisExtent,
                              ),
                          itemCount: _vouchers.length,
                          itemBuilder: (context, index) {
                            final v = _vouchers[index];
                            final active = v['active'] == true;
                            final onlyVip = v['onlyVip'] == true;
                            return InkWell(
                              onTap: () async {
                                final payload = await _showVoucherDialog(
                                  init: v,
                                );
                                if (payload != null) {
                                  await VoucherService.updateVoucher(
                                    v['_id'],
                                    payload,
                                  );
                                  await _load();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ),
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
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.discount,
                                            color: Colors.purple,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            v['code'] ?? 'MÃ',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await VoucherService.deleteVoucher(
                                              v['_id'],
                                            );
                                            await _load();
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Wrap to prevent overflow when text is long or on small screens
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        Chip(
                                          label: Text(
                                            '${v['type']} ${v['value']}',
                                          ),
                                          backgroundColor:
                                              Colors.purple.shade50,
                                          labelStyle: const TextStyle(
                                            color: Colors.purple,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        if (onlyVip)
                                          Chip(
                                            label: const Text('VIP'),
                                            backgroundColor:
                                                Colors.orange.shade50,
                                            labelStyle: const TextStyle(
                                              color: Colors.orange,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        Chip(
                                          label: Text(
                                            active
                                                ? 'Đang hoạt động'
                                                : 'Tạm tắt',
                                          ),
                                          backgroundColor: active
                                              ? Colors.green.shade50
                                              : Colors.grey.shade200,
                                          labelStyle: TextStyle(
                                            color: active
                                                ? Colors.green
                                                : Colors.grey.shade700,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Hiệu lực: ${v['startAt']} → ${v['endAt']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }, // end itemBuilder
                        ); // end GridView.builder
                      }, // end LayoutBuilder builder
                    ), // end LayoutBuilder
                  ), // end Expanded
                ],
              ),
            ),
    );
  }
}
