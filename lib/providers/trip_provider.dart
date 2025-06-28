import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../api/trip_service.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  bool _isLoading = false;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;

  Future<void> loadTrips() async {
    // Đặt loading state nhưng không notify ngay lập tức để tránh setState trong build
    _isLoading = true;

    try {
      print('🔄 TripProvider: Starting to load trips...');
      _trips = await TripService.fetchAllTrips();
      print('✅ TripProvider: Loaded ${_trips.length} trips');
    } catch (e) {
      print('❌ TripProvider: Error loading trips: $e');
      _trips = [];
    }

    _isLoading = false;
    notifyListeners(); // Chỉ notify một lần khi hoàn thành
  }

  Future<void> searchTrips({
    required String diemDi,
    required String diemDen,
    required String ngayDi,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trips = await TripService.searchTrips(
        diemDi: diemDi,
        diemDen: diemDen,
        ngayDi: ngayDi,
      );
    } catch (e) {
      print('Error searching trips: $e');
      _trips = [];
    }
    _isLoading = false;
    notifyListeners();
  }
}
