import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../api/booking_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookings = await BookingService.fetchBookings();
    } catch (e) {
      _bookings = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking(String tripId, int soLuong) async {
    final result = await BookingService.createBooking(tripId, soLuong);
    if (result) await loadBookings();
    return result;
  }

  Future<bool> createBookingWithSeats(
    String tripId,
    List<String> selectedSeats,
  ) async {
    final result = await BookingService.createBookingWithSeats(
      tripId,
      selectedSeats,
    );
    if (result) await loadBookings();
    return result;
  }

  Future<bool> createBookingWithPickup(
    String tripId,
    List<String> selectedSeats,
    String pickupType,
    String? customAddress,
    String? pickupNote, {
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    final result = await BookingService.createBookingWithPickup(
      tripId,
      selectedSeats,
      pickupType,
      customAddress,
      pickupNote,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
    );
    if (result) await loadBookings();
    return result;
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final result = await BookingService.cancelBooking(bookingId);
    if (result['success'] == true) {
      await loadBookings(); // Reload bookings after cancelling
    }
    return result;
  }
}
