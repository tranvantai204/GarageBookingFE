import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/socket_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/user_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_users_screen.dart';
import 'create_trip_screen.dart';
import 'revenue_report_screen.dart';
import 'vehicle_management_screen.dart';
import 'price_management_screen.dart';
// Screens imported on demand in navigation methods
// import 'overdue_bookings_screen.dart';
// import 'voucher_management_screen.dart';
import 'system_settings_screen.dart';
import 'vip_customers_screen.dart';
import 'broadcast_notification_screen.dart';
import 'notifications_center_screen.dart';
import 'overdue_bookings_screen.dart';
import 'voucher_management_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_driver_feedbacks_screen.dart';
import 'drivers_tracking_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _autoTimer;
  void _bindSocket() {
    final socket = Provider.of<SocketProvider>(context, listen: false);
    socket.off('trip_status_update');
    socket.on('trip_status_update', (data) {
      _loadData();
      if (!mounted) return;
      final status = data['status'];
      final tripId = data['tripId'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trạng thái chuyến $tripId: $status')),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // Gọi sau khi build xong để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _bindSocket();
    });
    // Tự động refresh mỗi 10s
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    try {
      final socket = Provider.of<SocketProvider>(context, listen: false);
      socket.off('trip_status_update');
    } catch (_) {}
    super.dispose();
  }

  void _loadData() {
    if (mounted) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
      Provider.of<TripProvider>(context, listen: false).loadTrips();
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildModernHeader(),

                  const SizedBox(height: 24),

                  // Statistics Cards
                  _buildStatisticsCards(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  // Management Sections
                  _buildManagementSections(),

                  const SizedBox(height: 24),

                  // Recent Activities
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed unused legacy header

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hệ thống quản lý nhà xe Hà Phương',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  'Hôm nay',
                  '${DateTime.now().day}/${DateTime.now().month}',
                  Icons.today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderStat(
                  'Thời gian',
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderStat('Trạng thái', 'Online', Icons.wifi),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer3<BookingProvider, TripProvider, UserProvider>(
      builder: (context, bookingProvider, tripProvider, userProvider, child) {
        final totalBookings = bookingProvider.bookings.length;
        final totalTrips = tripProvider.trips.length;
        final totalUsers = userProvider.users.length;
        final totalDrivers = userProvider.drivers.length;
        final paidBookings = bookingProvider.bookings
            .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
            .length;
        final totalRevenue = bookingProvider.bookings
            .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
            .fold(0, (sum, b) => sum + b.tongTien);

        final items = <Widget>[
          _buildMetricCard(
            'Tổng vé đặt',
            totalBookings.toString(),
            Icons.confirmation_number,
            Colors.blue,
          ),
          _buildMetricCard(
            'Chuyến đi',
            totalTrips.toString(),
            Icons.directions_bus,
            Colors.green,
          ),
          _buildMetricCard(
            'Người dùng',
            totalUsers.toString(),
            Icons.people,
            Colors.purple,
          ),
          _buildMetricCard(
            'Tài xế',
            totalDrivers.toString(),
            Icons.drive_eta,
            Colors.orange,
          ),
          _buildMetricCard(
            'Đã thanh toán',
            paidBookings.toString(),
            Icons.payment,
            Colors.teal,
          ),
          _buildMetricCard(
            'Doanh thu',
            '${_formatCurrency(totalRevenue)}đ',
            Icons.monetization_on,
            Colors.red,
          ),
        ];

        final width = MediaQuery.of(context).size.width;
        final crossAxisCount = width < 360 ? 2 : 3;
        final childAspectRatio = crossAxisCount == 2 ? 1.05 : 0.9;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: items,
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Deprecated: kept during refactor; removed to avoid lint warning

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Quản lý vé đặt',
                'Xem và quản lý tất cả vé đã đặt',
                Icons.receipt_long,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminBookingsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Quản lý chuyến đi',
                'Xem chi tiết các chuyến đi và xe',
                Icons.directions_bus,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminTripsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Theo dõi chuyến',
                'Vị trí tài xế realtime',
                Icons.map,
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriversTrackingScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Quản lý người dùng',
                'Quản lý tài khoản và phân quyền',
                Icons.people,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Tạo chuyến đi mới',
                'Thêm chuyến đi mới vào hệ thống',
                Icons.add_circle,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTripScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quản lý hệ thống',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildManagementCard(
              'Báo cáo doanh thu',
              'Xem thống kê thu chi',
              Icons.analytics,
              Colors.green,
              () => _navigateToRevenueReport(),
            ),
            _buildManagementCard(
              'Quản lý đội xe',
              'Xe và tài xế',
              Icons.directions_bus,
              Colors.blue,
              () => _navigateToVehicleManagement(),
            ),
            _buildManagementCard(
              'Cài đặt giá vé',
              'Quản lý giá theo tuyến',
              Icons.attach_money,
              Colors.orange,
              () => _navigateToPriceManagement(),
            ),
            _buildManagementCard(
              'Thông báo',
              'Gửi tin đến khách hàng',
              Icons.notifications,
              Colors.purple,
              () => _navigateToNotifications(),
            ),
            _buildManagementCard(
              'Vé quá hạn',
              'Danh sách vé đã quá hạn',
              Icons.warning_amber,
              Colors.red,
              () => _navigateToOverdueBookings(),
            ),
            _buildManagementCard(
              'Voucher',
              'Quản lý voucher khuyến mãi',
              Icons.card_giftcard,
              Colors.pink,
              () => _navigateToVoucherManagement(),
            ),
            _buildManagementCard(
              'Hoàn tiền',
              'Duyệt yêu cầu hủy/hoàn',
              Icons.undo,
              Colors.teal,
              () => _navigateToRefunds(),
            ),
            _buildManagementCard(
              'Khách hàng VIP',
              'Chương trình loyalty',
              Icons.star,
              Colors.amber,
              () => _navigateToCustomerManagement(),
            ),
            _buildManagementCard(
              'Cài đặt hệ thống',
              'Cấu hình app',
              Icons.settings,
              Colors.grey,
              () => _navigateToSystemSettings(),
            ),
            _buildManagementCard(
              'Đánh giá tài xế',
              'Xem/duyệt đánh giá',
              Icons.reviews,
              Colors.indigo,
              () => _navigateToDriverFeedbacks(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToRevenueReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RevenueReportScreen()),
    );
  }

  void _navigateToVehicleManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehicleManagementScreen()),
    );
  }

  void _navigateToPriceManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PriceManagementScreen()),
    );
  }

  void _navigateToNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('Gửi thông báo (Broadcast)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BroadcastNotificationScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Hộp thư thông báo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsCenterScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCustomerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VipCustomersScreen()),
    );
  }

  void _navigateToSystemSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SystemSettingsScreen()),
    );
  }

  void _navigateToOverdueBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OverdueBookingsScreen()),
    );
  }

  void _navigateToVoucherManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoucherManagementScreen()),
    );
  }

  void _navigateToRefunds() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminRefundsScreen()),
    );
  }

  void _navigateToDriverFeedbacks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminDriverFeedbacksScreen(),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final recentBookings = bookingProvider.bookings.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: recentBookings.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Chưa có hoạt động nào')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentBookings.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final booking = recentBookings[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                booking.trangThaiThanhToan == 'da_thanh_toan'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              Icons.confirmation_number,
                              color:
                                  booking.trangThaiThanhToan == 'da_thanh_toan'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          title: Text('Vé ${booking.maVe}'),
                          subtitle: Text(
                            'Ghế: ${booking.danhSachGhe.join(", ")} • ${_formatCurrency(booking.tongTien)}đ',
                          ),
                          trailing: Text(
                            '${booking.createdAt.day}/${booking.createdAt.month}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
