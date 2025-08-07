import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi sau khi build xong để tránh setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý hệ thống đặt vé xe khách',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

        return Column(
          children: [
            // First row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng vé đặt',
                    totalBookings.toString(),
                    Icons.confirmation_number,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Chuyến đi',
                    totalTrips.toString(),
                    Icons.directions_bus,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Người dùng',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Tài xế',
                    totalDrivers.toString(),
                    Icons.drive_eta,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Second row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Đã thanh toán',
                    paidBookings.toString(),
                    Icons.payment,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Doanh thu',
                    '${_formatCurrency(totalRevenue)}đ',
                    Icons.monetization_on,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // Empty space
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // Empty space
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
  }

  void _navigateToCustomerManagement() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
  }

  void _navigateToSystemSettings() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
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
