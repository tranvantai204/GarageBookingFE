import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/trip_card.dart';
import '../models/trip.dart';
import 'create_trip_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_utils.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TripListScreen extends StatefulWidget {
  final bool showAppBar;

  const TripListScreen({super.key, this.showAppBar = true});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  String _userRole = 'user';
  String _userName = '';
  String _userId = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _onlyAvailableSeats = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Sử dụng WidgetsBinding để đảm bảo load trips sau khi build hoàn thành
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TripProvider>(context, listen: false).loadTrips();
        Provider.of<BookingProvider>(context, listen: false).loadBookings();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedRole = prefs.getString('vaiTro') ?? 'user';
    final loadedName = prefs.getString('hoTen') ?? '';
    final loadedUserId = prefs.getString('userId') ?? '';

    setState(() {
      _userRole = loadedRole;
      _userName = loadedName;
      _userId = loadedUserId;
    });

    // Kiểm tra lại vai trò từ server để đảm bảo chính xác
    // await _refreshUserRole(); // Tạm tắt vì API /auth/me không tồn tại
  }

  // _refreshUserRole() tắt do API /auth/me chưa khả dụng

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Xóa tất cả dữ liệu user
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('hoTen');
      await prefs.remove('vaiTro');

      // Xóa toàn bộ SharedPreferences để đảm bảo
      await prefs.clear();

      if (mounted) {
        // Hiển thị thông báo đăng xuất
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng xuất thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Chuyển về màn hình đăng nhập
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Lỗi khi logout, vẫn chuyển về login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  List<Trip> _getFilteredTrips(
    List<Trip> allTrips,
    BookingProvider bookingProvider,
  ) {
    // Base by role
    List<Trip> result;
    if (_userRole == 'driver' || _userRole == 'tai_xe') {
      result = allTrips.where((trip) {
        final matchesName =
            trip.taiXe.trim().toLowerCase() == _userName.trim().toLowerCase();
        final matchesId = (trip.taiXeId?.toString() ?? '') == _userId;
        final containsName = trip.taiXe.toLowerCase().contains(
          _userName.toLowerCase(),
        );
        return matchesName || matchesId || containsName;
      }).toList();
    } else {
      result = List.of(allTrips);
    }

    // Text search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.diemDi.toLowerCase().contains(q) ||
            t.diemDen.toLowerCase().contains(q) ||
            t.bienSoXe.toLowerCase().contains(q) ||
            (t.taiXe.toLowerCase().contains(q) == true);
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

    // Only trips with available seats
    if (_onlyAvailableSeats) {
      result = result.where((t) {
        final booked = bookingProvider.bookings
            .where((b) => b.tripId == t.id)
            .expand((b) => b.danhSachGhe)
            .length;
        return (t.soGhe - booked) > 0;
      }).toList();
    }

    // Always hide trips already departed (client-side guard)
    final now = DateTime.now();
    result = result.where((t) => t.thoiGianKhoiHanh.isAfter(now)).toList();
    return result;
  }

  String _getEmptyMessage() {
    if (_userRole == 'admin') {
      return 'Hãy tạo chuyến đi đầu tiên';
    } else if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return 'Chưa có chuyến đi nào được giao cho bạn';
    } else {
      return 'Chưa có chuyến đi nào. Vui lòng quay lại sau.';
    }
  }

  Color _getRoleBadgeColor() {
    if (_userRole == 'admin') return Colors.red;
    if (_userRole == 'driver' || _userRole == 'tai_xe') return Colors.blue;
    return Colors.green;
  }

  String _getRoleBadgeText() {
    if (_userRole == 'admin') return 'ADMIN';
    if (_userRole == 'driver' || _userRole == 'tai_xe') return 'TÀI XẾ';
    return 'USER';
  }

  @override
  Widget build(BuildContext context) {
    final listContent = RefreshIndicator(
      onRefresh: () async {
        await Provider.of<TripProvider>(context, listen: false).loadTrips();
        await Provider.of<BookingProvider>(
          context,
          listen: false,
        ).loadBookings();
      },
      child: Consumer2<TripProvider, BookingProvider>(
        builder: (context, tripProvider, bookingProvider, child) {
          if (tripProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách chuyến đi...'),
                ],
              ),
            );
          }

          final filteredTrips = _getFilteredTrips(
            tripProvider.trips,
            bookingProvider,
          );

          if (filteredTrips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có chuyến đi nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyMessage(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  if (_userRole == 'admin')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateTripScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          Provider.of<TripProvider>(
                            context,
                            listen: false,
                          ).loadTrips();
                        }
                      },
                      icon: const Icon(Icons.add_box),
                      label: const Text('Tạo chuyến đi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              final trip = filteredTrips[index];
              return TripCard(
                trip: trip,
                isAdmin: _userRole == 'admin',
                onTap: () {
                  Navigator.pushNamed(context, '/trip_detail', arguments: trip);
                },
                onDelete: _userRole == 'admin'
                    ? () => _confirmDeleteTrip(trip)
                    : null,
              );
            },
          );
        },
      ),
    );

    final content = Column(
      children: [
        _buildHeaderBanner(),
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(child: listContent),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Đặt xe Hà Phương${_userName.isNotEmpty ? ' - $_userName ($_userRole)' : ''}',
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            // QR Scanner button for drivers
            if (_userRole == 'driver' || _userRole == 'tai_xe')
              IconButton(
                onPressed: () {
                  // Navigate to QR Scanner
                  Navigator.pushNamed(context, '/qr_scanner');
                },
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Quét mã QR',
              ),
            // Hiển thị role badge
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleBadgeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleBadgeText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'create_trip':
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTripScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      Provider.of<TripProvider>(
                        context,
                        listen: false,
                      ).loadTrips();
                    }
                    break;
                  case 'refresh':
                    Provider.of<TripProvider>(
                      context,
                      listen: false,
                    ).loadTrips();
                    break;
                  case 'booking_history':
                    Navigator.pushNamed(context, '/booking_history');
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                // Chỉ admin mới thấy tạo chuyến đi
                if (_userRole == 'admin') ...[
                  PopupMenuItem<String>(
                    value: 'create_trip',
                    child: Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Tạo chuyến đi'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                ],
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Làm mới'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'booking_history',
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Lịch sử đặt vé'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildHeaderBanner() {
    if (_userRole == 'driver' || _userRole == 'tai_xe') {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: AppTheme.shadowPrimary,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName.isNotEmpty ? 'Xin chào, $_userName!' : 'Xin chào!',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Danh sách chuyến được giao',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowPrimary,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty
                      ? 'Xin chào, ${_userName.split(' ').last}! 👋'
                      : 'Chào mừng bạn!',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tìm chuyến xe phù hợp với bạn',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (_userRole == 'admin')
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                );
                if (result == true && mounted) {
                  Provider.of<TripProvider>(context, listen: false).loadTrips();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Tạo chuyến',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm tuyến đường, biển số, tài xế...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final initial = (_fromDate != null && _toDate != null)
        ? DateTimeRange(start: _fromDate!, end: _toDate!)
        : null;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              icon: Icons.date_range_rounded,
              label: (_fromDate == null || _toDate == null)
                  ? 'Khoảng ngày'
                  : '${AppDateUtils.formatVietnameseDate(_fromDate!)} - ${AppDateUtils.formatVietnameseDate(_toDate!)}',
              isActive: _fromDate != null || _toDate != null,
              onTap: _pickDateRange,
              onDelete: (_fromDate != null || _toDate != null)
                  ? () => setState(() {
                        _fromDate = null;
                        _toDate = null;
                      })
                  : null,
            ),
            const SizedBox(width: 8),
            _filterChip(
              icon: Icons.event_seat_rounded,
              label: 'Còn chỗ',
              isActive: _onlyAvailableSeats,
              onTap: () => setState(() => _onlyAvailableSeats = !_onlyAvailableSeats),
              onDelete: _onlyAvailableSeats
                  ? () => setState(() => _onlyAvailableSeats = false)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: 10,
          right: onDelete != null ? 4 : 10,
          top: 7,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.12) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            if (onDelete != null) ...
              [
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa chuyến đi từ ${trip.diemDi} đến ${trip.diemDen}?\n\nHành động này không thể hoàn tác.',
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
