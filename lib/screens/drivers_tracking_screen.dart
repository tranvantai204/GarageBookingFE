import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import '../providers/socket_provider.dart';

class DriversTrackingScreen extends StatefulWidget {
  const DriversTrackingScreen({super.key});

  @override
  State<DriversTrackingScreen> createState() => _DriversTrackingScreenState();
}

class _DriversTrackingScreenState extends State<DriversTrackingScreen> {
  final Map<String, Map<String, dynamic>> _drivers =
      {}; // userId -> {lat,lng,ts}
  final Map<String, List<LatLng>> _tracks =
      {}; // Google Map polylines per driver
  final Map<String, List<ll.LatLng>> _tracksOsm =
      {}; // OSM polylines per driver

  GoogleMapController? _gController;
  final fm.MapController _osmController = fm.MapController();
  int _tab = 0; // 0=Map, 1=List

  @override
  void initState() {
    super.initState();
    final socket = Provider.of<SocketProvider>(context, listen: false);
    socket.off('driver_location_update');
    socket.on('driver_location_update', (data) {
      final userId = data['userId']?.toString() ?? '';
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      final ts = data['ts'] ?? DateTime.now().millisecondsSinceEpoch;
      if (userId.isEmpty || lat == null || lng == null) return;
      setState(() {
        _drivers[userId] = {'lat': lat, 'lng': lng, 'ts': ts};
        final point = LatLng(lat, lng);
        _tracks.putIfAbsent(userId, () => []);
        _tracks[userId]!.add(point);
        _tracksOsm.putIfAbsent(userId, () => []);
        _tracksOsm[userId]!.add(ll.LatLng(lat, lng));
      });
      // Center camera to latest point
      _gController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
      _osmController.move(ll.LatLng(lat, lng), 14);
    });
    // Yêu cầu snapshot vị trí ngay khi mở màn
    try {
      socket.emit('request_driver_locations', {});
      socket.off('driver_locations_snapshot');
      socket.on('driver_locations_snapshot', (payload) {
        try {
          final items = (payload['items'] as List?) ?? [];
          if (items.isEmpty) return;
          setState(() {
            for (final it in items) {
              final userId = (it['userId'] ?? '').toString();
              final lat = (it['lat'] as num?)?.toDouble();
              final lng = (it['lng'] as num?)?.toDouble();
              final ts = it['ts'] ?? DateTime.now().millisecondsSinceEpoch;
              if (userId.isEmpty || lat == null || lng == null) continue;
              _drivers[userId] = {'lat': lat, 'lng': lng, 'ts': ts};
              final point = LatLng(lat, lng);
              _tracks.putIfAbsent(userId, () => []);
              _tracks[userId]!.add(point);
              _tracksOsm.putIfAbsent(userId, () => []);
              _tracksOsm[userId]!.add(ll.LatLng(lat, lng));
            }
          });
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    final socket = Provider.of<SocketProvider>(context, listen: false);
    socket.off('driver_location_update');
    socket.off('driver_locations_snapshot');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _drivers.entries.map((e) {
      final id = e.key;
      final d = e.value;
      final pos = LatLng(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
      );
      return Marker(
        markerId: MarkerId(id),
        position: pos,
        infoWindow: InfoWindow(title: 'Tài xế $id'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();

    final polylines = _tracks.entries.map((e) {
      final color = _colorFor(e.key);
      return Polyline(
        polylineId: PolylineId('t_${e.key}'),
        points: e.value,
        color: color,
        width: 5,
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi tài xế (Realtime)'),
        actions: [
          IconButton(
            icon: Icon(_tab == 0 ? Icons.list : Icons.map),
            tooltip: _tab == 0 ? 'Xem danh sách' : 'Xem bản đồ',
            onPressed: () => setState(() => _tab = _tab == 0 ? 1 : 0),
          ),
        ],
      ),
      body: _drivers.isEmpty
          ? const Center(child: Text('Chưa có vị trí tài xế'))
          : (_tab == 1
                ? _buildList()
                : _buildMap(markers: markers, polylines: polylines)),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _drivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _drivers.values.elementAt(index);
        final userId = _drivers.keys.elementAt(index);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.teal),
            title: Text('Tài xế $userId'),
            subtitle: Text(
              'Lat: ${item['lat']}, Lng: ${item['lng']}\nCập nhật: ${DateTime.fromMillisecondsSinceEpoch(item['ts'] ?? 0)}',
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap({
    required Set<Marker> markers,
    required Set<Polyline> polylines,
  }) {
    const useGoogle = bool.fromEnvironment(
      'USE_GOOGLE_MAPS',
      defaultValue: false,
    );
    if (useGoogle) {
      return GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(10.762622, 106.660172),
          zoom: 12,
        ),
        onMapCreated: (c) => _gController = c,
        markers: markers,
        polylines: polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: true,
        compassEnabled: true,
      );
    }
    // OSM fallback
    final osmPolylines = _tracksOsm.entries
        .map(
          (e) => fm.Polyline(
            points: e.value,
            strokeWidth: 4,
            color: _colorFor(e.key),
          ),
        )
        .toList();
    final osmMarkers = _drivers.entries
        .map(
          (e) => fm.Marker(
            point: ll.LatLng(e.value['lat'], e.value['lng']),
            child: const Icon(Icons.location_pin, color: Colors.teal),
          ),
        )
        .toList();
    return fm.FlutterMap(
      mapController: _osmController,
      options: const fm.MapOptions(
        initialCenter: ll.LatLng(10.762622, 106.660172),
        initialZoom: 12,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        fm.PolylineLayer(polylines: osmPolylines),
        fm.MarkerLayer(markers: osmMarkers),
      ],
    );
  }

  Color _colorFor(String id) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
    ];
    final idx = id.hashCode.abs() % colors.length;
    return colors[idx];
  }
}
