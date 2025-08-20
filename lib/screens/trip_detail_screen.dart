import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/seat_selection_widget.dart';
import '../widgets/pickup_location_widget.dart';
import '../widgets/customer_info_widget.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key});

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<String> selectedSeats = [];
  bool isLoading = false;
  final TextEditingController _voucherController = TextEditingController();
  int _discount = 0;

  // Thông tin điểm đón
  String pickupType = 'ben_xe';
  String? customAddress;
  String? pickupNote;

  // Thông tin khách hàng
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Trip trip = ModalRoute.of(context)!.settings.arguments as Trip;

    // Debug log
    print('🚌 Trip Detail - Trip ID: ${trip.id}');
    print('🚌 Trip Detail - Số ghế: ${trip.soGhe}');
    print('🚌 Trip Detail - Danh sách ghế: ${trip.danhSachGhe.length}');
    if (trip.danhSachGhe.isNotEmpty) {
      print('🚌 Trip Detail - Ghế đầu tiên: ${trip.danhSachGhe.first.tenGhe}');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${trip.nhaXe} - Chi tiết chuyến'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin chuyến đi
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin chuyến đi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on,
                      'Điểm đi',
                      trip.diemDi,
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      'Điểm đến',
                      trip.diemDen,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      'Thời gian',
                      '${trip.gioKhoiHanh} - ${trip.ngayKhoiHanh}',
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.directions_bus,
                      'Tài xế',
                      trip.taiXe,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.confirmation_number,
                      'Biển số xe',
                      trip.bienSoXe,
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.event_seat,
                      'Ghế trống',
                      '${trip.soGheTrong}/${trip.soGhe}',
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sơ đồ ghế
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn ghế',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSeatLegend(),
                    const SizedBox(height: 16),

                    // Widget chọn ghế mới
                    SeatSelectionWidget(
                      trip: trip,
                      selectedSeats: selectedSeats,
                      onSeatsChanged: (seats) {
                        setState(() {
                          selectedSeats = seats;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Widget chọn điểm đón
            if (selectedSeats.isNotEmpty) ...[
              PickupLocationWidget(
                selectedType: pickupType,
                customAddress: customAddress,
                note: pickupNote,
                onChanged: (type, address, note) {
                  setState(() {
                    pickupType = type;
                    customAddress = address;
                    pickupNote = note;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Voucher & tính tiền
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mã giảm giá',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập voucher (nếu có)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final code = _voucherController.text.trim();
                              if (code.isEmpty) return;
                              final amount = trip.giaVe * selectedSeats.length;
                              try {
                                final discount =
                                    await Provider.of<BookingProvider>(
                                      context,
                                      listen: false,
                                    ).validateVoucher(code, amount);
                                setState(() => _discount = discount);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Áp dụng voucher thành công'),
                                  ),
                                );
                              } catch (e) {
                                setState(() => _discount = 0);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Voucher không hợp lệ: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Áp dụng'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPriceSummary(trip, selectedSeats.length),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Widget thông tin khách hàng
              CustomerInfoWidget(
                nameController: _nameController,
                phoneController: _phoneController,
                emailController: _emailController,
              ),
              const SizedBox(height: 20),
            ],

            // Nút đặt vé
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedSeats.isEmpty || isLoading
                    ? null
                    : () async {
                        // Validation cho thông tin khách hàng
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập họ và tên'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (_phoneController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập số điện thoại'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validation cho địa chỉ đón
                        if (pickupType == 'dia_chi_cu_the' &&
                            (customAddress == null ||
                                customAddress!.trim().isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập địa chỉ đón cụ thể'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);
                        final result =
                            await Provider.of<BookingProvider>(
                              context,
                              listen: false,
                            ).createBookingWithPickup(
                              trip.id,
                              selectedSeats,
                              pickupType,
                              customAddress,
                              pickupNote,
                              customerName: _nameController.text.trim(),
                              customerPhone: _phoneController.text.trim(),
                              customerEmail:
                                  _emailController.text.trim().isNotEmpty
                                  ? _emailController.text.trim()
                                  : null,
                              voucherCode:
                                  _voucherController.text.trim().isNotEmpty
                                  ? _voucherController.text.trim()
                                  : null,
                              discountAmount: _discount > 0 ? _discount : null,
                            );
                        setState(() => isLoading = false);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result
                                    ? 'Đặt vé thành công!'
                                    : 'Đặt vé thất bại!',
                              ),
                              backgroundColor: result
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                          if (result) Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        selectedSeats.isEmpty
                            ? 'Vui lòng chọn ghế'
                            : 'Đặt vé (${selectedSeats.length} ghế)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(Trip trip, int seatCount) {
    final total = trip.giaVe * seatCount;
    final finalAmount = (total - _discount).clamp(0, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tạm tính'),
            Text('${_formatCurrency(total)}đ'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Giảm giá'),
            Text(
              '-${_formatCurrency(_discount)}đ',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_formatCurrency(finalAmount)}đ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(?<!\d)(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.green, 'Trống'),
        _buildLegendItem(Colors.red, 'Đã đặt'),
        _buildLegendItem(Colors.blue, 'Đang chọn'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
