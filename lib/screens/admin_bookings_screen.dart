import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../utils/date_utils.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Gọi sau khi build xong để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> _getFilteredBookings(List<Booking> bookings) {
    List<Booking> filtered = bookings;

    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((booking) {
        switch (_selectedFilter) {
          case 'paid':
            return booking.trangThaiThanhToan == 'da_thanh_toan';
          case 'unpaid':
            return booking.trangThaiThanhToan == 'chua_thanh_toan';
          case 'checked_in':
            return booking.trangThaiCheckIn == 'da_check_in';
          case 'not_checked_in':
            return booking.trangThaiCheckIn == 'chua_check_in';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        return booking.maVe.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            booking.danhSachGhe.any(
              (seat) => seat.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý vé đặt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
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
          // Search and Filter Bar
          _buildSearchAndFilter(),

          // Bookings List
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                if (bookingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredBookings = _getFilteredBookings(
                  bookingProvider.bookings,
                );

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedFilter != 'all'
                              ? 'Không tìm thấy vé phù hợp'
                              : 'Chưa có vé nào',
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
                    await Provider.of<BookingProvider>(
                      context,
                      listen: false,
                    ).loadBookings();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _buildBookingCard(booking);
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

  Widget _buildSearchAndFilter() {
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
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã vé hoặc số ghế...',
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả'),
                _buildFilterChip('paid', 'Đã thanh toán'),
                _buildFilterChip('unpaid', 'Chưa thanh toán'),
                _buildFilterChip('checked_in', 'Đã check-in'),
                _buildFilterChip('not_checked_in', 'Chưa check-in'),
              ],
            ),
          ),
        ],
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

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetail(booking),
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
                          'Mã vé: ${booking.maVe}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đặt lúc: ${AppDateUtils.formatVietnameseDateTime(booking.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildStatusChip(booking.trangThaiThanhToan, 'payment'),
                      const SizedBox(height: 4),
                      _buildStatusChip(booking.trangThaiCheckIn, 'checkin'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trip Info
              if (booking.diemDi != null && booking.diemDen != null) ...[
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.diemDi} → ${booking.diemDen}',
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

              // Departure Time
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
                      AppDateUtils.formatVietnameseDateTime(
                        booking.thoiGianKhoiHanh!,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Seats and Price
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

              const SizedBox(height: 8),

              // Pickup Location
              if (booking.loaiDiemDon == 'dia_chi_cu_the' &&
                  booking.diaChiDon != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đón tại: ${booking.diaChiDon}',
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

              // Price
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String type) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (type == 'payment') {
      switch (status) {
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
    } else {
      switch (status) {
        case 'da_check_in':
          backgroundColor = Colors.blue.shade100;
          textColor = Colors.blue.shade700;
          text = 'Đã check-in';
          break;
        case 'chua_check_in':
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.grey.shade700;
          text = 'Chưa check-in';
          break;
        default:
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.grey.shade700;
          text = 'Không xác định';
      }
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
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showBookingDetail(Booking booking) {
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
              _buildDetailRow('Số lượng:', '${booking.danhSachGhe.length} ghế'),
              _buildDetailRow(
                'Tổng tiền:',
                '${_formatCurrency(booking.tongTien)}đ',
              ),
              _buildDetailRow(
                'Trạng thái thanh toán:',
                _getPaymentStatusText(booking.trangThaiThanhToan),
              ),
              _buildDetailRow(
                'Trạng thái check-in:',
                _getCheckInStatusText(booking.trangThaiCheckIn),
              ),
              if (booking.diemDi != null)
                _buildDetailRow('Điểm đi:', booking.diemDi!),
              if (booking.diemDen != null)
                _buildDetailRow('Điểm đến:', booking.diemDen!),
              if (booking.thoiGianKhoiHanh != null)
                _buildDetailRow(
                  'Khởi hành:',
                  AppDateUtils.formatVietnameseDateTime(
                    booking.thoiGianKhoiHanh!,
                  ),
                ),
              _buildDetailRow(
                'Loại điểm đón:',
                booking.loaiDiemDon == 'ben_xe' ? 'Bến xe' : 'Địa chỉ cụ thể',
              ),
              if (booking.diaChiDon != null)
                _buildDetailRow('Địa chỉ đón:', booking.diaChiDon!),
              if (booking.ghiChuDiemDon != null)
                _buildDetailRow('Ghi chú:', booking.ghiChuDiemDon!),
              _buildDetailRow(
                'Đặt lúc:',
                AppDateUtils.formatVietnameseDateTime(booking.createdAt),
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
            width: 120,
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

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'da_thanh_toan':
        return 'Đã thanh toán';
      case 'chua_thanh_toan':
        return 'Chưa thanh toán';
      default:
        return 'Không xác định';
    }
  }

  String _getCheckInStatusText(String status) {
    switch (status) {
      case 'da_check_in':
        return 'Đã check-in';
      case 'chua_check_in':
        return 'Chưa check-in';
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
}
