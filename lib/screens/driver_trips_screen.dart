import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../models/trip.dart';
import 'qr_scanner_screen.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  String _driverName = '';
  String _driverId = '';
  String _selectedFilter = 'all'; // 'all', 'today', 'upcoming', 'completed'

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).loadTrips();
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  Future<void> _loadDriverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString('hoTen') ?? 'Tài xế';
      _driverId = prefs.getString('userId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến đi của tôi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildTripsList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tất cả'),
            _buildFilterChip('today', 'Hôm nay'),
            _buildFilterChip('upcoming', 'Sắp tới'),
            _buildFilterChip('completed', 'Đã hoàn thành'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildTripsList() {
    return Consumer2<TripProvider, BookingProvider>(
      builder: (context, tripProvider, bookingProvider, child) {
        if (tripProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTrips = _getFilteredTrips(tripProvider.trips);

        if (filteredTrips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<TripProvider>(context, listen: false).loadTrips();
            await Provider.of<BookingProvider>(
              context,
              listen: false,
            ).loadBookings();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              final tripBookings = bookingProvider.bookings
                  .where((booking) => booking.tripId == trip.id)
                  .toList();
              return _buildTripCard(trip, tripBookings);
            },
          ),
        );
      },
    );
  }

  List<Trip> _getFilteredTrips(List<Trip> allTrips) {
    // Filter trips for current driver
    final myTrips = allTrips
        .where((trip) => trip.taiXe == _driverName || trip.taiXeId == _driverId)
        .toList();

    switch (_selectedFilter) {
      case 'today':
        final today = DateTime.now();
        return myTrips.where((trip) {
          final tripDate = DateTime.parse(trip.gioKhoiHanh);
          return tripDate.day == today.day &&
              tripDate.month == today.month &&
              tripDate.year == today.year;
        }).toList();

      case 'upcoming':
        final now = DateTime.now();
        return myTrips.where((trip) {
          final tripDate = DateTime.parse(trip.gioKhoiHanh);
          return tripDate.isAfter(now);
        }).toList();

      case 'completed':
        final now = DateTime.now();
        return myTrips.where((trip) {
          final tripDate = trip.gioKetThuc ?? trip.thoiGianKhoiHanh;
          return tripDate.isBefore(now);
        }).toList();

      default:
        return myTrips;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'today':
        return 'Không có chuyến đi hôm nay';
      case 'upcoming':
        return 'Không có chuyến đi sắp tới';
      case 'completed':
        return 'Chưa có chuyến đi nào hoàn thành';
      default:
        return 'Chưa có chuyến đi nào được giao';
    }
  }

  Widget _buildTripCard(Trip trip, List<dynamic> bookings) {
    final tripDate = DateTime.parse(trip.gioKhoiHanh);
    final now = DateTime.now();
    final isUpcoming = tripDate.isAfter(now);
    final isToday =
        tripDate.day == now.day &&
        tripDate.month == now.month &&
        tripDate.year == now.year;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTripDetail(trip, bookings),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTripStatusColor(
                        trip,
                        isUpcoming,
                        isToday,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTripIcon(trip.loaiXe ?? 'ghe_ngoi'),
                      color: _getTripStatusColor(trip, isUpcoming, isToday),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.diemDi} → ${trip.diemDen}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatDate(tripDate)} • ${_formatTime(trip.gioKhoiHanh)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildTripStatusChip(trip, isUpcoming, isToday),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTripInfo(
                        'Hành khách',
                        '${trip.tongSoGhe - trip.soGheTrong}/${trip.tongSoGhe}',
                      ),
                    ),
                    Expanded(
                      child: _buildTripInfo(
                        'Loại xe',
                        _getVehicleTypeName(trip.loaiXe ?? 'ghe_ngoi'),
                      ),
                    ),
                    Expanded(
                      child: _buildTripInfo(
                        'Giá vé',
                        '${_formatCurrency(trip.giaVe)}đ',
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToQRScanner(),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Quét QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPassengerList(trip, bookings),
                        icon: const Icon(Icons.people, size: 18),
                        label: const Text('DS hành khách'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTripStatusChip(Trip trip, bool isUpcoming, bool isToday) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (isToday) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      text = 'Hôm nay';
    } else if (isUpcoming) {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade700;
      text = 'Sắp tới';
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      text = 'Đã qua';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getTripStatusColor(Trip trip, bool isUpcoming, bool isToday) {
    if (isToday) return Colors.green;
    if (isUpcoming) return Colors.blue;
    return Colors.grey;
  }

  IconData _getTripIcon(String loaiXe) {
    switch (loaiXe) {
      case 'limousine':
        return Icons.airport_shuttle;
      case 'giuong_nam':
        return Icons.airline_seat_flat;
      case 'ghe_ngoi':
        return Icons.event_seat;
      default:
        return Icons.directions_bus;
    }
  }

  String _getVehicleTypeName(String loaiXe) {
    switch (loaiXe) {
      case 'limousine':
        return 'Limousine';
      case 'giuong_nam':
        return 'Giường nằm';
      case 'ghe_ngoi':
        return 'Ghế ngồi';
      default:
        return 'Xe khách';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showTripDetail(Trip trip, List<dynamic> bookings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết chuyến đi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tuyến:', '${trip.diemDi} → ${trip.diemDen}'),
              _buildDetailRow('Khởi hành:', _formatTime(trip.gioKhoiHanh)),
              _buildDetailRow(
                'Kết thúc:',
                trip.gioKetThuc != null
                    ? _formatTime(trip.gioKetThuc!.toIso8601String())
                    : 'Chưa xác định',
              ),
              _buildDetailRow(
                'Loại xe:',
                _getVehicleTypeName(trip.loaiXe ?? 'ghe_ngoi'),
              ),
              _buildDetailRow('Biển số:', trip.bienSoXe ?? 'Chưa có'),
              _buildDetailRow('Số ghế:', '${trip.tongSoGhe}'),
              _buildDetailRow('Đã đặt:', '${trip.tongSoGhe - trip.soGheTrong}'),
              _buildDetailRow('Còn trống:', '${trip.soGheTrong}'),
              _buildDetailRow('Giá vé:', '${_formatCurrency(trip.giaVe)}đ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (DateTime.parse(trip.gioKhoiHanh).day == DateTime.now().day)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToQRScanner();
              },
              child: const Text('Quét QR'),
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
            width: 80,
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

  void _showPassengerList(Trip trip, List<dynamic> bookings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Danh sách hành khách'),
        content: SizedBox(
          width: double.maxFinite,
          child: bookings.isEmpty
              ? const Text('Chưa có hành khách đặt vé')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(booking.hoTen ?? 'Khách hàng'),
                      subtitle: Text(booking.soDienThoai ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: booking.trangThai == 'da_xac_nhan'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.trangThai == 'da_xac_nhan'
                              ? 'Đã xác nhận'
                              : 'Chờ xác nhận',
                          style: TextStyle(
                            color: booking.trangThai == 'da_xac_nhan'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
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

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }
}
