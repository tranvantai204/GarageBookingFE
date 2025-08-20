import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen_with_online_call.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _payosUrl;

  @override
  void initState() {
    super.initState();
    _current = widget.booking;
    _loadQr();
    _loadPayosLink();
    _startAutoRefresh();
  }

  Future<void> _loadPayosLink() async {
    try {
      final resp = await Provider.of<BookingProvider>(
        context,
        listen: false,
      ).createPayosLink(type: 'booking', bookingId: _current.id);
      if (resp['success'] == true) {
        setState(
          () => _payosUrl = (resp['data']?['checkoutUrl'] ?? '') as String,
        );
      }
    } catch (_) {}
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
        setState(() => _qrUrl = (resp['data']?['qrImageUrl'] ?? '') as String);
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
                'Quét QR để thanh toán (ưu tiên PayOS/Casso)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: _payosUrl != null
                    ? Image(
                        image: NetworkImage(
                          // Render QR của chính checkoutUrl (PayOS sẽ xử lý khi mở link)
                          // Nếu muốn QR ảnh thật từ PayOS, cần API khác; tạm thời dùng URL -> người dùng mở link thay vì scan ảnh
                          'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=' +
                              Uri.encodeComponent(_payosUrl!),
                        ),
                        height: 240,
                        fit: BoxFit.contain,
                      )
                    : (_qrUrl == null
                          ? const SizedBox(height: 240)
                          : Image.network(
                              _qrUrl!,
                              height: 240,
                              fit: BoxFit.contain,
                            )),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _refreshStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra trạng thái'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final resp = await Provider.of<BookingProvider>(
                      context,
                      listen: false,
                    ).createPayosLink(type: 'booking', bookingId: _current.id);
                    final url = resp['data']?['checkoutUrl'] as String?;
                    if (url != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang mở PayOS...')),
                      );
                      final uri = Uri.parse(url);
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            resp['message'] ?? 'Tạo link PayOS thất bại',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Thanh toán qua PayOS (link)'),
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
                    final resp = await Provider.of<BookingProvider>(
                      context,
                      listen: false,
                    ).payBooking(bookingId: _current.id, method: 'wallet');
                    if (!mounted) return;
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
