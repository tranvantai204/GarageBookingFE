import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../models/trip.dart';
import '../models/booking.dart';

class AdminTripsScreen extends StatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Gọi sau khi build xong để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).loadTrips();
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> _getFilteredTrips(List<Trip> trips) {
    if (_searchQuery.isEmpty) return trips;

    return trips.where((trip) {
      return trip.diemDi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.diemDen.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.bienSoXe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.taiXe.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chuyến đi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TripProvider>(context, listen: false).loadTrips();
              Provider.of<BookingProvider>(
                context,
                listen: false,
              ).loadBookings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Trips List
          Expanded(
            child: Consumer2<TripProvider, BookingProvider>(
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
                        Icon(
                          Icons.directions_bus,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy chuyến đi phù hợp'
                              : 'Chưa có chuyến đi nào',
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
                    await Provider.of<TripProvider>(
                      context,
                      listen: false,
                    ).loadTrips();
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tuyến đường, biển số xe, tài xế...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip, List<Booking> bookings) {
    final bookedSeats = bookings.expand((b) => b.danhSachGhe).toList();
    final availableSeats = trip.soGhe - bookedSeats.length;
    final revenue = bookings
        .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
        .fold(0, (sum, b) => sum + b.tongTien);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTripDetail(trip, bookings),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.diemDi} → ${trip.diemDen}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(trip.thoiGianKhoiHanh),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: availableSeats > 0
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$availableSeats/${trip.soGhe} ghế trống',
                      style: TextStyle(
                        color: availableSeats > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Vehicle Info
              Row(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xe ${trip.soGhe} chỗ - ${trip.bienSoXe}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Driver Info
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài xế: ${trip.taiXe}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Vé đã đặt',
                      '${bookings.length}',
                      Icons.confirmation_number,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Đã thanh toán',
                      '${bookings.where((b) => b.trangThaiThanhToan == 'da_thanh_toan').length}',
                      Icons.payment,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Doanh thu',
                      '${_formatCurrency(revenue)}đ',
                      Icons.monetization_on,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTripDetail(Trip trip, List<Booking> bookings) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết chuyến đi',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trip Info
              _buildDetailSection('Thông tin chuyến đi', [
                _buildDetailRow(
                  'Tuyến đường:',
                  '${trip.diemDi} → ${trip.diemDen}',
                ),
                _buildDetailRow(
                  'Thời gian:',
                  DateFormat('dd/MM/yyyy HH:mm').format(trip.thoiGianKhoiHanh),
                ),
                _buildDetailRow('Xe:', '${trip.soGhe} chỗ - ${trip.bienSoXe}'),
                _buildDetailRow('Tài xế:', trip.taiXe),
                _buildDetailRow('Nhà xe:', trip.nhaXe),
              ]),

              const SizedBox(height: 16),

              // Bookings List
              Expanded(
                child: _buildDetailSection(
                  'Danh sách vé đã đặt (${bookings.length})',
                  [
                    if (bookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Chưa có vé nào được đặt')),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      booking.trangThaiThanhToan ==
                                          'da_thanh_toan'
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  child: Icon(
                                    Icons.confirmation_number,
                                    color:
                                        booking.trangThaiThanhToan ==
                                            'da_thanh_toan'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                title: Text('Vé ${booking.maVe}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ghế: ${booking.danhSachGhe.join(", ")}',
                                    ),
                                    Text(
                                      '${_formatCurrency(booking.tongTien)}đ',
                                    ),
                                    if (booking.loaiDiemDon ==
                                            'dia_chi_cu_the' &&
                                        booking.diaChiDon != null)
                                      Text(
                                        'Đón tại: ${booking.diaChiDon}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            booking.trangThaiThanhToan ==
                                                'da_thanh_toan'
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        booking.trangThaiThanhToan ==
                                                'da_thanh_toan'
                                            ? 'Đã TT'
                                            : 'Chưa TT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              booking.trangThaiThanhToan ==
                                                  'da_thanh_toan'
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            booking.trangThaiCheckIn ==
                                                'da_check_in'
                                            ? Colors.blue.shade100
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        booking.trangThaiCheckIn ==
                                                'da_check_in'
                                            ? 'Đã CI'
                                            : 'Chưa CI',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              booking.trangThaiCheckIn ==
                                                  'da_check_in'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
