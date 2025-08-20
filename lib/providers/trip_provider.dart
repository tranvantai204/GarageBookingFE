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
      final all = await TripService.fetchAllTrips();
      final now = DateTime.now();
      // Ẩn các chuyến đã qua (đưa ra khỏi danh sách hiển thị)
      _trips = all.where((t) => t.thoiGianKhoiHanh.isAfter(now)).toList();
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

  Future<bool> deleteTrip(String tripId, String token) async {
    try {
      print('🗑️ Deleting trip: $tripId');

      final success = await TripService.deleteTrip(tripId, token);

      if (success) {
        // Xóa trip khỏi local list
        _trips.removeWhere((trip) => trip.id == tripId);
        notifyListeners();
        print('✅ Trip deleted successfully');
        return true;
      } else {
        print('❌ Failed to delete trip');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting trip: $e');
      return false;
    }
  }
}
