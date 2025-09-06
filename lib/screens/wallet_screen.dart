import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/wallet_service.dart';
import '../utils/event_bus.dart';
import '../api/booking_service.dart';
import 'package:flutter/services.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _loading = true;
  int _balance = 0;
  List<dynamic> _txs = [];
  String _userId = '';
  String? _qrUrl;
  String? _addInfo;
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    final resp = await WalletService.getMyWallet();
    if (resp['success'] == true) {
      final data = resp['data'] as Map<String, dynamic>;
      _balance = data['balance'] ?? 0;
      _txs = data['transactions'] ?? [];
      await prefs.setInt('viSoDu', _balance);
    }
    // Lấy QR nạp ví qua API (VietQR với addInfo=TOPUP-<userId>)
    try {
      if (_userId.isNotEmpty) {
        final qrResp = await BookingService.createPaymentQr(
          type: 'topup',
          userId: _userId,
          amount: 0,
        );
        if (qrResp['success'] == true) {
          _qrUrl = (qrResp['data']?['qrImageUrl'] ?? '') as String?;
          _addInfo = qrResp['data']?['addInfo'] as String?;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    // Phát sự kiện để ProfileScreen tự reload số dư
    EventBus().emit(Events.walletUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số dư hiện tại',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatCurrency(_balance) + 'đ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Quét QR ngân hàng để nạp ví'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Số tiền nạp (VND)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final raw = _amountCtrl.text.trim();
                                  final amt = int.tryParse(raw) ?? 0;
                                  if (amt <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nhập số tiền > 0'),
                                      ),
                                    );
                                    return;
                                  }
                                  final qrResp =
                                      await BookingService.createPaymentQr(
                                        type: 'topup',
                                        userId: _userId,
                                        amount: amt,
                                      );
                                  if (qrResp['success'] == true) {
                                    setState(() {
                                      _qrUrl =
                                          (qrResp['data']?['qrImageUrl'] ?? '')
                                              as String?;
                                      _addInfo =
                                          qrResp['data']?['addInfo'] as String?;
                                    });
                                  }
                                },
                                child: const Text('Tạo QR nạp ví'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: _qrUrl == null
                                ? const SizedBox(height: 220)
                                : Image.network(
                                    _qrUrl!,
                                    height: 220,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          if (_addInfo != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Nội dung chuyển khoản: ${_addInfo!}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: _addInfo!),
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã sao chép nội dung chuyển khoản',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _txs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = _txs[i] as Map<String, dynamic>;
                        final type = (t['type'] ?? '').toString();
                        final amount = (t['amount'] ?? 0) as int;
                        return ListTile(
                          leading: Icon(
                            type == 'topup'
                                ? Icons.add
                                : (type == 'payment'
                                      ? Icons.remove
                                      : Icons.replay),
                            color: type == 'topup'
                                ? Colors.green
                                : (type == 'payment'
                                      ? Colors.red
                                      : Colors.orange),
                          ),
                          title: Text(
                            _typeText(type) +
                                ' ' +
                                _formatCurrency(amount) +
                                'đ',
                          ),
                          subtitle: Text(
                            DateTime.tryParse(
                                  t['createdAt']?.toString() ?? '',
                                )?.toLocal().toString() ??
                                '',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => m[1]! + ',',
    );
  }

  String _typeText(String type) {
    switch (type) {
      case 'topup':
        return 'Nạp ví';
      case 'payment':
        return 'Thanh toán vé';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }
}
