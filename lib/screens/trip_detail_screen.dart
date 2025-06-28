import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key});

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<String> selectedSeats = [];
  bool isLoading = false;

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

                    // Hình ảnh minh họa sơ đồ xe
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Sơ đồ xe minh họa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _buildBusLayout(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Chọn ghế của bạn:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSeatMap(trip),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin đặt vé
            if (selectedSeats.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin đặt vé',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Ghế đã chọn: ${selectedSeats.join(", ")}'),
                      Text('Số lượng: ${selectedSeats.length} ghế'),
                      Text(
                        'Tổng tiền: ${(selectedSeats.length * trip.giaVe).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        setState(() => isLoading = true);
                        final result = await Provider.of<BookingProvider>(
                          context,
                          listen: false,
                        ).createBookingWithSeats(trip.id, selectedSeats);
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

  Widget _buildBusLayout() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        children: [
          // Tiêu đề
          Text(
            'Sơ đồ ghế xe 16 chỗ Ford Transit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),

          // Khoang lái và tài xế
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Khoang lái',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'Tài xế',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cửa lên xuống
          Row(
            children: [
              Container(
                width: 6,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.brown.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cửa lên xuống',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sơ đồ ghế theo layout Ford Transit 16 chỗ
          Expanded(
            child: Column(
              children: [
                // Hàng 1: 15, 11, 08, 05
                _buildSeatRow(['15', '11', '08', '05']),
                const SizedBox(height: 8),

                // Hàng 2: 14, 10, 07, 04
                _buildSeatRow(['14', '10', '07', '04']),
                const SizedBox(height: 8),

                // Hàng 3: 13, 09, 06, 03
                _buildSeatRow(['13', '09', '06', '03']),
                const SizedBox(height: 8),

                // Hàng 4: 12, [Lối đi], [Lối đi], 02
                Row(
                  children: [
                    _buildSeat('12'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Lối đi',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSeat('02'),
                  ],
                ),
                const SizedBox(height: 8),

                // Hàng 5: [Trống], [Trống], [Trống], 01
                Row(
                  children: [
                    const Spacer(),
                    const Spacer(),
                    const Spacer(),
                    _buildSeat('01'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatRow(List<String> seatNumbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: seatNumbers
          .map((seatNumber) => _buildSeat(seatNumber))
          .toList(),
    );
  }

  Widget _buildSeat(String seatNumber) {
    return Container(
      width: 35,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade600, width: 2),
      ),
      child: Center(
        child: Text(
          seatNumber,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
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

  Widget _buildSeatMap(Trip trip) {
    // Layout Ford Transit 16 chỗ theo đúng sơ đồ
    return Column(
      children: [
        // Hàng 1: 15, 11, 08, 05
        _buildSeatRowForSelection(['15', '11', '08', '05'], trip),
        const SizedBox(height: 8),

        // Hàng 2: 14, 10, 07, 04
        _buildSeatRowForSelection(['14', '10', '07', '04'], trip),
        const SizedBox(height: 8),

        // Hàng 3: 13, 09, 06, 03
        _buildSeatRowForSelection(['13', '09', '06', '03'], trip),
        const SizedBox(height: 8),

        // Hàng 4: 12, [Lối đi], 02
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectableSeat('12', trip),
            Container(
              width: 70,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  'Lối đi',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            _buildSelectableSeat('02', trip),
          ],
        ),
        const SizedBox(height: 8),

        // Hàng 5: [Trống], [Trống], [Trống], 01
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(width: 35, height: 30), // Trống
            Container(width: 70, height: 30), // Trống (lối đi)
            _buildSelectableSeat('01', trip),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatRowForSelection(List<String> seatNumbers, Trip trip) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: seatNumbers
          .map((seatNumber) => _buildSelectableSeat(seatNumber, trip))
          .toList(),
    );
  }

  Widget _buildSelectableSeat(String seatNumber, Trip trip) {
    // Tìm ghế trong danh sách từ API
    Seat? foundSeat;
    try {
      foundSeat = trip.danhSachGhe.firstWhere((s) => s.tenGhe == seatNumber);
    } catch (e) {
      // Nếu không tìm thấy, tạo ghế mới
      foundSeat = null;
    }

    final seat =
        foundSeat ??
        Seat(
          tenGhe: seatNumber,
          trangThai: 'trong',
          giaVe: trip.danhSachGhe.isNotEmpty
              ? trip.danhSachGhe.first.giaVe
              : 100000,
        );

    final isSelected = selectedSeats.contains(seat.tenGhe);
    final isAvailable = seat.trangThai == 'trong';

    Color seatColor;
    if (!isAvailable) {
      seatColor = Colors.red;
    } else if (isSelected) {
      seatColor = Colors.blue;
    } else {
      seatColor = Colors.green;
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seat.tenGhe);
                } else {
                  selectedSeats.add(seat.tenGhe);
                }
              });
            }
          : null,
      child: Container(
        width: 35,
        height: 30,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            seat.tenGhe,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
