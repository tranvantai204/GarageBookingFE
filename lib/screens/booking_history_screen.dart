import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';

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
    Provider.of<BookingProvider>(context, listen: false).loadBookings();
  }

  void _showBookingDetail(BuildContext context, booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết vé ${booking.maVe}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Mã vé:', booking.maVe),
              _buildDetailRow('Ghế:', booking.danhSachGhe.join(', ')),
              _buildDetailRow('Số lượng:', '${booking.soLuong} ghế'),
              _buildDetailRow(
                'Tổng tiền:',
                '${_formatCurrency(booking.tongTien)}đ',
              ),
              _buildDetailRow(
                'Trạng thái:',
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
            ],
          ),
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
        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<BookingProvider>(
              context,
              listen: false,
            ).loadBookings();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bookingProvider.bookings.length,
            itemBuilder: (context, index) {
              final booking = bookingProvider.bookings[index];
              return BookingCard(
                booking: booking,
                onTap: () {
                  _showBookingDetail(context, booking);
                },
              );
            },
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
