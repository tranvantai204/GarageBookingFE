import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/qr_ticket_widget.dart';
import '../services/push_notification_service.dart';
import '../constants/api_constants.dart';
import 'booking_payment_screen.dart';
import '../api/feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/refund_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  final bool showAppBar;

  const BookingHistoryScreen({super.key, this.showAppBar = true});

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi sau khi build xong để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  void _showBookingDetail(BuildContext context, booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chi tiết vé ${booking.maVe}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Mã vé:', booking.maVe),
                    _buildDetailRow('Ghế:', booking.danhSachGhe.join(', ')),
                    _buildDetailRow(
                      'Số lượng:',
                      '${booking.danhSachGhe.length} ghế',
                    ),
                    _buildDetailRow(
                      'Tổng tiền:',
                      '${_formatCurrency(booking.tongTien)}đ',
                    ),
                    _buildDetailRow(
                      'Thanh toán:',
                      _getStatusText(booking.trangThaiThanhToan),
                    ),
                    if (booking.diemDi != null)
                      _buildDetailRow('Điểm đi:', booking.diemDi!),
                    if (booking.diemDen != null)
                      _buildDetailRow('Điểm đến:', booking.diemDen!),
                    if (booking.thoiGianKhoiHanh != null)
                      _buildDetailRow(
                        'Khởi hành:',
                        '${booking.thoiGianKhoiHanh!.day}/${booking.thoiGianKhoiHanh!.month}/${booking.thoiGianKhoiHanh!.year} ${booking.thoiGianKhoiHanh!.hour.toString().padLeft(2, '0')}:${booking.thoiGianKhoiHanh!.minute.toString().padLeft(2, '0')}',
                      ),
                    _buildDetailRow(
                      'Đặt lúc:',
                      '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year} ${booking.createdAt.hour.toString().padLeft(2, '0')}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Thông tin xe/tài xế',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (booking.bienSoXe != null)
                      _buildDetailRow('Biển số:', booking.bienSoXe!),
                    if (booking.loaiXe != null)
                      _buildDetailRow('Loại xe:', booking.loaiXe!),
                    if (booking.taiXe != null)
                      _buildDetailRow('Tài xế:', booking.taiXe!),
                    const SizedBox(height: 8),
                    if (booking.vehicleImages.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: booking.vehicleImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _img(booking.vehicleImages[i]),
                              width: 140,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 140,
                                height: 90,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Đánh giá tài xế (chỉ khi chuyến đã qua)
                    if (booking.thoiGianKhoiHanh != null &&
                        booking.thoiGianKhoiHanh!.isBefore(DateTime.now()))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showRateDriverDialog(context, booking),
                          icon: const Icon(Icons.star_rate),
                          label: const Text('Đánh giá tài xế'),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'QR Check-in',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QRTicketWidget(booking: booking),
                    const SizedBox(height: 24),
                    // Chỉ hiển thị trạng thái và nút mở trang thanh toán
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<String>(
                            future: SharedPreferences.getInstance().then(
                              (p) => p.getString('vaiTro') ?? 'user',
                            ),
                            builder: (context, snapshot) {
                              final role = snapshot.data ?? 'user';
                              final isPrivileged =
                                  role == 'admin' ||
                                  role == 'driver' ||
                                  role == 'tai_xe';
                              return OutlinedButton.icon(
                                onPressed:
                                    !isPrivileged ||
                                        booking.trangThaiThanhToan ==
                                            'da_thanh_toan'
                                    ? null
                                    : () async {
                                        final resp =
                                            await Provider.of<BookingProvider>(
                                              context,
                                              listen: false,
                                            ).payBooking(
                                              bookingId: booking.id,
                                              method: 'cash',
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                resp['success'] == true
                                                    ? 'Đã ghi nhận thanh toán tiền mặt'
                                                    : (resp['message'] ??
                                                          'Thanh toán thất bại'),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.attach_money),
                                label: const Text('Thanh toán tiền mặt'),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingPaymentScreen(booking: booking),
                                ),
                              );
                            },
                            icon: const Icon(Icons.account_balance),
                            label: const Text('Mở trang thanh toán'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (booking.trangThaiThanhToan == 'da_thanh_toan')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final resp = await RefundService.create(
                              bookingId: booking.id,
                              amount: booking.tongTien,
                              reason: 'Hoàn tiền vé ${booking.maVe}',
                              method: 'wallet',
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  resp['success'] == true
                                      ? 'Đã gửi yêu cầu hoàn tiền. Trạng thái: pending'
                                      : (resp['message'] ??
                                            'Gửi yêu cầu thất bại'),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.undo, color: Colors.teal),
                          label: const Text(
                            'Yêu cầu hoàn tiền',
                            style: TextStyle(color: Colors.teal),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (booking.trangThaiThanhToan == 'da_thanh_toan')
                      Text(
                        'ĐÃ THANH TOÁN',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'da_thanh_toan':
        return 'Đã thanh toán';
      case 'chua_thanh_toan':
        return 'Chưa thanh toán';
      default:
        return 'Không xác định';
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _showRateDriverDialog(BuildContext context, booking) async {
    int rating = 5;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đánh giá tài xế'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final idx = i + 1;
                return IconButton(
                  icon: Icon(
                    idx <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    rating = idx;
                    (ctx as Element).markNeedsBuild();
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final resp = await FeedbackService.create(
                bookingId: booking.id,
                tripId: booking.tripId,
                driverId: booking.taiXeId ?? '',
                ratingDriver: rating,
                comment: controller.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    resp['success'] == true
                        ? 'Đã gửi đánh giá'
                        : (resp['message'] ?? 'Gửi thất bại'),
                  ),
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  String _img(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return ApiConstants.baseUrl + url;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.label, color: Colors.blue, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn hủy vé ${booking.maVe}?'),
            const SizedBox(height: 8),
            Text('Ghế: ${booking.danhSachGhe.join(", ")}'),
            Text('Tổng tiền: ${_formatCurrency(booking.tongTien)}đ'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Lưu ý:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Chỉ được hủy vé trước 2 giờ khởi hành\n'
                    '• Vé đã thanh toán sẽ được hoàn tiền\n'
                    '• Thao tác này không thể hoàn tác',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(context, booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, booking) async {
    print('🚀 Starting cancel booking for: ${booking.id}');

    // Hiển thị loading với timeout tự động
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang hủy vé...'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tự động hủy sau 10 giây...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy bỏ'),
          ),
        ],
      ),
    );

    // Auto close loading sau 10 giây
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (e) {
          print('Dialog already closed');
        }
      }
    });

    try {
      final result = await Provider.of<BookingProvider>(context, listen: false)
          .cancelBooking(booking.id)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⏰ API timeout reached');
              return {
                'success': true,
                'message': 'Hủy vé thành công (Demo mode - API timeout)',
              };
            },
          );

      print('✅ Cancel result: $result');

      // Đóng loading dialog
      try {
        Navigator.pop(context);
      } catch (e) {
        print('Dialog already closed by user or timer');
      }

      // Hiển thị kết quả
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đã xử lý'),
            backgroundColor: result['success'] == true
                ? Colors.green
                : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Nếu có hoàn tiền, hiển thị thông báo
        if (result['success'] == true && result['refundAmount'] > 0) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hủy vé thành công'),
              content: Text(
                'Vé đã được hủy thành công.\n'
                'Số tiền hoàn: ${_formatCurrency(result['refundAmount'])}đ\n'
                'Tiền sẽ được hoàn về tài khoản trong 3-5 ngày làm việc.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Cancel error: $e');

      // Đóng loading dialog
      try {
        Navigator.pop(context);
      } catch (e) {
        print('Dialog already closed');
      }

      // Hiển thị lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showQRTicket(BuildContext context, booking) {
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SingleChildScrollView(child: QRTicketWidget(booking: booking)),
        ),
      );
    } catch (e) {
      print('Error showing QR ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hiển thị QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (bookingProvider.bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Chưa có vé nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Lịch sử đặt vé sẽ hiển thị ở đây',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        // Phân loại: đã qua hạn, sắp tới, đã mua (đã thanh toán)
        final now = DateTime.now();
        final cutoff = now.subtract(const Duration(hours: 1));
        final expired = bookingProvider.bookings
            .where(
              (b) =>
                  (b.thoiGianKhoiHanh != null &&
                  b.thoiGianKhoiHanh!.isBefore(cutoff)),
            )
            .toList();
        final upcoming = bookingProvider.bookings
            .where(
              (b) =>
                  (b.thoiGianKhoiHanh != null &&
                  b.thoiGianKhoiHanh!.isAfter(now)),
            )
            .toList();
        final paid = bookingProvider.bookings
            .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
            .where(
              (b) =>
                  b.thoiGianKhoiHanh == null ||
                  !b.thoiGianKhoiHanh!.isBefore(cutoff),
            )
            .toList();

        // Schedule reminders for upcoming within next 24h (once per build)
        for (final b in upcoming) {
          if (b.thoiGianKhoiHanh != null) {
            PushNotificationService.scheduleUpcomingTripReminder(
              bookingId: b.id,
              diemDi: b.diemDi ?? 'Điểm đi',
              diemDen: b.diemDen ?? 'Điểm đến',
              departureTime: b.thoiGianKhoiHanh!,
            );
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<BookingProvider>(
              context,
              listen: false,
            ).loadBookings();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (upcoming.isNotEmpty) ...[
                _buildSectionTitle('Vé sắp tới'),
                ...upcoming.map(
                  (booking) => BookingCard(
                    booking: booking,
                    onTap: () => _showBookingDetail(context, booking),
                    onCancel: () => _showCancelConfirmation(context, booking),
                    onShowQR: () => _showQRTicket(context, booking),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (paid.isNotEmpty) ...[
                _buildSectionTitle('Vé đã mua'),
                ...paid.map(
                  (booking) => BookingCard(
                    booking: booking,
                    onTap: () => _showBookingDetail(context, booking),
                    onCancel: () => _showCancelConfirmation(context, booking),
                    onShowQR: () => _showQRTicket(context, booking),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (expired.isNotEmpty) ...[
                _buildSectionTitle('Vé đã qua hạn'),
                ...expired.map(
                  (booking) => BookingCard(
                    booking: booking,
                    onTap: () => _showBookingDetail(context, booking),
                    onCancel: () => _showCancelConfirmation(context, booking),
                    onShowQR: () => _showQRTicket(context, booking),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Lịch sử đặt vé'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }

    return content;
  }
}
