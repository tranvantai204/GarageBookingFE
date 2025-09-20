import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../models/trip.dart';
import '../models/booking.dart';
import '../utils/date_utils.dart';

class AdminTripsScreen extends StatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _onlyWithTickets = false;
  bool _onlyAvailableSeats = false;
  String _paymentFilter = 'all'; // all | paid | unpaid

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
    List<Trip> result = trips;

    // Text search
    if (_searchQuery.isNotEmpty) {
      result = result.where((trip) {
        final q = _searchQuery.toLowerCase();
        return trip.diemDi.toLowerCase().contains(q) ||
            trip.diemDen.toLowerCase().contains(q) ||
            trip.bienSoXe.toLowerCase().contains(q) ||
            trip.taiXe.toLowerCase().contains(q);
      }).toList();
    }

    // Date range filter (inclusive)
    if (_fromDate != null || _toDate != null) {
      final fromDate = _fromDate != null
          ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0)
          : DateTime(2000);
      final toDate = _toDate != null
          ? DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
              23,
              59,
              59,
              999,
            )
          : DateTime(2100);
      result = result.where((t) {
        final dt = t.thoiGianKhoiHanh;
        return !dt.isBefore(fromDate) && !dt.isAfter(toDate);
      }).toList();
    }

    return result;
  }

  List<Trip> _applyAdvancedFilters(
    List<Trip> trips,
    BookingProvider bookingProvider,
  ) {
    List<Trip> result = List.of(trips);

    if (_onlyAvailableSeats) {
      result = result.where((trip) {
        final booked = bookingProvider.bookings
            .where((b) => b.tripId == trip.id)
            .expand((b) => b.danhSachGhe)
            .length;
        return (trip.soGhe - booked) > 0;
      }).toList();
    }

    if (_onlyWithTickets) {
      result = result.where((trip) {
        return bookingProvider.bookings.any((b) => b.tripId == trip.id);
      }).toList();
    }

    if (_paymentFilter != 'all') {
      result = result.where((trip) {
        final related = bookingProvider.bookings.where(
          (b) => b.tripId == trip.id,
        );
        if (_paymentFilter == 'paid') {
          return related.any((b) => b.trangThaiThanhToan == 'da_thanh_toan');
        } else {
          return related.any((b) => b.trangThaiThanhToan != 'da_thanh_toan');
        }
      }).toList();
    }

    return result;
  }

  Future<void> _pickDateRange() async {
    final initialDateRange = (_fromDate != null && _toDate != null)
        ? DateTimeRange(start: _fromDate!, end: _toDate!)
        : null;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialDateRange,
      helpText: 'Chọn khoảng ngày khởi hành',
      locale: const Locale('vi'),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
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

          // Filter Bar
          _buildFilterBar(),

          // Trips List
          Expanded(
            child: Consumer2<TripProvider, BookingProvider>(
              builder: (context, tripProvider, bookingProvider, child) {
                if (tripProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final baseFiltered = _getFilteredTrips(tripProvider.trips);
                final filteredTrips = _applyAdvancedFilters(
                  baseFiltered,
                  bookingProvider,
                );

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

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InputChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(
                (_fromDate == null && _toDate == null)
                    ? 'Khoảng ngày'
                    : '${AppDateUtils.formatVietnameseDate(_fromDate!)} - ${AppDateUtils.formatVietnameseDate(_toDate!)}',
              ),
              onPressed: _pickDateRange,
              onDeleted: (_fromDate != null || _toDate != null)
                  ? () => setState(() {
                      _fromDate = null;
                      _toDate = null;
                    })
                  : null,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Còn chỗ'),
              selected: _onlyAvailableSeats,
              onSelected: (v) => setState(() => _onlyAvailableSeats = v),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Có vé'),
              selected: _onlyWithTickets,
              onSelected: (v) => setState(() => _onlyWithTickets = v),
            ),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _paymentFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Thanh toán: Tất cả'),
                    ),
                    DropdownMenuItem(value: 'paid', child: Text('Chỉ đã TT')),
                    DropdownMenuItem(
                      value: 'unpaid',
                      child: Text('Chỉ chưa TT'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _paymentFilter = v ?? 'all'),
                ),
              ),
            ),
          ],
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
                          AppDateUtils.formatVietnameseDateTime(
                            trip.thoiGianKhoiHanh,
                          ),
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
                  const SizedBox(width: 8),
                  // Nút xóa chuyến đi
                  IconButton(
                    onPressed: () => _confirmDeleteTrip(trip, bookings),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Xóa chuyến đi',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
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

              const SizedBox(height: 12),

              // Quick tickets preview
              if (bookings.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vé gần đây',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final b in bookings.take(6))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: b.trangThaiThanhToan == 'da_thanh_toan'
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: b.trangThaiThanhToan == 'da_thanh_toan'
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_number, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Vé ${b.maVe} • ${b.danhSachGhe.join(', ')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        if (bookings.length > 6)
                          Text(
                            '+${bookings.length - 6} vé',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
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
                  AppDateUtils.formatVietnameseDateTime(trip.thoiGianKhoiHanh),
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

  Future<void> _confirmDeleteTrip(Trip trip, List<Booking> bookings) async {
    // Kiểm tra xem có vé đã đặt không
    if (bookings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể xóa'),
          content: Text(
            'Chuyến đi này đã có ${bookings.length} vé được đặt. Không thể xóa chuyến đi đã có khách đặt vé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Hiển thị dialog xác nhận xóa
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa chuyến đi từ ${trip.diemDi} đến ${trip.diemDen}?\n\nThời gian: ${AppDateUtils.formatVietnameseDateTime(trip.thoiGianKhoiHanh)}\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTrip(trip);
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    try {
      // Lấy token từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Hiển thị loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final success = await tripProvider.deleteTrip(trip.id, token);

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa chuyến đi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa chuyến đi. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
