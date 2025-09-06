import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/trip_provider.dart';
import '../providers/booking_provider.dart';
import '../models/trip.dart';
import 'qr_scanner_screen.dart';
import '../providers/socket_provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'driver_start_trip_screen.dart';
import 'driver_completed_trips_screen.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  String _driverName = '';
  String _driverId = '';
  String _selectedFilter = 'all'; // 'all', 'today', 'upcoming', 'completed'
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
      _startLocationStream();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          ),
        ).listen((pos) {
          final socketProvider = Provider.of<SocketProvider>(
            context,
            listen: false,
          );
          if (socketProvider.isConnected) {
            socketProvider.emit('driver_location', {
              'userId': _driverId,
              'lat': pos.latitude,
              'lng': pos.longitude,
            });
          }
        });
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> _loadDriverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString('hoTen')?.trim() ?? 'Tài xế';
      _driverId = prefs.getString('userId') ?? '';
    });
    // Reload trips once driver identity is known to ensure filter works
    if (mounted) {
      try {
        if (_driverId.isNotEmpty) {
          await Provider.of<TripProvider>(
            context,
            listen: false,
          ).loadDriverUpcoming(_driverId);
        } else {
          await Provider.of<TripProvider>(context, listen: false).loadTrips();
        }
      } catch (_) {}
    }
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
            tooltip: 'Lịch sử chuyến',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DriverCompletedTripsScreen(),
              ),
            ),
          ),
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
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final base = _driverScopedBase(tripProvider.trips);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        int allCount = base.length;
        int todayCount = base
            .where(
              (t) =>
                  t.thoiGianKhoiHanh.year == today.year &&
                  t.thoiGianKhoiHanh.month == today.month &&
                  t.thoiGianKhoiHanh.day == today.day,
            )
            .length;
        int upcomingCount = base
            .where((t) => t.thoiGianKhoiHanh.isAfter(now))
            .length;
        int completedCount = base
            .where((t) => (t.gioKetThuc ?? t.thoiGianKhoiHanh).isBefore(now))
            .length;

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
                _buildFilterChip('all', 'Tất cả (' + allCount.toString() + ')'),
                _buildFilterChip(
                  'today',
                  'Hôm nay (' + todayCount.toString() + ')',
                ),
                _buildFilterChip(
                  'upcoming',
                  'Sắp tới (' + upcomingCount.toString() + ')',
                ),
                _buildFilterChip(
                  'completed',
                  'Đã hoàn thành (' + completedCount.toString() + ')',
                ),
              ],
            ),
          ),
        );
      },
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
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_driverId.isNotEmpty) {
                      await Provider.of<TripProvider>(
                        context,
                        listen: false,
                      ).loadDriverUpcoming(_driverId);
                    } else {
                      await Provider.of<TripProvider>(
                        context,
                        listen: false,
                      ).loadTrips();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (_driverId.isNotEmpty) {
              await Provider.of<TripProvider>(
                context,
                listen: false,
              ).loadDriverUpcoming(_driverId);
            } else {
              await Provider.of<TripProvider>(
                context,
                listen: false,
              ).loadTrips();
            }
            await Provider.of<BookingProvider>(
              context,
              listen: false,
            ).loadBookings();
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredTrips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              try {
                final trip = filteredTrips[index];
                final tripBookings = bookingProvider.bookings
                    .where((booking) => booking.tripId == trip.id)
                    .toList();
                return _TripTile(
                  trip: trip,
                  bookingsCount: tripBookings.length,
                  onTap: () => _showTripDetail(trip, tripBookings),
                  onPrepare: () => _openDriverStart(trip),
                  onStart: () => _openDriverStart(trip),
                );
              } catch (e) {
                return ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: const Text('Lỗi hiển thị mục'),
                  subtitle: Text(e.toString()),
                );
              }
            },
          ),
        );
      },
    );
  }

  // Old driver action buttons were replaced by simplified tile actions

  Future<void> _openDriverStart(Trip trip) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DriverStartTripScreen(trip: trip)),
    );
  }

  List<Trip> _driverScopedBase(List<Trip> allTrips) {
    final dn = _driverName.trim().toLowerCase();
    final myTrips = allTrips.where((trip) {
      final name = (trip.taiXe).trim().toLowerCase();
      final idMatch = (trip.taiXeId?.toString() ?? '') == _driverId;
      final nameExact = dn.isNotEmpty && name == dn;
      final nameContains =
          dn.isNotEmpty && (name.contains(dn) || dn.contains(name));
      return idMatch || nameExact || nameContains;
    }).toList();
    return myTrips.isNotEmpty ? myTrips : allTrips;
  }

  List<Trip> _getFilteredTrips(List<Trip> allTrips) {
    // Base theo tài xế (hoặc toàn bộ nếu chưa được gán)
    final base = _driverScopedBase(allTrips);

    List<Trip> result;
    switch (_selectedFilter) {
      case 'today':
        final today = DateTime.now();
        result = base.where((trip) {
          final tripDate = trip.thoiGianKhoiHanh;
          return tripDate.day == today.day &&
              tripDate.month == today.month &&
              tripDate.year == today.year;
        }).toList();

      case 'upcoming':
        final now = DateTime.now();
        result = base.where((trip) {
          final tripDate = trip.thoiGianKhoiHanh;
          return tripDate.isAfter(now);
        }).toList();

      case 'completed':
        final now = DateTime.now();
        result = base.where((trip) {
          final tripDate = trip.gioKetThuc ?? trip.thoiGianKhoiHanh;
          return tripDate.isBefore(now);
        }).toList();

      default:
        // 'Tất cả': hiển thị toàn bộ danh sách (bao gồm đã qua và sắp tới)
        result = List<Trip>.from(base);
    }
    // Sắp xếp theo thời gian khởi hành tăng dần để dễ theo dõi
    result.sort((a, b) => a.thoiGianKhoiHanh.compareTo(b.thoiGianKhoiHanh));
    return result;
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

  // Old large trip card replaced by compact _TripTile

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

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeString;
    }
  }

  String _formatTimeNullable(DateTime? dt) {
    if (dt == null) return 'Chưa xác định';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // Legacy helper removed from new UI

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
                _formatTimeNullable(trip.gioKetThuc),
              ),
              _buildDetailRow(
                'Loại xe:',
                _getVehicleTypeName(trip.loaiXe ?? 'ghe_ngoi'),
              ),
              _buildDetailRow('Biển số:', trip.bienSoXe),
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
          if (trip.thoiGianKhoiHanh.day == DateTime.now().day)
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

  // Passenger list – currently unused in simplified UI
  /* void _showPassengerList(Trip trip, List<dynamic> _) async {
    final resp = await Provider.of<BookingProvider>(
      context,
      listen: false,
    ).fetchTripPassengers(trip.id);
    if (resp['success'] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp['message'] ?? 'Không tải được danh sách')),
      );
      return;
    }
    final data = Map<String, dynamic>.from(resp['data'] ?? {});
    final bookings = List<Map<String, dynamic>>.from(data['bookings'] ?? []);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              int unpaidSeats = 0;
              int paidSeats = 0;
              for (final b in bookings) {
                final count = (b['danhSachGhe'] as List<dynamic>?)?.length ?? 0;
                if (b['trangThaiThanhToan'] == 'da_thanh_toan') {
                  paidSeats += count;
                } else {
                  unpaidSeats += count;
                }
              }
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hành khách • ${trip.diemDi} → ${trip.diemDen}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chưa thanh toán: ' + unpaidSeats.toString() + ' ghế',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Đã thanh toán: ' + paidSeats.toString() + ' ghế',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        final seats = (b['danhSachGhe'] as List<dynamic>).join(
                          ', ',
                        );
                        final paid = b['trangThaiThanhToan'] == 'da_thanh_toan';
                        final checkedIn =
                            b['trangThaiCheckIn'] == 'da_check_in';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: checkedIn
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              checkedIn ? Icons.check : Icons.access_time,
                              color: checkedIn ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(
                            'Vé ' + (b['maVe'] ?? '') + ' • Ghế: ' + seats,
                          ),
                          subtitle: Text(
                            'Khách: ' + (b['userId']?['hoTen'] ?? ''),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: paid
                                ? Center(
                                    child: Text(
                                      'Đã thanh toán',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () async {
                                      final resp =
                                          await Provider.of<BookingProvider>(
                                            context,
                                            listen: false,
                                          ).payBooking(
                                            bookingId:
                                                b['_id']?.toString() ?? '',
                                            method: 'cash',
                                          );
                                      if (resp['success'] == true) {
                                        setModalState(() {
                                          b['trangThaiThanhToan'] =
                                              'da_thanh_toan';
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Xác nhận tiền mặt thành công',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              resp['message'] ?? 'Lỗi xác nhận',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Xác nhận tiền mặt'),
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
        },
      ),
    );
  } */

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen(tripId: '')),
    );
  }

  // Manual booking dialog – currently unused in simplified UI
  /* Future<void> _openMakeBookingDialog(Trip trip) async {
    final seats = trip.danhSachGhe.map((s) => s.tenGhe).toList();
    final selected = <String>{};
    final phoneCtrl = TextEditingController();
    final pickupCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt vé hộ khách'),
        content: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn ghế trống:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: seats.map((g) {
                    // Cho phép chọn ghế bất kỳ (có thể nâng cấp chặn ghế đã đặt sau)
                    final isSel = selected.contains(g);
                    return FilterChip(
                      label: Text(g),
                      selected: isSel,
                      onSelected: (v) =>
                          setS(() => v ? selected.add(g) : selected.remove(g)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại khách',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pickupCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Điểm đón (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selected.isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chọn ghế và nhập SĐT')),
                );
                return;
              }
              Navigator.pop(ctx);
              final body = {
                'tripId': trip.id,
                'danhSachGheDat': selected.toList(),
                'forPhone': phoneCtrl.text.trim(),
                if (pickupCtrl.text.trim().isNotEmpty)
                  'diaChiDon': pickupCtrl.text.trim(),
              };
              final res = await Provider.of<BookingProvider>(
                context,
                listen: false,
              ).createBooking(body);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đặt vé thành công')),
                );
                await Provider.of<BookingProvider>(
                  context,
                  listen: false,
                ).loadBookings();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Đặt thất bại')),
                );
              }
            },
            child: const Text('Tạo vé'),
          ),
        ],
      ),
    );
  } */
}

class _TripTile extends StatelessWidget {
  final Trip trip;
  final int bookingsCount;
  final VoidCallback onTap;
  final VoidCallback onPrepare;
  final VoidCallback onStart;

  const _TripTile({
    required this.trip,
    required this.bookingsCount,
    required this.onTap,
    required this.onPrepare,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        trip.thoiGianKhoiHanh.day == now.day &&
        trip.thoiGianKhoiHanh.month == now.month &&
        trip.thoiGianKhoiHanh.year == now.year;
    final isUpcoming = trip.thoiGianKhoiHanh.isAfter(now);
    final canStart =
        isUpcoming &&
        trip.thoiGianKhoiHanh.difference(now) <= const Duration(minutes: 30);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isToday
                              ? Colors.green
                              : isUpcoming
                              ? Colors.blue
                              : Colors.grey)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: isToday
                      ? Colors.green
                      : isUpcoming
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.diemDi + ' → ' + trip.diemDen,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khởi hành: ' +
                          trip.thoiGianKhoiHanh.hour.toString().padLeft(
                            2,
                            '0',
                          ) +
                          ':' +
                          trip.thoiGianKhoiHanh.minute.toString().padLeft(
                            2,
                            '0',
                          ) +
                          ' • Ghế: ' +
                          (trip.tongSoGhe - trip.soGheTrong).toString() +
                          '/' +
                          trip.tongSoGhe.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: onPrepare,
                          icon: const Icon(Icons.remove_red_eye, size: 18),
                          label: const Text('Chuẩn bị'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: canStart ? onStart : null,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Bắt đầu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
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
}
