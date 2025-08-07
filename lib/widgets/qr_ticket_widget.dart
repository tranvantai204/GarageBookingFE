import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class QRTicketWidget extends StatelessWidget {
  final Booking booking;

  const QRTicketWidget({super.key, required this.booking});

  // Tạo QR data đơn giản để tránh lỗi quá dài
  String _generateSimpleQRData(Booking booking) {
    return 'HAPHUONG|${booking.maVe}|${booking.danhSachGhe.join(",")}|${booking.tongTien}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'VÉ XE HÀ PHƯƠNG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã vé: ${booking.maVe}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),

          // Thông tin chuyến đi
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (booking.diemDi != null && booking.diemDen != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Từ: ${booking.diemDi}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đến: ${booking.diemDen}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (booking.thoiGianKhoiHanh != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Khởi hành: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.thoiGianKhoiHanh!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    const Icon(Icons.event_seat, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Ghế: ${booking.danhSachGhe.join(", ")}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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

                const SizedBox(height: 20),

                // QR Code
                if (booking.qrCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          child: QrImageView(
                            data: _generateSimpleQRData(booking),
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.L,
                            errorStateBuilder: (cxt, err) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Lỗi tạo QR code',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vui lòng xuất trình mã QR này khi lên xe',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Trạng thái check-in
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: booking.trangThaiCheckIn == 'da_check_in'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.trangThaiCheckIn == 'da_check_in'
                        ? 'Đã check-in'
                        : 'Chưa check-in',
                    style: TextStyle(
                      color: booking.trangThaiCheckIn == 'da_check_in'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
