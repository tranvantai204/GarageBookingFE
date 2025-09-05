import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../providers/booking_provider.dart';
import 'qr_scanner_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/socket_provider.dart';
// Prefer Google Maps if API key is provided; otherwise fall back to OpenStreetMap via flutter_map
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show
        PanGestureRecognizer,
        ScaleGestureRecognizer,
        TapGestureRecognizer,
        VerticalDragGestureRecognizer,
        OneSequenceGestureRecognizer;

class DriverStartTripScreen extends StatefulWidget {
  final Trip trip;
  const DriverStartTripScreen({super.key, required this.trip});

  @override
  State<DriverStartTripScreen> createState() => _DriverStartTripScreenState();
}

class _DriverStartTripScreenState extends State<DriverStartTripScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  bool _active = false;
  StreamSubscription<Position>? _posSub;
  String _driverId = '';
  static const String _prefActiveKey = 'driver_trip_active';
  static const String _prefActiveTripKey = 'driver_trip_id';
  // Map state
  int _tabIndex = 0; // 0=Map, 1=Passengers
  GoogleMapController? _mapController;
  Marker? _driverMarker;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _trackPoints = [];
  // Google Maps custom style for cleaner look
  static const String _googleMapStyle =
      '[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},{"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},{"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},{"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},{"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},{"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},{"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}]';
  // OSM fallback
  final fm.MapController _osmController = fm.MapController();
  final List<fm.Polyline> _osmPolylines = [];
  final List<fm.Marker> _osmMarkers = [];

  @override
  void initState() {
    super.initState();
    _load();
    _restoreActiveIfNeeded();
  }

  Future<void> _finishTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('userId') ?? '';
      final socketProvider = Provider.of<SocketProvider>(
        context,
        listen: false,
      );
      if (socketProvider.isConnected) {
        socketProvider.emit('trip_ended', {
          'tripId': widget.trip.id,
          'driverId': driverId,
        });
      }
    } catch (_) {}
    await _stopTracking();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã hoàn thành chuyến')));
  }

  Future<void> _load() async {
    final resp = await Provider.of<BookingProvider>(
      context,
      listen: false,
    ).fetchTripPassengers(widget.trip.id);
    if (resp['success'] == true) {
      final data = resp['data'] as Map<String, dynamic>;
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(data['bookings'] ?? []);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Không tải được dữ liệu')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Không tắt theo dõi nếu đang active; lần sau mở màn sẽ tự khôi phục
    if (!_active) {
      _posSub?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final totalSeats = trip.tongSoGhe;
    final paidSeats = _bookings
        .where((b) => b['trangThaiThanhToan'] == 'da_thanh_toan')
        .fold<int>(0, (sum, b) => sum + (b['danhSachGhe'] as List).length);
    final checkedInSeats = _bookings
        .where((b) => b['trangThaiCheckIn'] == 'da_check_in')
        .fold<int>(0, (sum, b) => sum + (b['danhSachGhe'] as List).length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bắt đầu chuyến'),
        actions: [
          if (_active)
            TextButton.icon(
              onPressed: _finishTrip,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Hoàn thành',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tabIndex,
              children: [
                _buildMapTab(trip, totalSeats, paidSeats, checkedInSeats),
                _buildPassengersTab(
                  trip,
                  totalSeats,
                  paidSeats,
                  checkedInSeats,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Hành khách',
          ),
        ],
      ),
      floatingActionButton: _loading
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _toggleTripActive,
                  icon: Icon(_active ? Icons.stop : Icons.play_arrow),
                  label: Text(_active ? 'Kết thúc' : 'Bắt đầu'),
                  backgroundColor: _active ? Colors.red : null,
                ),
                const SizedBox(height: 8),
                if (_active)
                  FloatingActionButton.extended(
                    onPressed: _togglePause,
                    icon: const Icon(Icons.pause_circle),
                    label: const Text('Tạm dừng/tiếp tục'),
                    backgroundColor: Colors.orange,
                  ),
                const SizedBox(height: 8),
                if (_active)
                  FloatingActionButton.extended(
                    onPressed: _confirmFinishTrip,
                    icon: const Icon(Icons.flag),
                    label: const Text('Hoàn thành chuyến'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
    );
  }

  Widget _buildMapTab(
    Trip trip,
    int totalSeats,
    int soldSeats,
    int checkedInSeats,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await _buildAndDrawRoute();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tripHeader(trip),
          const SizedBox(height: 12),
          _statsRow(totalSeats, soldSeats, checkedInSeats),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMapWidget(),
            ),
          ),
          const SizedBox(height: 12),
          _seatMapSection(),
        ],
      ),
    );
  }

  Widget _buildPassengersTab(
    Trip trip,
    int totalSeats,
    int soldSeats,
    int checkedInSeats,
  ) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tripHeader(trip),
          const SizedBox(height: 12),
          _statsRow(totalSeats, soldSeats, checkedInSeats),
          const SizedBox(height: 12),
          _passengerListSection(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openGoogleMapsRoute,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Mở Google Maps'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRScannerScreen(tripId: widget.trip.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét QR check-in'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _tripHeader(Trip trip) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_bus, color: Colors.blue),
        title: Text('${trip.diemDi} → ${trip.diemDen}'),
        subtitle: Text(
          '${trip.ngayKhoiHanh} • ${trip.gioKhoiHanh} • ${trip.bienSoXe}',
        ),
      ),
    );
  }

  Widget _statsRow(int total, int sold, int checkedIn) {
    return Row(
      children: [
        Expanded(
          child: _statCard('Tổng ghế', '$total', Icons.event_seat, Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'Đã bán',
            '$sold',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'Đã check-in',
            '$checkedIn',
            Icons.verified,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seatMapSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sơ đồ ghế',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _buildSeatChips()),
            const SizedBox(height: 8),
            Row(
              children: [
                _legend(Colors.grey.shade300, 'Trống'),
                const SizedBox(width: 12),
                _legend(Colors.orange.shade100, 'Đã bán'),
                const SizedBox(width: 12),
                _legend(Colors.green.shade100, 'Đã check-in'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSeatChips() {
    // status map from bookings
    final seatStatus = <String, String>{}; // 'checked' | 'booked'
    for (final b in _bookings) {
      final seats = List<String>.from(b['danhSachGhe'] ?? []);
      final isCheckedIn = b['trangThaiCheckIn'] == 'da_check_in';
      for (final s in seats) {
        seatStatus[s] = isCheckedIn ? 'checked' : 'booked';
      }
    }
    final List<Widget> chips = [];
    for (final seat in widget.trip.danhSachGhe) {
      final code = seat.tenGhe;
      final status = seatStatus[code];
      Color bg;
      Color iconColor;
      IconData icon;
      if (status == 'checked') {
        bg = Colors.green.shade100;
        iconColor = Colors.green;
        icon = Icons.verified;
      } else if (status == 'booked') {
        bg = Colors.orange.shade100;
        iconColor = Colors.orange;
        icon = Icons.event_seat;
      } else {
        bg = Colors.grey.shade300;
        iconColor = Colors.grey.shade700;
        icon = Icons.event_seat;
      }
      chips.add(
        Chip(
          label: Text(code),
          avatar: Icon(icon, size: 14, color: iconColor),
          backgroundColor: bg,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      );
    }
    if (chips.isEmpty)
      return [const Text('Chưa cấu hình sơ đồ ghế cho chuyến')];
    return chips;
  }

  Widget _passengerListSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách hành khách',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._bookings.map((b) {
              final seats = (b['danhSachGhe'] as List).join(', ');
              final checked = b['trangThaiCheckIn'] == 'da_check_in';
              final paid = b['trangThaiThanhToan'] == 'da_thanh_toan';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: paid
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    paid ? Icons.verified : Icons.payments_outlined,
                    color: paid ? Colors.green : Colors.red,
                  ),
                ),
                title: Text('Vé ${b['maVe'] ?? ''} • Ghế: $seats'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khách: ${b['userId']?['hoTen'] ?? ''}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                          ),
                          backgroundColor: paid
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          labelStyle: TextStyle(
                            color: paid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 6),
                        Chip(
                          label: Text(
                            checked ? 'Đã check-in' : 'Chưa check-in',
                          ),
                          backgroundColor: checked
                              ? Colors.blue.shade50
                              : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: checked ? Colors.blue : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // _routeSection removed in favor of in-app Google Map tab

  // _routeRow removed

  Future<void> _openGoogleMapsRoute() async {
    final trip = widget.trip;
    final origin = Uri.encodeComponent(trip.diemDi);
    final destination = Uri.encodeComponent(trip.diemDen);
    final waypoints = _bookings
        .map((b) => b['diaChiDon'])
        .where((e) => e != null && (e as String).trim().isNotEmpty)
        .cast<String>()
        .map(Uri.encodeComponent)
        .join('%7C');
    final url = waypoints.isEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving'
        : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps')),
      );
    }
  }

  Future<void> _toggleTripActive() async {
    if (!_active) {
      await _startTracking(resume: false);
    } else {
      await _stopTracking();
    }
  }

  Future<void> _startTracking({required bool resume}) async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền vị trí để bắt đầu chuyến')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _driverId = prefs.getString('userId') ?? '';
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);

    // Cập nhật vị trí ngay lập tức để người dùng thấy hiệu ứng
    try {
      final cur = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      final first = LatLng(cur.latitude, cur.longitude);
      _trackPoints.clear();
      _trackPoints.add(first);
      _polylines.removeWhere((p) => p.polylineId.value == 'live');
      _polylines.add(
        const Polyline(
          polylineId: PolylineId('live'),
          points: [],
          color: Colors.transparent,
          width: 1,
        ),
      );
      // set marker + camera
      _driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: first,
        infoWindow: const InfoWindow(title: 'Vị trí của tôi'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: first, zoom: 16, tilt: 40),
        ),
      );
      try {
        _osmController.move(ll.LatLng(first.latitude, first.longitude), 16);
      } catch (_) {}
      setState(() {});
    } catch (_) {}

    _posSub?.cancel();
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          ),
        ).listen((pos) {
          if (socketProvider.isConnected) {
            socketProvider.emit('driver_location', {
              'userId': _driverId,
              'lat': pos.latitude,
              'lng': pos.longitude,
              'ts': DateTime.now().millisecondsSinceEpoch,
            });
            socketProvider.emit('trip_started', {
              'tripId': widget.trip.id,
              'driverId': _driverId,
            });
          }
          // Cập nhật đường đi realtime
          final current = LatLng(pos.latitude, pos.longitude);
          if (_trackPoints.isEmpty ||
              _trackPoints.last.latitude != current.latitude ||
              _trackPoints.last.longitude != current.longitude) {
            _trackPoints.add(current);
            if (_trackPoints.length > 200) _trackPoints.removeAt(0);
            _polylines.removeWhere((p) => p.polylineId.value == 'live');
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('live'),
                points: List<LatLng>.from(_trackPoints),
                color: Colors.blueAccent,
                width: 5,
              ),
            );
            // OSM fallback: vẽ track
            _osmPolylines.removeWhere((p) => p.color == Colors.blueAccent);
            _osmPolylines.add(
              fm.Polyline(
                points: _trackPoints
                    .map((p) => ll.LatLng(p.latitude, p.longitude))
                    .toList(),
                strokeWidth: 5,
                color: Colors.blueAccent,
              ),
            );
          }

          final newMarker = Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow: const InfoWindow(title: 'Vị trí của tôi'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          );
          setState(() => _driverMarker = newMarker);
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 16,
                tilt: 40,
              ),
            ),
          );
          // OSM: move camera theo
          try {
            _osmController.move(ll.LatLng(pos.latitude, pos.longitude), 16);
          } catch (_) {}
        });

    await prefs.setBool(_prefActiveKey, true);
    await prefs.setString(_prefActiveTripKey, widget.trip.id);
    setState(() => _active = true);
    if (!mounted) return;
    if (!resume) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu chuyến - đang cập nhật vị trí'),
        ),
      );
    }
  }

  Future<void> _togglePause() async {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    socketProvider.emit('trip_paused', {
      'tripId': widget.trip.id,
      'driverId': _driverId,
      'paused': true,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi trạng thái tạm dừng tới admin')),
    );
  }

  Future<void> _stopTracking() async {
    await _posSub?.cancel();
    _posSub = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefActiveKey);
    await prefs.remove(_prefActiveTripKey);
    setState(() => _active = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã kết thúc chuyến')));
  }

  Future<void> _confirmFinishTrip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hoàn thành chuyến'),
        content: const Text(
          'Bạn có chắc chắn hoàn thành? Hệ thống sẽ ghi nhận và kết thúc chuyến.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final socketProvider = Provider.of<SocketProvider>(
        context,
        listen: false,
      );
      socketProvider.emit('trip_ended', {
        'tripId': widget.trip.id,
        'driverId': _driverId,
      });
      await _stopTracking();
    }
  }

  Future<void> _restoreActiveIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final wasActive = prefs.getBool(_prefActiveKey) ?? false;
    final lastTripId = prefs.getString(_prefActiveTripKey);
    if (wasActive && lastTripId == widget.trip.id) {
      await _startTracking(resume: true);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
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

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _buildAndDrawRoute() async {
    try {
      final origin = widget.trip.diemDi;
      final dest = widget.trip.diemDen;
      final waypoints = _bookings
          .map((b) => b['diaChiDon'])
          .where((e) => e != null && (e as String).trim().isNotEmpty)
          .cast<String>()
          .toList();

      // Fallback: place simple markers when no API key or failure
      final originPos = await _geocode(origin);
      final destPos = await _geocode(dest);
      final wpPositions = <LatLng>[];
      for (final w in waypoints) {
        wpPositions.add(await _geocode(w));
      }
      setState(() {
        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId('origin'),
              position: originPos,
              infoWindow: const InfoWindow(title: 'Điểm đi'),
            ),
          )
          ..add(
            Marker(
              markerId: const MarkerId('dest'),
              position: destPos,
              infoWindow: const InfoWindow(title: 'Điểm đến'),
            ),
          );
        for (int i = 0; i < wpPositions.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId('wp$i'),
              position: wpPositions[i],
              infoWindow: InfoWindow(title: 'Đón: ${waypoints[i]}'),
            ),
          );
        }
      });

      // Try Directions API if key available via String.fromEnvironment
      const envKey = String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: '',
      );
      if (envKey.isEmpty) {
        // Build OSM overlays instead
        await _buildOsmOverlays(originPos, destPos, wpPositions);
        return;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${Uri.encodeComponent(origin)}&destination=${Uri.encodeComponent(dest)}&waypoints=${waypoints.map(Uri.encodeComponent).join('|')}&mode=driving&key=$envKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(resp.body);
      if (data['status'] != 'OK') return;
      _polylines.clear();
      int idx = 0;
      for (final route in data['routes']) {
        for (final leg in route['legs']) {
          for (final step in leg['steps']) {
            final points = _decodePoly(step['polyline']['points']);
            _polylines.add(
              Polyline(
                polylineId: PolylineId('r${idx++}'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            );
          }
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Future<LatLng> _geocode(String address) async {
    try {
      // 1) Nếu address có dạng "lat,lng" → parse trực tiếp
      final m = RegExp(
        r"([-+]?[0-9]*\.?[0-9]+)\s*,\s*([-+]?[0-9]*\.?[0-9]+)",
      ).firstMatch(address);
      if (m != null) {
        final lat = double.parse(m.group(1)!);
        final lng = double.parse(m.group(2)!);
        return LatLng(lat, lng);
      }

      // 2) Thử Nominatim (OSM) miễn phí để geocode địa chỉ văn bản
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
          .replace(
            queryParameters: {
              'q': address,
              'format': 'json',
              'limit': '1',
              'countrycodes': 'vn',
            },
          );
      final resp = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'GarageBookingApp/1.0 (contact: support@example.com)',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final arr = jsonDecode(resp.body) as List<dynamic>;
        if (arr.isNotEmpty) {
          final obj = arr.first as Map<String, dynamic>;
          final lat = double.tryParse(obj['lat']?.toString() ?? '');
          final lon = double.tryParse(obj['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}

    // 3) Fallback: vị trí hiện tại của thiết bị nếu có
    try {
      final cur = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      return LatLng(cur.latitude, cur.longitude);
    } catch (_) {}

    // 4) Cuối cùng: điểm mặc định (TP.HCM)
    return const LatLng(10.762622, 106.660172);
  }

  Future<void> _buildOsmOverlays(
    LatLng originPos,
    LatLng destPos,
    List<LatLng> wpPositions,
  ) async {
    _osmMarkers
      ..clear()
      ..add(
        fm.Marker(
          point: ll.LatLng(originPos.latitude, originPos.longitude),
          child: const Icon(Icons.flag, color: Colors.blue),
        ),
      )
      ..add(
        fm.Marker(
          point: ll.LatLng(destPos.latitude, destPos.longitude),
          child: const Icon(Icons.flag, color: Colors.red),
        ),
      );
    for (final p in wpPositions) {
      _osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(p.latitude, p.longitude),
          child: const Icon(Icons.place, color: Colors.orange),
        ),
      );
    }
    _osmPolylines
      ..clear()
      ..add(
        fm.Polyline(
          points: [
            ll.LatLng(originPos.latitude, originPos.longitude),
            ...wpPositions.map((p) => ll.LatLng(p.latitude, p.longitude)),
            ll.LatLng(destPos.latitude, destPos.longitude),
          ],
          strokeWidth: 4,
          color: Colors.blue,
        ),
      );
    setState(() {});
  }

  Widget _buildMapWidget() {
    // Use Google Maps only when explicitly enabled via --dart-define=USE_GOOGLE_MAPS=true
    const useGoogle = bool.fromEnvironment(
      'USE_GOOGLE_MAPS',
      defaultValue: false,
    );
    final hasKey = useGoogle;
    if (hasKey) {
      return GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(10.762622, 106.660172),
          zoom: 12,
        ),
        onMapCreated: (c) async {
          _mapController = c;
          // Apply custom dark style for a modern look
          try {
            await _mapController?.setMapStyle(_googleMapStyle);
          } catch (_) {}
          await _buildAndDrawRoute();
        },
        polylines: _polylines,
        markers: _markers.union({if (_driverMarker != null) _driverMarker!}),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        buildingsEnabled: true,
        trafficEnabled: false,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
          Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
          Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer(),
          ),
        },
      );
    }
    // OSM fallback (no key required)
    return fm.FlutterMap(
      mapController: _osmController,
      options: fm.MapOptions(
        initialCenter: const ll.LatLng(10.762622, 106.660172),
        initialZoom: 12,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all,
        ),
        onMapReady: () async {
          try {
            await _buildAndDrawRoute();
          } catch (_) {}
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        fm.PolylineLayer(polylines: _osmPolylines),
        fm.MarkerLayer(markers: _osmMarkers),
      ],
    );
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}
