import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../models/trip.dart';

class DriverCompletedTripsScreen extends StatelessWidget {
  const DriverCompletedTripsScreen({super.key});

  List<Trip> _completedTripsForDriver(
    List<Trip> all,
    String driverName,
    String driverId,
  ) {
    final now = DateTime.now();
    return all
        .where(
          (t) =>
              (t.taiXe == driverName || t.taiXeId == driverId) &&
              t.thoiGianKhoiHanh.isBefore(now),
        )
        .toList()
      ..sort((a, b) => b.thoiGianKhoiHanh.compareTo(a.thoiGianKhoiHanh));
  }

  Future<void> _openPassengers(BuildContext context, Trip trip) async {
    final resp = await Provider.of<BookingProvider>(
      context,
      listen: false,
    ).fetchTripPassengers(trip.id);
    if (resp['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resp['message'] ?? 'Không tải được danh sách hành khách',
          ),
        ),
      );
      return;
    }
    final data = resp['data'] as Map<String, dynamic>;
    final bookings = List<Map<String, dynamic>>.from(data['bookings'] ?? []);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return ListView.builder(
            controller: controller,
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              final seats = (b['danhSachGhe'] as List).join(', ');
              final checked = b['trangThaiCheckIn'] == 'da_check_in';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: checked
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  child: Icon(
                    checked ? Icons.check : Icons.access_time,
                    color: checked ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text('Vé ${b['maVe'] ?? ''} • Ghế: $seats'),
                subtitle: Text('Khách: ${b['userId']?['hoTen'] ?? ''}'),
                trailing: Text(checked ? 'Đã check-in' : 'Chưa'),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chuyến đã hoàn thành')),
      body: Consumer2<TripProvider, BookingProvider>(
        builder: (context, tripProvider, bookingProvider, child) {
          final trips = tripProvider.trips;
          final driverName =
              ''; // not needed for filter here if provider already scoped; keep empty
          final driverId = '';
          final completed =
              trips
                  .where((t) => t.thoiGianKhoiHanh.isBefore(DateTime.now()))
                  .toList()
                ..sort(
                  (a, b) => b.thoiGianKhoiHanh.compareTo(a.thoiGianKhoiHanh),
                );

          if (completed.isEmpty) {
            return const Center(child: Text('Chưa có chuyến hoàn thành'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Provider.of<TripProvider>(
                context,
                listen: false,
              ).loadTrips();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trip = completed[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.done, color: Colors.green),
                    title: Text('${trip.diemDi} → ${trip.diemDen}'),
                    subtitle: Text(
                      '${trip.ngayKhoiHanh} • ${trip.gioKhoiHanh} • ${trip.bienSoXe}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _openPassengers(context, trip),
                      child: const Text('Hành khách'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
