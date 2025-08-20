import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/socket_provider.dart';

class DriversTrackingScreen extends StatefulWidget {
  const DriversTrackingScreen({super.key});

  @override
  State<DriversTrackingScreen> createState() => _DriversTrackingScreenState();
}

class _DriversTrackingScreenState extends State<DriversTrackingScreen> {
  final Map<String, Map<String, dynamic>> _drivers =
      {}; // userId -> {lat,lng,ts}
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final socket = Provider.of<SocketProvider>(context, listen: false);
    socket.off('driver_location_update');
    socket.on('driver_location_update', (data) {
      setState(() {
        _drivers[data['userId']] = data;
      });
    });
  }

  @override
  void dispose() {
    final socket = Provider.of<SocketProvider>(context, listen: false);
    socket.off('driver_location_update');
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi tài xế (Realtime)')),
      body: _drivers.isEmpty
          ? const Center(child: Text('Chưa có vị trí tài xế'))
          : ListView.separated(
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
            ),
    );
  }
}
