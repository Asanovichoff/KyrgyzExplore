import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/booking_model.dart';
import '../models/payment_intent_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(dio: ref.read(dioProvider));
});

class BookingRepository {
  BookingRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<BookingModel> create({
    required String listingId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numberOfGuests,
    String? guestMessage,
  }) async {
    final res = await _dio.post('/bookings', data: {
      'listingId': listingId,
      'checkInDate': _fmt(checkInDate),
      'checkOutDate': _fmt(checkOutDate),
      'numberOfGuests': numberOfGuests,
      if (guestMessage != null && guestMessage.isNotEmpty)
        'guestMessage': guestMessage,
    });
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> myBookings({int page = 0, int size = 10}) async {
    final res = await _dio.get(
      '/bookings/my',
      queryParameters: {'page': page, 'size': size},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(String bookingId) async {
    await _dio.post('/bookings/$bookingId/cancel');
  }

  Future<List<BookingModel>> hostBookings({int page = 0, int size = 10}) async {
    final res = await _dio.get(
      '/bookings/host',
      queryParameters: {'page': page, 'size': size},
    );
    final content = res.data['data']['content'] as List<dynamic>;
    return content
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> confirm(String bookingId) async {
    final res = await _dio.post('/bookings/$bookingId/confirm');
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<BookingModel> reject(String bookingId, String reason) async {
    final res = await _dio.post(
      '/bookings/$bookingId/reject',
      data: {'reason': reason},
    );
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentIntentModel> pay(String bookingId) async {
    final res = await _dio.post('/bookings/$bookingId/pay');
    return PaymentIntentModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // Formats a DateTime to "yyyy-MM-dd" as expected by the backend LocalDate.
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
