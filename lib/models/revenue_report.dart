class RevenueReport {
  final DateTime date;
  final int totalBookings;
  final int totalRevenue;
  final int totalRefunds;
  final int netRevenue;
  final Map<String, int> revenueByRoute;
  final Map<String, int> bookingsByRoute;

  RevenueReport({
    required this.date,
    required this.totalBookings,
    required this.totalRevenue,
    required this.totalRefunds,
    required this.netRevenue,
    required this.revenueByRoute,
    required this.bookingsByRoute,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) {
    return RevenueReport(
      date: DateTime.parse(json['date']),
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      totalRefunds: json['totalRefunds'] ?? 0,
      netRevenue: json['netRevenue'] ?? 0,
      revenueByRoute: Map<String, int>.from(json['revenueByRoute'] ?? {}),
      bookingsByRoute: Map<String, int>.from(json['bookingsByRoute'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'totalRefunds': totalRefunds,
      'netRevenue': netRevenue,
      'revenueByRoute': revenueByRoute,
      'bookingsByRoute': bookingsByRoute,
    };
  }
}

class MonthlyReport {
  final int year;
  final int month;
  final List<RevenueReport> dailyReports;
  final int totalRevenue;
  final int totalBookings;
  final double averageDailyRevenue;
  final String topRoute;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.dailyReports,
    required this.totalRevenue,
    required this.totalBookings,
    required this.averageDailyRevenue,
    required this.topRoute,
  });

  factory MonthlyReport.fromDailyReports(int year, int month, List<RevenueReport> reports) {
    final totalRevenue = reports.fold(0, (sum, report) => sum + report.netRevenue);
    final totalBookings = reports.fold(0, (sum, report) => sum + report.totalBookings);
    final averageDailyRevenue = reports.isNotEmpty ? totalRevenue / reports.length : 0.0;
    
    // Find top route
    final routeRevenue = <String, int>{};
    for (final report in reports) {
      report.revenueByRoute.forEach((route, revenue) {
        routeRevenue[route] = (routeRevenue[route] ?? 0) + revenue;
      });
    }
    
    final topRoute = routeRevenue.isNotEmpty 
        ? routeRevenue.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'Không có dữ liệu';

    return MonthlyReport(
      year: year,
      month: month,
      dailyReports: reports,
      totalRevenue: totalRevenue,
      totalBookings: totalBookings,
      averageDailyRevenue: averageDailyRevenue,
      topRoute: topRoute,
    );
  }

  String get monthName {
    const months = [
      '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return months[month];
  }
}

class CustomerStats {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int totalTrips;
  final int totalSpent;
  final DateTime lastTripDate;
  final String favoriteRoute;
  final String customerTier; // 'bronze', 'silver', 'gold', 'platinum'

  CustomerStats({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.totalTrips,
    required this.totalSpent,
    required this.lastTripDate,
    required this.favoriteRoute,
    required this.customerTier,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      totalTrips: json['totalTrips'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      lastTripDate: DateTime.parse(json['lastTripDate']),
      favoriteRoute: json['favoriteRoute'] ?? '',
      customerTier: json['customerTier'] ?? 'bronze',
    );
  }

  String get tierDisplayName {
    switch (customerTier) {
      case 'bronze':
        return 'Đồng';
      case 'silver':
        return 'Bạc';
      case 'gold':
        return 'Vàng';
      case 'platinum':
        return 'Bạch kim';
      default:
        return 'Chưa xếp hạng';
    }
  }

  String get tierColor {
    switch (customerTier) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#808080';
    }
  }
}
