import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen_with_online_call.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Booking booking;

  const BookingPaymentScreen({super.key, required this.booking});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  late Booking _current;
  Timer? _pollTimer;
  bool _checking = false;
  String? _qrUrl;
  String? _bankAddInfo;

  @override
  void initState() {
    super.initState();
    _current = widget.booking;
    _loadQr();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _refreshStatus(),
    );
  }

  Future<void> _loadQr() async {
    try {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      final resp = await provider.createPaymentQr(
        type: 'booking',
        bookingId: _current.id,
      );
      if (resp['success'] == true) {
        setState(() {
          _qrUrl = (resp['data']?['qrImageUrl'] ?? '') as String;
          _bankAddInfo = resp['data']?['addInfo'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshStatus() async {
    if (!mounted || _checking) return;
    try {
      _checking = true;
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.loadBookings();
      final updated = provider.bookings.firstWhere(
        (b) => b.id == _current.id,
        orElse: () => _current,
      );
      if (!mounted) return;
      setState(() => _current = updated);
      if (_current.trangThaiThanhToan == 'da_thanh_toan') {
        _pollTimer?.cancel();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Thanh toán thành công'),
            content: const Text('Hệ thống đã xác nhận chuyển khoản.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _chatWithAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meId = prefs.getString('userId') ?? '';
      final meName = prefs.getString('hoTen') ?? '';
      final meRole = prefs.getString('vaiTro') ?? 'user';

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUsers();
      final admins = userProvider.users
          .where((u) => u.vaiTro == 'admin' && u.id.length == 24)
          .toList();
      if (admins.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy admin để nhắn tin')),
          );
        }
        return;
      }
      final admin = admins.first;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final roomId = await chatProvider.createOrGetChatRoom(
        currentUserId: meId,
        currentUserName: meName,
        currentUserRole: meRole,
        targetUserId: admin.id,
        targetUserName: admin.hoTen,
        targetUserRole: admin.vaiTro,
      );
      if (roomId != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreenWithOnlineCall(
              chatRoomId: roomId,
              chatRoomName: 'Hỗ trợ Admin',
              targetUserName: admin.hoTen,
              targetUserRole: 'admin',
              targetUserId: admin.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi mở chat: ' + e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = _current.trangThaiThanhToan == 'da_thanh_toan';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán vé'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // N button to message admin
          IconButton(
            tooltip: 'Nhắn admin',
            onPressed: _chatWithAdmin,
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'N',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã vé: ' + _current.maVe,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Ghế: ' + _current.danhSachGhe.join(', ')),
                  const SizedBox(height: 4),
                  Text(
                    'Số tiền: ' + _formatCurrency(_current.tongTien) + 'đ',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!paid) ...[
              const Text(
                'Quét QR ngân hàng để thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: _qrUrl != null
                    ? Image.network(_qrUrl!, height: 240, fit: BoxFit.contain)
                    : const SizedBox(height: 240),
              ),
              const SizedBox(height: 12),
              if (_bankAddInfo != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nội dung chuyển khoản: ${_bankAddInfo!}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _bankAddInfo!),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép nội dung chuyển khoản'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra trạng thái'),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Tôi đã chuyển khoản'),
                        content: Text(
                          'Vui lòng chuyển khoản theo đúng nội dung:\n${_bankAddInfo ?? ''}\nSau đó nhấn Xác nhận để hệ thống tự kiểm tra (không xác nhận thủ công).',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Đóng'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã ghi nhận. Hệ thống sẽ tự kiểm tra qua webhook.',
                          ),
                        ),
                      );
                      _startAutoRefresh();
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tôi đã chuyển khoản'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _startAutoRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã bật tự động kiểm tra mỗi 6 giây'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Tự động kiểm tra'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final balance = prefs.getInt('viSoDu') ?? 0;
                    final price = _current.tongTien;
                    final remain = balance - price;

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xác nhận thanh toán bằng ví'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số dư hiện có: ' +
                                  _formatCurrency(balance) +
                                  'đ',
                            ),
                            Text('Giá vé: ' + _formatCurrency(price) + 'đ'),
                            const SizedBox(height: 6),
                            Text(
                              'Số dư còn lại: ' + _formatCurrency(remain) + 'đ',
                              style: TextStyle(
                                color: remain >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (remain < 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Số dư không đủ. Vui lòng nạp thêm hoặc chọn cách khác.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: remain >= 0
                                ? () => Navigator.pop(ctx, true)
                                : null,
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final resp = await Provider.of<BookingProvider>(
                        context,
                        listen: false,
                      ).payBooking(bookingId: _current.id, method: 'wallet');
                      if (!mounted) return;
                      if (resp['success'] == true) {
                        await prefs.setInt('viSoDu', remain);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            resp['success'] == true
                                ? 'Thanh toán bằng ví thành công'
                                : (resp['message'] ?? 'Thanh toán ví thất bại'),
                          ),
                        ),
                      );
                      await _refreshStatus();
                    }
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Thanh toán bằng ví'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lưu ý: Hệ thống tự xác nhận sau khi nhận tiền qua webhook. Không cần gửi minh chứng.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text('Vé đã được xác nhận thanh toán'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => m[1]! + ',',
    );
  }
}
