import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/wallet_service.dart';
import '../api/booking_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _payosUrl;
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
    // Lấy QR nạp ví qua API mới (VietQR với addInfo=TOPUP-<userId>)
    try {
      if (_userId.isNotEmpty) {
        // Ưu tiên PayOS; chỉ khi tạo link PayOS thất bại mới lấy VietQR dự phòng
        final linkResp = await BookingService.createPayosLink(
          type: 'topup',
          userId: _userId,
          amount: 0,
        );
        if (linkResp['success'] == true) {
          _payosUrl = (linkResp['data']?['checkoutUrl'] ?? '') as String?;
        }
        if (_payosUrl == null) {
          final qrResp = await BookingService.createPaymentQr(
            type: 'topup',
            userId: _userId,
            amount: 0,
          );
          if (qrResp['success'] == true) {
            _qrUrl = (qrResp['data']?['qrImageUrl'] ?? '') as String?;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
                          const Text('Quét QR để nạp tiền'),
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
                                  final linkResp =
                                      await BookingService.createPayosLink(
                                        type: 'topup',
                                        userId: _userId,
                                        amount: amt,
                                      );
                                  if (linkResp['success'] == true) {
                                    setState(
                                      () => _payosUrl =
                                          (linkResp['data']?['checkoutUrl'] ??
                                                  '')
                                              as String?,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          linkResp['message'] ??
                                              'Tạo link PayOS thất bại',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Tạo QR PayOS'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: _payosUrl != null
                                ? Image(
                                    image: NetworkImage(
                                      'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=' +
                                          Uri.encodeComponent(_payosUrl!),
                                    ),
                                    height: 220,
                                  )
                                : (_qrUrl == null
                                      ? const SizedBox(height: 220)
                                      : Image.network(
                                          _qrUrl!,
                                          height: 220,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        )),
                          ),
                          const SizedBox(height: 8),
                          if (_payosUrl != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(_payosUrl!);
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Mở PayOS (link)'),
                              ),
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
