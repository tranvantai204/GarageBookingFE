import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onShowQR;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với mã vé và trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã vé: ${booking.maVe}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),

              const SizedBox(height: 16),

              // Thông tin chuyến đi
              if (booking.diemDi != null && booking.diemDen != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.diemDi!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.diemDen!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Thời gian khởi hành
              if (booking.thoiGianKhoiHanh != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(booking.thoiGianKhoiHanh!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Thông tin ghế
              Row(
                children: [
                  const Icon(Icons.event_seat, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ghế: ${booking.danhSachGhe.join(", ")} (${booking.danhSachGhe.length} ghế)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tổng tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${_formatCurrency(booking.tongTien)}đ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // Các nút hành động
              const SizedBox(height: 16),
              Row(
                children: [
                  // Nút xem QR
                  if (onShowQR != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onShowQR,
                        icon: const Icon(Icons.qr_code, size: 20),
                        label: const Text('Xem QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (onCancel != null && _canCancelBooking())
                      const SizedBox(width: 12),
                  ],

                  // Nút hủy vé
                  if (onCancel != null && _canCancelBooking()) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Hủy vé',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (booking.trangThaiThanhToan) {
      case 'da_thanh_toan':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = 'Đã thanh toán';
        break;
      case 'chua_thanh_toan':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = 'Chưa thanh toán';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  bool _canCancelBooking() {
    // Không cho hủy nếu không có thời gian khởi hành
    if (booking.thoiGianKhoiHanh == null) return false;

    final now = DateTime.now();
    final departureTime = booking.thoiGianKhoiHanh!;

    // Không cho hủy nếu đã quá giờ khởi hành
    if (departureTime.isBefore(now)) return false;

    // Không cho hủy nếu còn dưới 2 giờ
    if (now.isAfter(departureTime.subtract(const Duration(hours: 2)))) {
      return false;
    }

    // Không cho hủy nếu đã thanh toán
    if (booking.trangThaiThanhToan == 'da_thanh_toan') return false;

    return true;
  }
}
