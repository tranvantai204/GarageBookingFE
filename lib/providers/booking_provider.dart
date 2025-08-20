import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../api/booking_service.dart';
import '../api/voucher_service.dart';

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

  Future<bool> createBookingSimple(String tripId, int soLuong) async {
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
    String? voucherCode,
    int? discountAmount,
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
      voucherCode: voucherCode,
      discountAmount: discountAmount,
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

  Future<int> validateVoucher(String code, int amount, {String? route}) async {
    return VoucherService.validate(code, amount, route: route);
  }

  Future<Map<String, dynamic>> checkInByQr(
    String qrData, {
    String? tripId,
  }) async {
    final resp = await BookingService.checkInByQr(qrData, tripId: tripId);
    if (resp['success'] == true) {
      await loadBookings();
    }
    return resp;
  }

  Future<Map<String, dynamic>> fetchTripPassengers(String tripId) async {
    return BookingService.getTripPassengers(tripId);
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> body) async {
    final resp = await BookingService.createRaw(body);
    if (resp['success'] == true) await loadBookings();
    return resp;
  }

  Future<Map<String, dynamic>> payBooking({
    required String bookingId,
    required String method,
    String? reference,
  }) async {
    final resp = await BookingService.payBooking(
      bookingId: bookingId,
      method: method,
      reference: reference,
    );
    if (resp['success'] == true) {
      await loadBookings();
    }
    return resp;
  }

  Future<Map<String, dynamic>> createPaymentQr({
    required String type,
    String? bookingId,
    String? userId,
    int? amount,
  }) async {
    return BookingService.createPaymentQr(
      type: type,
      bookingId: bookingId,
      userId: userId,
      amount: amount,
    );
  }

  Future<Map<String, dynamic>> createPayosLink({
    required String type,
    String? bookingId,
    String? userId,
    int? amount,
  }) async {
    return BookingService.createPayosLink(
      type: type,
      bookingId: bookingId,
      userId: userId,
      amount: amount,
    );
  }
}
