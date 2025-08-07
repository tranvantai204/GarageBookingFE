import 'package:flutter/material.dart';
import '../models/trip.dart';

class SeatSelectionWidget extends StatefulWidget {
  final Trip trip;
  final List<String> selectedSeats;
  final Function(List<String>) onSeatsChanged;

  const SeatSelectionWidget({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.onSeatsChanged,
  });

  @override
  State<SeatSelectionWidget> createState() => _SeatSelectionWidgetState();
}

class _SeatSelectionWidgetState extends State<SeatSelectionWidget> {
  late List<String> _selectedSeats;

  @override
  void initState() {
    super.initState();
    _selectedSeats = List.from(widget.selectedSeats);
  }

  void _toggleSeat(String seatName) {
    setState(() {
      if (_selectedSeats.contains(seatName)) {
        _selectedSeats.remove(seatName);
      } else {
        _selectedSeats.add(seatName);
      }
    });
    widget.onSeatsChanged(_selectedSeats);
  }

  Color _getSeatColor(Seat seat) {
    if (seat.trangThai == 'da_dat') {
      return Colors.red.shade400; // Đã đặt
    } else if (_selectedSeats.contains(seat.tenGhe)) {
      return Colors.blue.shade600; // Đang chọn
    } else {
      return Colors.green.shade400; // Trống
    }
  }

  IconData _getSeatIcon(Seat seat) {
    if (seat.trangThai == 'da_dat') {
      return Icons.event_seat; // Ghế đã đặt
    } else if (_selectedSeats.contains(seat.tenGhe)) {
      return Icons.event_seat; // Ghế đang chọn
    } else {
      return Icons.event_seat_outlined; // Ghế trống
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với thông tin xe
          _buildBusHeader(),

          const SizedBox(height: 20),

          // Danh sách ghế
          _buildSeatGrid(),

          const SizedBox(height: 20),

          // Chú thích
          _buildLegend(),

          const SizedBox(height: 20),

          // Thông tin ghế đã chọn
          if (_selectedSeats.isNotEmpty) _buildSelectedSeatsInfo(),
        ],
      ),
    );
  }

  Widget _buildBusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xe ${widget.trip.soGhe} chỗ - ${widget.trip.nhaXe}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Biển số: ${widget.trip.bienSoXe}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.trip.soGheTrong} ghế trống',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 ghế mỗi hàng
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: widget.trip.danhSachGhe.length,
        itemBuilder: (context, index) {
          final seat = widget.trip.danhSachGhe[index];
          return _buildSeatButton(seat);
        },
      ),
    );
  }

  Widget _buildSeatButton(Seat seat) {
    final isDisabled = seat.trangThai == 'da_dat';
    final isSelected = _selectedSeats.contains(seat.tenGhe);

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleSeat(seat.tenGhe),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: _getSeatColor(seat),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getSeatIcon(seat), color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(
              seat.tenGhe,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          color: Colors.green.shade400,
          icon: Icons.event_seat_outlined,
          label: 'Trống',
        ),
        _buildLegendItem(
          color: Colors.blue.shade600,
          icon: Icons.event_seat,
          label: 'Đang chọn',
        ),
        _buildLegendItem(
          color: Colors.red.shade400,
          icon: Icons.event_seat,
          label: 'Đã đặt',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSelectedSeatsInfo() {
    final totalPrice = _selectedSeats.length * widget.trip.giaVe;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghế đã chọn:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedSeats.map((seat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  seat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${_formatCurrency(totalPrice)}đ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
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
