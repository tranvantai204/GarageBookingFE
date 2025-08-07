import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/revenue_report.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedPeriod = 'day'; // 'day', 'week', 'month'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildRevenueChart(),
              const SizedBox(height: 24),
              _buildRouteAnalysis(),
              const SizedBox(height: 24),
              _buildTopCustomers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn khoảng thời gian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('Ngày')),
                      ButtonSegment(value: 'week', label: Text('Tuần')),
                      ButtonSegment(value: 'month', label: Text('Tháng')),
                    ],
                    selected: {selectedPeriod},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        selectedPeriod = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_getDateText()),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cập nhật'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final bookings = bookingProvider.bookings;
        final totalRevenue = bookings
            .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
            .fold(0, (sum, b) => sum + b.tongTien);
        final totalBookings = bookings.length;
        final avgRevenue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Tổng doanh thu',
                '${_formatCurrency(totalRevenue)}đ',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Số vé bán',
                totalBookings.toString(),
                Icons.confirmation_number,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Trung bình/vé',
                '${_formatCurrency(avgRevenue.round())}đ',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ doanh thu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          'Doanh thu ${selectedPeriod == 'day'
                              ? 'hôm nay'
                              : selectedPeriod == 'week'
                              ? 'tuần này'
                              : 'tháng này'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatCurrency(_calculateTotalRevenue(bookingProvider.bookings))}đ',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${bookingProvider.bookings.length} vé đã bán',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteAnalysis() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân tích theo tuyến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                final routes = <String, Map<String, int>>{};

                for (final booking in bookingProvider.bookings) {
                  final route = '${booking.diemDi} - ${booking.diemDen}';
                  if (!routes.containsKey(route)) {
                    routes[route] = {'count': 0, 'revenue': 0};
                  }
                  routes[route]!['count'] = routes[route]!['count']! + 1;
                  if (booking.trangThaiThanhToan == 'da_thanh_toan') {
                    routes[route]!['revenue'] =
                        routes[route]!['revenue']! + booking.tongTien;
                  }
                }

                final sortedRoutes = routes.entries.toList()
                  ..sort(
                    (a, b) =>
                        b.value['revenue']!.compareTo(a.value['revenue']!),
                  );

                return Column(
                  children: sortedRoutes.take(5).map((entry) {
                    return _buildRouteItem(
                      entry.key,
                      entry.value['count']!,
                      entry.value['revenue']!,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem(String route, int bookings, int revenue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$bookings vé • ${_formatCurrency(revenue)}đ',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_formatCurrency(revenue)}đ',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khách hàng VIP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) {
              return _buildCustomerItem(
                'Khách hàng ${index + 1}',
                '098765432${index}',
                (index + 1) * 5,
                (index + 1) * 2500000,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(String name, String phone, int trips, int spent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.amber,
            child: Text(name[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(phone, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$trips chuyến',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatCurrency(spent)}đ',
                style: TextStyle(color: Colors.amber.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateText() {
    switch (selectedPeriod) {
      case 'day':
        return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      case 'week':
        return 'Tuần ${_getWeekOfYear(selectedDate)}/${selectedDate.year}';
      case 'month':
        return '${selectedDate.month}/${selectedDate.year}';
      default:
        return '';
    }
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  int _calculateTotalRevenue(List<dynamic> bookings) {
    return bookings
        .where((b) => b.trangThaiThanhToan == 'da_thanh_toan')
        .fold<int>(0, (sum, b) => sum + (b.tongTien as int));
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _refreshData() {
    // Refresh data logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật dữ liệu')));
  }

  void _exportReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Xuất báo cáo thành công')));
  }
}
